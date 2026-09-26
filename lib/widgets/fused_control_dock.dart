import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../player/player.dart';
import '../models/models.dart';
import '../api/api.dart';
import '../l10n/app_localizations.dart';

class FusedControlDock extends StatefulWidget {
  final PlayerState playerState;
  final VoidCallback onPlayPause;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<double> onSeek;
  final Color? themeColor;
  final Track? track;
  final bool showTranslations;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onPlaylistToggle;
  final VoidCallback? onToggleTranslations;

  /// 队列按钮的焦点节点：播放页用它把焦点从关闭的抽屉还回来。
  final FocusNode? playlistToggleFocusNode;

  /// 播放键的焦点节点：遥控器从播放模式进入控件模式时，焦点要有个确定的
  /// 落点，否则第一下方向键不知道该从哪儿算起。
  final FocusNode? playFocusNode;

  const FusedControlDock({
    super.key,
    required this.playerState,
    required this.onPlayPause,
    required this.onPrevious,
    required this.onNext,
    required this.onVolumeChanged,
    required this.onSeek,
    this.themeColor,
    this.track,
    this.showTranslations = true,
    this.onFavoriteToggle,
    this.onPlaylistToggle,
    this.onToggleTranslations,
    this.playlistToggleFocusNode,
    this.playFocusNode,
  });

  @override
  State<FusedControlDock> createState() => _FusedControlDockState();
}

class _FusedControlDockState extends State<FusedControlDock> {
  bool _volumeExpanded = false;

  /// 时间显示当前是否持有焦点，用来画进度条的焦点描边。
  bool _seekFocused = false;

  /// 遥控器进度步长。长按方向键时系统会发 KeyRepeatEvent 连续快进。
  static const int _seekStepMs = 5000;

  /// 小屏（紧凑）布局的宽度分界，与 PlayerScreen 保持一致。
  static const double _compactBreakpoint = 500;

  /// 显示药丸徽章所需的最小逻辑宽度。
  ///
  /// 徽章最大 198（左右内边距 20 + 图 30 + 间距 8 + 文本 140），加上中间
  /// 控制键 206、右侧时间/音量/收藏/队列 240、内外水平留白 80，共约 724。
  /// 宽度不够时先隐藏徽章，它只是装饰，标题和歌手在主界面同样看得到。
  static const double _pillMinWidth = 740;

  /// 使用内联音量滑条所需的最小逻辑宽度。
  ///
  /// 滑条比弹出式音量开关多占约 52px。宽度不够时改用弹出式开关（紧凑布局
  /// 本来就是这么做的），否则 500~560 的窄窗口下右侧区域会溢出。
  static const double _inlineVolumeMinWidth = 560;

  /// 时间显示同时也是遥控器的进度条：左右键快退/快进，上下键照常把焦点
  /// 移出这根进度条。返回 [KeyEventResult.handled] 才不会被应用级的
  /// Shortcuts 接管成方向键移动焦点。
  KeyEventResult _handleSeekKeys(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key != LogicalKeyboardKey.arrowLeft &&
        key != LogicalKeyboardKey.arrowRight) {
      return KeyEventResult.ignored;
    }
    final duration = widget.playerState.duration;
    // 还不知道总时长时也不能把焦点放走，否则按一下左右就"掉"到别处去了。
    if (duration.inMilliseconds <= 0) return KeyEventResult.handled;

    final current = widget.playerState.position.inMilliseconds;
    final delta = key == LogicalKeyboardKey.arrowRight
        ? _seekStepMs
        : -_seekStepMs;
    final next = (current + delta).clamp(0, duration.inMilliseconds).toDouble();
    widget.onSeek(next / duration.inMilliseconds);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    final accent = widget.themeColor ?? colorScheme.primary;
    final progress = widget.playerState.progress.clamp(0.0, 1.0);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < _compactBreakpoint;
    // 横向空间不够时先舍弃装饰性内容，保证中间播放键和右侧进度/收藏/队列
    // 始终完整可见（否则 Row 会溢出画出一条黑条）。
    final showPill = !isSmall && screenWidth >= _pillMinWidth;
    final showInlineVolume = !isSmall && screenWidth >= _inlineVolumeMinWidth;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isSmall ? 12 : 24,
        0,
        isSmall ? 12 : 24,
        isSmall ? 12 : 16,
      ),
      child: GestureDetector(
        onTapDown: (d) => _handleSeek(d, context),
        onHorizontalDragUpdate: (d) => _handleSeek(d, context),
        child: Container(
          height: isSmall ? 56 : 64,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Background + progress fill layer
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF120F0D).withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.45),
                            border: Border(
                              right: BorderSide(
                                color: accent.withValues(alpha: 0.9),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Border
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 0.5,
                    ),
                  ),
                ),
              ),
              // Controls
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16),
                  child: Row(
                    children: [
                      if (showPill) ...[
                        _buildPillBadge(accent, loc),
                        const Spacer(),
                      ],
                      _buildCenterControls(accent, isSmall: isSmall),
                      const Spacer(),
                      // 右侧（时间/音量/收藏/队列）不参与弹性分配：让它按自身
                      // 完整宽度布局并贴住右边缘，只由两个 Spacer 吸收剩余空间。
                      // 之前它和两个 Spacer 三等分，窄一点就会被挤到放不下而溢出。
                      _buildRightSection(
                        accent,
                        showInlineVolume: showInlineVolume,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillBadge(Color accent, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 0.5),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.track != null &&
              widget.track!.coverArt.isNotEmpty &&
              coverImageProvider(context, widget.track!.coverArt) != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image(
                image: coverImageProvider(context, widget.track!.coverArt)!,
                width: 30,
                height: 30,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, st) => Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white54,
                    size: 16,
                  ),
                ),
              ),
            )
          else
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.music_note,
                color: Colors.white54,
                size: 16,
              ),
            ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.track?.title ?? loc.noTrack,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.track?.artist ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterControls(Color accent, {bool isSmall = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isSmall) ...[
          _DockIconButton(
            icon: Icons.shuffle,
            size: 14,
            color: widget.playerState.isShuffle ? accent : Colors.white54,
            onTap: () => widget.playerState.toggleShuffle(),
          ),
          const SizedBox(width: 16),
        ],
        _DockIconButton(
          icon: Icons.skip_previous_rounded,
          size: isSmall ? 18 : 22,
          color: Colors.white70,
          onTap: widget.onPrevious,
        ),
        SizedBox(width: isSmall ? 8 : 12),
        _FocusRing(
          radius: 24,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              focusNode: widget.playFocusNode,
              onTap: widget.onPlayPause,
              borderRadius: BorderRadius.circular(24),
              // 白色圆钮正好填满 InkWell 时，描边会压在圆边上。留 3px 让
              // 焦点环落在按钮外侧的深色底上，才看得出是焦点。
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Container(
                  width: isSmall ? 34 : 40,
                  height: isSmall ? 34 : 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 8),
                    ],
                  ),
                  child: Icon(
                    widget.playerState.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: isSmall ? 18 : 22,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: isSmall ? 8 : 12),
        _DockIconButton(
          icon: Icons.skip_next_rounded,
          size: isSmall ? 18 : 22,
          color: Colors.white70,
          onTap: widget.onNext,
        ),
        if (!isSmall) ...[
          const SizedBox(width: 16),
          _DockIconButton(
            icon: widget.playerState.isRepeat ? Icons.repeat_one : Icons.repeat,
            size: 14,
            color: widget.playerState.isRepeat ? accent : Colors.white54,
            onTap: () => widget.playerState.toggleRepeat(),
          ),
        ],
      ],
    );
  }

  Widget _buildRightSection(Color accent, {bool showInlineVolume = true}) {
    final volumeIcon = widget.playerState.volume > 0.5
        ? Icons.volume_up_rounded
        : widget.playerState.volume > 0
        ? Icons.volume_down_rounded
        : Icons.volume_off_rounded;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Time：触摸时只是显示，遥控器上聚焦后左右键就是进度条。
        Focus(
          onFocusChange: (focused) {
            if (focused == _seekFocused) return;
            setState(() => _seekFocused = focused);
          },
          onKeyEvent: _handleSeekKeys,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${widget.playerState.formattedPosition}/${widget.playerState.formattedDuration}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // 描边叠在最上层且不参与布局，进度条拿到焦点时才看得见。
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _seekFocused ? Colors.white : Colors.transparent,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showInlineVolume) ...[
          const SizedBox(width: 12),
          Icon(volumeIcon, size: 14, color: Colors.white54),
          SizedBox(
            width: 50,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayColor: Colors.white.withValues(alpha: 0.1),
                activeTrackColor: Colors.white70,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                thumbColor: Colors.white,
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: widget.playerState.volume,
                onChanged: widget.onVolumeChanged,
                min: 0,
                max: 1,
              ),
            ),
          ),
        ],
        if (!showInlineVolume) _buildVolumeToggle(volumeIcon, accent),
        // Heart
        if (widget.onFavoriteToggle != null)
          _FocusRing(
            radius: 6,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onFavoriteToggle,
                borderRadius: BorderRadius.circular(6),
                child: Icon(
                  widget.playerState.isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  size: 14,
                  color: widget.playerState.isFavorite
                      ? const Color(0xFFF43F5E)
                      : Colors.white54,
                ),
              ),
            ),
          ),
        const SizedBox(width: 10),
        // Playlist toggle
        if (widget.onPlaylistToggle != null)
          _FocusRing(
            radius: 6,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPlaylistToggle,
                focusNode: widget.playlistToggleFocusNode,
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.queue_music_rounded,
                      size: 16,
                      color: Colors.white54,
                    ),
                    if (widget.playerState.hasQueue)
                      Positioned(
                        top: -3,
                        right: -3,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVolumeToggle(IconData volumeIcon, Color accent) {
    return _FocusRing(
      radius: 6,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _volumeExpanded = !_volumeExpanded),
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 24,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Icon(volumeIcon, size: 14, color: Colors.white54),
                ),
                if (_volumeExpanded)
                  Positioned(
                    bottom: 26,
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        height: 120,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF120F0D,
                          ).withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 0.5,
                          ),
                        ),
                        child: RotatedBox(
                          quarterTurns: -1,
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 5,
                              ),
                              overlayColor: Colors.white.withValues(alpha: 0.1),
                              activeTrackColor: Colors.white70,
                              inactiveTrackColor: Colors.white.withValues(
                                alpha: 0.2,
                              ),
                              thumbColor: Colors.white,
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 12,
                              ),
                            ),
                            child: Slider(
                              value: widget.playerState.volume,
                              onChanged: widget.onVolumeChanged,
                              min: 0,
                              max: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSeek(dynamic details, BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPos = renderBox.globalToLocal(details.globalPosition);
    final width = renderBox.size.width;
    final progress = (localPos.dx / width).clamp(0.0, 1.0);
    widget.onSeek(progress);
  }
}

class _DockIconButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback onTap;

  const _DockIconButton({
    required this.icon,
    required this.size,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FocusRing(
      radius: 16,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(icon, size: size, color: color),
          ),
        ),
      ),
    );
  }
}

/// 遥控器焦点描边。
///
/// 这层只负责"看得见"：`canRequestFocus: false` 让它退出焦点遍历，真正的
/// 焦点仍然落在子控件的 FocusNode 上，方向键和回车照常工作（`onFocusChange`
/// 监听的是 `hasFocus`，子节点拿到焦点时它也会亮）。
///
/// 描边用 `Positioned.fill` 叠在子节点上方，不参与布局，所以加上它不会
/// 让紧凑的 dock 撑出溢出。深色背景上 Material 自带的 focusColor 太淡，
/// 这里固定用白色以保证在播放页和浅色主题下都看得见。
class _FocusRing extends StatefulWidget {
  const _FocusRing({required this.child, this.radius = 12});

  final Widget child;
  final double radius;

  @override
  State<_FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<_FocusRing> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      onFocusChange: (hasFocus) {
        if (hasFocus == _focused) return;
        setState(() => _focused = hasFocus);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _focused ? Colors.white : Colors.transparent,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(widget.radius),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
