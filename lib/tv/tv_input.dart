import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 遥控器的两层模式。
enum TvMode {
  /// 播放模式：方向键直接操作播放（上一首 / 下一首 / 快退 / 快进）。
  playback,

  /// 控件模式：方向键退回焦点遍历，确定键激活当前焦点的控件。
  control,
}

/// 遥控器按键状态机，把一颗菜单键变成"前缀键"（leader key）。
///
/// 三层键位：
///
/// | 操作 | 语义 |
/// | --- | --- |
/// | ↑ ↓ ← →（菜单未按住） | 播放控制：上一首 / 下一首 / 快退 / 快进 |
/// | 菜单 + ↑ ↓ ← → | 内容导航：音乐库 / 播放列表 / 上一个专辑 / 下一个专辑 |
/// | 长按菜单 | 全局设置 |
/// | 短按菜单 | 打开 / 关闭播放队列 |
/// | 确定键（播放页） | 进入控件模式，方向键恢复成焦点遍历 |
/// | 返回键（控件模式） | 退回播放模式 |
///
/// 拦截点有两个，少一个都不行（Flutter 3.47 的按键分发顺序）：
///
/// 1. [HardwareKeyboard.addHandler] 在焦点系统**之前**跑，而且不管有没有
///    焦点都会跑。菜单键、"没焦点时的方向键"都在这里拦截。
/// 2. 但它吞掉事件并**不会**阻止焦点系统继续处理（`_dispatchKeyMessage`
///    是无条件调用的）。真正能停掉焦点链的是
///    [FocusManager.addEarlyKeyEventHandler]，它在焦点遍历之前跑，返回
///    [KeyEventResult.handled] 就直接 return。
///
/// 所以这里用"同一次事件对象"把两个钩子串起来：硬件层先决定要不要吞，
/// 焦点层用 `identical` 认出同一个事件，再决定要不要拦下焦点链。
class TvInputController extends ChangeNotifier {
  TvInputController({required this.tabIndex}) {
    tabIndex.addListener(_handleTabChanged);
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
    FocusManager.instance.addEarlyKeyEventHandler(_handleFocusKey);
  }

  /// 播放模式下方向键的快进 / 快退步长。
  static const int seekStepMs = 10000;

  /// 长按菜单键进入设置的阈值。
  static const Duration longPressThreshold = Duration(milliseconds: 500);

  /// 被当成"菜单"的逻辑按键。
  ///
  /// Android TV 的 KEYCODE_MENU（82）映射到
  /// [LogicalKeyboardKey.contextMenu]。如果哪台盒子的菜单键是别的键，
  /// 往这个集合里加一行即可。
  static final Set<LogicalKeyboardKey> menuKeys = {
    LogicalKeyboardKey.contextMenu,
  };

  final ValueNotifier<int> tabIndex;

  /// 由宿主注入的回调；屏幕各自注册自己那一部分。
  void Function()? popToHome;
  void Function()? playPrevious;
  void Function()? playNext;
  void Function(int deltaMs)? seekBy;
  void Function(int libraryTab)? goLibraryTab;
  void Function(int delta)? albumDelta;
  void Function()? toggleQueue;
  void Function()? focusPlayButton;

  TvMode _mode = TvMode.playback;
  bool _menuHeld = false;
  bool _menuConsumed = false;
  bool _queueOpen = false;
  Timer? _menuTimer;
  KeyEvent? _consumedEvent;

  TvMode get mode => _mode;

  /// 菜单键是否处于按住状态（导航模式）。
  bool get menuHeld => _menuHeld;

  /// 队列抽屉是否展开。
  ///
  /// 抽屉打开时方向键必须让给焦点遍历，否则抽屉里的按钮用遥控器点不到。
  bool get queueOpen => _queueOpen;

  /// 只有"播放页 + 播放模式 + 队列没开"时，方向键才属于播放控制。
  bool get playbackActive =>
      _mode == TvMode.playback && tabIndex.value == 0 && !_queueOpen;

  @override
  void dispose() {
    _menuTimer?.cancel();
    tabIndex.removeListener(_handleTabChanged);
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    FocusManager.instance.removeEarlyKeyEventHandler(_handleFocusKey);
    super.dispose();
  }

  // ---------------------------------------------------------------- 键事件

  bool _handleHardwareKey(KeyEvent event) {
    _consumedEvent = null;
    if (!_route(event)) return false;
    _consumedEvent = event;
    return true;
  }

  KeyEventResult _handleFocusKey(KeyEvent event) =>
      identical(_consumedEvent, event)
      ? KeyEventResult.handled
      : KeyEventResult.ignored;

  bool _route(KeyEvent event) {
    final key = event.logicalKey;

    // 菜单键状态机：DOWN 开始计时，重复事件吞掉，UP 决定短按 / 放行。
    if (menuKeys.contains(key)) {
      if (event is KeyDownEvent) {
        _onMenuDown();
      } else if (event is KeyUpEvent) {
        _onMenuUp();
      }
      return true;
    }

    // 按住菜单期间的方向键 = 内容导航，全部吞掉。
    if (_menuHeld && _isArrow(key)) {
      if (event is KeyDownEvent) _onNavigate(key);
      return true;
    }

    // 播放模式的方向键 = 播放控制。
    if (playbackActive && _isArrow(key)) {
      if (event is KeyDownEvent || event is KeyRepeatEvent) {
        _onPlayback(key, repeat: event is KeyRepeatEvent);
      }
      return true;
    }

    // 播放模式下按确定键 = 进入控件模式。
    if (playbackActive && _isActivate(key) && event is KeyDownEvent) {
      enterControlMode();
      return true;
    }

    // 返回键**不在这里**处理。真机（MiTV）上实测：控件模式下按返回键，
    // app 直接退到了桌面。返回键走的是 SystemChannels.navigation →
    // Navigator.maybePop 这条路，跟这里的键事件是两回事，吞键事件不顶用。
    // 退回播放模式交给 TvBackScope 的 PopScope——它正好挂在这条路上，而且
    // 是能真正否决这次 pop 的位置。
    return false;
  }

  static bool _isArrow(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.arrowUp ||
      key == LogicalKeyboardKey.arrowDown ||
      key == LogicalKeyboardKey.arrowLeft ||
      key == LogicalKeyboardKey.arrowRight;

  static bool _isActivate(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.numpadEnter;

  // ------------------------------------------------------------- 菜单状态机

  void _onMenuDown() {
    if (_menuHeld) return;
    _menuHeld = true;
    _menuConsumed = false;
    _menuTimer?.cancel();
    _menuTimer = Timer(longPressThreshold, _onMenuLongPress);
    notifyListeners();
  }

  void _onMenuUp() {
    if (!_menuHeld) return;
    _menuHeld = false;
    // 计时器还活着说明长按阈值没到，这次是一次干净的短按。
    final pending = _menuTimer?.isActive ?? false;
    _menuTimer?.cancel();
    _menuTimer = null;
    final tap = pending && !_menuConsumed;
    notifyListeners();
    if (tap) _onMenuTap();
  }

  void _onMenuLongPress() {
    _menuTimer = null;
    if (!_menuHeld) return;
    // 阈值一到就执行，不等松手：否则"按住 2 秒才按方向键"这种动作没法
    // 判定到底算长按还是算组合键。标记成已消费，随后的 UP 不会再算短按。
    _menuConsumed = true;
    popToHome?.call();
    tabIndex.value = 2;
  }

  void _onMenuTap() {
    if (tabIndex.value != 0) tabIndex.value = 0;
    toggleQueue?.call();
  }

  void _onNavigate(LogicalKeyboardKey key) {
    // 只在 KeyDown 上调用，真正的长按连发是 KeyRepeatEvent，走不到这里；
    // 同一次按住里换别的方向仍然算数。
    if (key == LogicalKeyboardKey.arrowUp) {
      _menuConsumed = true;
      popToHome?.call();
      tabIndex.value = 1;
      goLibraryTab?.call(0);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _menuConsumed = true;
      popToHome?.call();
      tabIndex.value = 1;
      goLibraryTab?.call(3);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _menuConsumed = true;
      _goAlbum(-1);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _menuConsumed = true;
      _goAlbum(1);
    }
  }

  void _goAlbum(int delta) {
    popToHome?.call();
    tabIndex.value = 1;
    if (albumDelta != null) {
      albumDelta!(delta);
    } else {
      goLibraryTab?.call(1);
    }
  }

  void _onPlayback(LogicalKeyboardKey key, {required bool repeat}) {
    switch (key) {
      case LogicalKeyboardKey.arrowUp:
        // 切歌只认单次按下，长按不能一路跳过去。
        if (!repeat) playPrevious?.call();
      case LogicalKeyboardKey.arrowDown:
        if (!repeat) playNext?.call();
      case LogicalKeyboardKey.arrowLeft:
        seekBy?.call(-seekStepMs);
      case LogicalKeyboardKey.arrowRight:
        seekBy?.call(seekStepMs);
      default:
        break;
    }
  }

  // ---------------------------------------------------------------- 模式

  void enterControlMode() {
    if (_mode == TvMode.control) return;
    _mode = TvMode.control;
    notifyListeners();
    // 从"没有任何焦点"直接进控件模式，方向键自己找不到起点，必须主动把
    // 焦点送到播放键上，否则第一下方向键看起来是没反应的。
    focusPlayButton?.call();
  }

  void exitControlMode() {
    if (_mode != TvMode.control) return;
    _mode = TvMode.playback;
    FocusManager.instance.primaryFocus?.unfocus();
    notifyListeners();
  }

  void setQueueOpen(bool open) {
    if (_queueOpen == open) return;
    _queueOpen = open;
    notifyListeners();
  }

  void _handleTabChanged() {
    // 离开播放页就忘掉控件模式，否则下次回到播放页方向键会先去挪焦点。
    if (tabIndex.value != 0 && _mode == TvMode.control) {
      _mode = TvMode.playback;
      notifyListeners();
    }
  }
}
