import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:sonata/tv/tv.dart';

/// 遥控器三层键位的状态机。
///
/// 键位：
/// * 播放模式的方向键 → 上一首 / 下一首 / 快退 / 快进
/// * 菜单 + 方向键 → 音乐库 / 播放列表 / 上一个专辑 / 下一个专辑
/// * 长按菜单 → 设置；短按菜单 → 开关队列
/// * 确定键 → 进控件模式（方向键回到焦点遍历），返回键 → 退回播放模式
void main() {
  late TvInputController controller;
  late ValueNotifier<int> tabIndex;
  late FocusNode a1;
  late FocusNode a2;

  int prevCount = 0;
  int nextCount = 0;
  int seekCount = 0;
  int seekDelta = 0;
  int queueCount = 0;
  int popHomeCount = 0;
  int libraryTabCount = 0;
  int? libraryTab;
  int? albumDelta;

  Future<void> pumpHost(WidgetTester tester, {int initialTab = 0}) async {
    // 目标设备是 1920×1080 的电视。
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    prevCount = 0;
    nextCount = 0;
    seekCount = 0;
    seekDelta = 0;
    queueCount = 0;
    popHomeCount = 0;
    libraryTabCount = 0;
    libraryTab = null;
    albumDelta = null;

    tabIndex = ValueNotifier<int>(initialTab);
    addTearDown(tabIndex.dispose);

    a1 = FocusNode(debugLabel: 'a1');
    a2 = FocusNode(debugLabel: 'a2');
    addTearDown(a1.dispose);
    addTearDown(a2.dispose);

    // 注意：这里不要用 `..级联 + => 表达式体` 的写法。`=>` 的函数体会一路
    // 吸走后面所有的 `..` 段，后面的赋值会被解析到 `prevCount++` 这种 int
    // 上去，报出一堆莫名其妙的 "setter isn't defined for the type 'int'"。
    controller = TvInputController(tabIndex: tabIndex);
    controller.playPrevious = () {
      prevCount++;
    };
    controller.playNext = () {
      nextCount++;
    };
    controller.seekBy = (delta) {
      seekCount++;
      seekDelta = delta;
    };
    controller.goLibraryTab = (tab) {
      libraryTabCount++;
      libraryTab = tab;
    };
    controller.albumDelta = (delta) {
      albumDelta = delta;
    };
    controller.toggleQueue = () {
      queueCount++;
    };
    controller.popToHome = () {
      popHomeCount++;
    };
    controller.focusPlayButton = a1.requestFocus;
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<TvInputController>.value(
        value: controller,
        child: MaterialApp(
          home: TvBackScope(
            child: Scaffold(
              body: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton(
                    focusNode: a1,
                    onPressed: () {},
                    child: const Text('A1'),
                  ),
                  const SizedBox(height: 80),
                  TextButton(
                    focusNode: a2,
                    onPressed: () {},
                    child: const Text('A2'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('播放模式', () {
    testWidgets('方向键是播放控制，焦点不许被带跑', (tester) async {
      await pumpHost(tester);

      a1.requestFocus();
      await tester.pump();
      expect(a1.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(nextCount, 1, reason: '播放模式下 ↓ 应当是下一首');
      expect(a1.hasPrimaryFocus, isTrue, reason: '方向键不能顺带挪焦点');
      expect(a2.hasPrimaryFocus, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(prevCount, 1, reason: '播放模式下 ↑ 应当是上一首');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(seekCount, 1);
      expect(seekDelta, TvInputController.seekStepMs, reason: '→ 快进');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(seekCount, 2);
      expect(seekDelta, -TvInputController.seekStepMs, reason: '← 快退');
    });

    testWidgets('长按只连续快进，不会一路跳歌', (tester) async {
      await pumpHost(tester);

      a1.requestFocus();
      await tester.pump();

      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(seekCount, 1, reason: '长按快进要能连续触发');

      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(nextCount, 0, reason: '连发的 ↓ 不该把歌一路跳过去');
    });

    testWidgets('确定键进控件模式，方向键才回到焦点遍历', (tester) async {
      await pumpHost(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();
      expect(controller.mode, TvMode.control);
      expect(a1.hasPrimaryFocus, isTrue, reason: '进控件模式要有明确的焦点落点');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(a2.hasPrimaryFocus, isTrue, reason: '控件模式下方向键恢复成焦点遍历');
      expect(nextCount, 0);

      // 返回键真机上走的是 SystemChannels.navigation → Navigator.maybePop，
      // 不是键事件；结论和处理方式见 lib/tv/tv_back_scope.dart。
      final navigator = Navigator.of(tester.element(find.byType(TvBackScope)));
      expect(
        await navigator.maybePop(),
        isTrue,
        reason: '返回 true = 这次返回被路由拦下，不再冒泡给系统退出 app',
      );
      await tester.pump();
      expect(find.byType(TextButton), findsNWidgets(2), reason: 'app 不能被退出');
      expect(controller.mode, TvMode.playback, reason: '返回键退回播放模式');
      expect(a1.hasPrimaryFocus, isFalse, reason: '焦点要被收走，否则下一下方向键还在挪它');
      expect(a2.hasPrimaryFocus, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(nextCount, 1, reason: '退回播放模式后方向键重新归播放管');
    });

    testWidgets('播放模式下返回键要冒泡给系统，不能被拦成关不掉', (tester) async {
      await pumpHost(tester);

      final navigator = Navigator.of(tester.element(find.byType(TvBackScope)));
      expect(
        await navigator.maybePop(),
        isFalse,
        reason: '首路由返回 false = 冒泡给系统，SystemNavigator.pop 才会退出 app',
      );
      await tester.pump();
      expect(find.byType(TextButton), findsNWidgets(2), reason: '路由本身不该被弹掉');
      expect(controller.mode, TvMode.playback);
    });

    testWidgets('队列抽屉打开时方向键让给焦点，否则抽屉点不到', (tester) async {
      await pumpHost(tester);
      controller.setQueueOpen(true);

      a1.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(a2.hasPrimaryFocus, isTrue);
      expect(nextCount, 0);
    });
  });

  group('非播放页', () {
    testWidgets('方向键照常走焦点遍历', (tester) async {
      await pumpHost(tester, initialTab: 1);

      a1.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(a2.hasPrimaryFocus, isTrue, reason: '曲库页方向键要能选中列表项');
      expect(nextCount, 0);
    });
  });

  group('菜单键状态机', () {
    testWidgets('短按 = 打开 / 关闭播放队列', (tester) async {
      await pumpHost(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      await tester.pump();

      expect(queueCount, 1);
      expect(controller.menuHeld, isFalse);
      expect(tabIndex.value, 0);
    });

    testWidgets('不在播放页时，短按先回到播放页再开队列', (tester) async {
      await pumpHost(tester, initialTab: 2);

      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      await tester.pump();

      expect(tabIndex.value, 0);
      expect(queueCount, 1);
    });

    testWidgets('长按阈值一到就进设置，松手不再算短按', (tester) async {
      await pumpHost(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.contextMenu);
      await tester.pump();
      expect(controller.menuHeld, isTrue);
      expect(tabIndex.value, 0, reason: '还没到阈值不能提前跳设置');

      await tester.pump(TvInputController.longPressThreshold);
      expect(tabIndex.value, 2, reason: '长按 = 设置');

      await tester.sendKeyUpEvent(LogicalKeyboardKey.contextMenu);
      await tester.pump();
      expect(controller.menuHeld, isFalse);
      expect(queueCount, 0, reason: '长按之后的松手不能再被当成短按');
      expect(tabIndex.value, 2);
    });

    testWidgets('菜单 + 方向 = 内容导航，方向键不进焦点树', (tester) async {
      await pumpHost(tester);

      a1.requestFocus();
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.contextMenu);
      await tester.pump();
      expect(controller.menuHeld, isTrue);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(libraryTab, 3, reason: '菜单 + ↓ = 播放列表分区');
      expect(tabIndex.value, 1, reason: '要切到曲库页');
      expect(popHomeCount, 1, reason: '详情页压着时先退回主页');
      expect(nextCount, 0, reason: '组合键期间 ↓ 不是下一首');
      expect(a1.hasPrimaryFocus, isTrue, reason: '组合键期间的方向键必须被拦在焦点系统之外');

      // 真正的长按连发是 KeyRepeatEvent，不该重复触发导航。
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(libraryTabCount, 1, reason: '按住方向键不能重复触发导航');

      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.contextMenu);
      await tester.pump();
      expect(queueCount, 0, reason: '组合键已经消费过，松开菜单不算短按');
      expect(controller.menuHeld, isFalse);
    });

    testWidgets('菜单 + ↑ = 音乐库，菜单 + ←/→ = 上一个 / 下一个专辑', (tester) async {
      await pumpHost(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.contextMenu);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(libraryTab, 0);
      expect(tabIndex.value, 1);
      expect(albumDelta, isNull);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowUp);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(albumDelta, 1, reason: '菜单 + → = 下一个专辑');
      expect(libraryTabCount, 1, reason: '翻专辑不该再切一次分区');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(albumDelta, -1, reason: '菜单 + ← = 上一个专辑');

      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.contextMenu);
      await tester.pump();
      expect(queueCount, 0);
    });

    testWidgets('长按期间按住菜单的方向键仍然是导航', (tester) async {
      await pumpHost(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.contextMenu);
      await tester.pump(TvInputController.longPressThreshold);
      expect(tabIndex.value, 2, reason: '长按已经进了设置');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(tabIndex.value, 1, reason: '菜单还按着，方向键仍然是导航语义');
      expect(libraryTab, 3);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.contextMenu);
      await tester.pump();
      expect(queueCount, 0);
    });
  });
}
