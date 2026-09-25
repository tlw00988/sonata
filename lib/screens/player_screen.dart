import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../player/player.dart';
import '../widgets/widgets.dart';
import '../models/models.dart';
import '../api/api.dart';
import '../l10n/app_localizations.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late AnimationController _drawerController;
  late Animation<Offset> _drawerSlideAnimation;
  late Animation<double> _backdropOpacityAnimation;
  bool _showTranslations = true;

  /// 队列抽屉是否展开。遥控器返回键要先关抽屉、再走系统返回，所以这个
  /// 状态必须是普通的字段，PopScope 的 canPop 才能在正确的时机读到。
  bool _drawerOpen = false;

  /// 打开抽屉后把焦点送到关闭按钮，否则焦点会留在被遮罩盖住的 dock 上，
  /// 方向键看起来"没反应"。关闭时再把焦点还给 dock 上的队列按钮。
  final FocusNode _drawerCloseNode = FocusNode(debugLabel: 'queue-close');
  final FocusNode _playlistToggleNode = FocusNode(debugLabel: 'queue-toggle');

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.55, end: 0.9).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _drawerController = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );
    _drawerSlideAnimation =
        Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _drawerController,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );
    _backdropOpacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _drawerController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _glowController.dispose();
    _drawerController.dispose();
    _drawerCloseNode.dispose();
    _playlistToggleNode.dispose();
    super.dispose();
  }

  void _openDrawer() {
    if (_drawerOpen) return;
    setState(() {
      _drawerOpen = true;
      _drawerController.forward();
    });
    // 抽屉要等这一帧重建完才挂上焦点节点。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_drawerOpen) return;
      _drawerCloseNode.requestFocus();
    });
  }

  void _closeDrawer() {
    if (!_drawerOpen) return;
    setState(() {
      _drawerOpen = false;
      _drawerController.reverse();
    });
    if (_playlistToggleNode.canRequestFocus) {
      _playlistToggleNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerState>(
      builder: (context, playerState, child) {
        final colorScheme = Theme.of(context).colorScheme;
        final themeColor = playerState.themeColor ?? colorScheme.primary;
        final track = playerState.currentTrack;
        final screenWidth = MediaQuery.of(context).size.width;
        final isWide = screenWidth > 900;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Ambient background
              _buildAmbientBackground(playerState, themeColor, track),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    // Header
                    _buildHeader(context, playerState, themeColor, track),

                    // Main area: lyrics (left) + album art (right)
                    Expanded(
                      child: isWide
                          ? _buildWideLayout(
                              context,
                              playerState,
                              themeColor,
                              track,
                            )
                          : _buildNarrowLayout(
                              context,
                              playerState,
                              themeColor,
                              track,
                            ),
                    ),

                    // Fused bottom dock
                    _buildFusedDock(context, playerState, themeColor, track),
                  ],
                ),
              ),

              // Playlist drawer overlay
              PopScope(
                // 遥控器返回键：抽屉开着时先关抽屉（canPop=false 不会走系统
                // 返回），抽屉关着时返回键照常工作（退出/上一层）。
                canPop: !_drawerOpen,
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop) _closeDrawer();
                },
                child: _buildPlaylistDrawer(context, playerState, themeColor),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAmbientBackground(
    PlayerState playerState,
    Color themeColor,
    Track? track,
  ) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, _) {
        return Positioned.fill(
          child: Stack(
            children: [
              // Blurred cover background
              if (track != null &&
                  track.coverArt.isNotEmpty &&
                  coverImageProvider(context, track.coverArt) != null)
                Positioned.fill(
                  child: Image(
                    image: coverImageProvider(context, track.coverArt)!,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (ctx, err, st) => const SizedBox(),
                  ),
                ),
              // Dark blur overlay
              Positioned.fill(
                child: Container(color: Colors.black.withValues(alpha: 0.75)),
              ),
              // Gaussian blur
              if (track != null &&
                  track.coverArt.isNotEmpty &&
                  coverImageProvider(context, track.coverArt) != null)
                Positioned.fill(
                  child: ClipRect(
                    child: Image(
                      image: coverImageProvider(context, track.coverArt)!,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.low,
                      errorBuilder: (ctx, err, st) => const SizedBox(),
                    ),
                  ),
                ),
              // Re-apply blur via color overlay (simulated)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ),
              // Dynamic orb 1 (top-left)
              Positioned(
                top: -128,
                left: -128,
                child: Container(
                  width: 600,
                  height: 600,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeColor.withValues(
                      alpha: 0.4 * _glowAnimation.value,
                    ),
                  ),
                ),
              ),
              // Dynamic orb 2 (bottom-right)
              Positioned(
                bottom: -128,
                right: -128,
                child: Container(
                  width: 600,
                  height: 600,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeColor.withValues(
                      alpha: 0.3 * _glowAnimation.value,
                    ),
                  ),
                ),
              ),
              // Vignette overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black,
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.6),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    PlayerState playerState,
    Color themeColor,
    Track? track,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSmall = MediaQuery.of(context).size.width < 500;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24, vertical: 8),
      child: Row(
        children: [
          // Status dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: themeColor,
              boxShadow: [
                BoxShadow(
                  color: themeColor.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Track info text
          Expanded(
            child: Text(
              track != null
                  ? '${track.artist} - ${track.title}'
                  : AppLocalizations.of(context)!.noTrackPlaying,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                fontSize: isSmall ? 11 : 12,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          // Translation toggle
          _PillButton(
            label: _showTranslations ? '文/A' : 'A',
            themeColor: themeColor,
            onTap: () => setState(() => _showTranslations = !_showTranslations),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    PlayerState playerState,
    Color themeColor,
    Track? track,
  ) {
    return Row(
      children: [
        // Left: Lyrics panel (~58%)
        Expanded(
          flex: 7,
          child: _buildLyricsPanel(context, playerState, themeColor),
        ),
        // Right: Album art + metadata (~42%)
        Expanded(
          flex: 5,
          child: _buildAlbumPanel(context, playerState, themeColor, track),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(
    BuildContext context,
    PlayerState playerState,
    Color themeColor,
    Track? track,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 500;
    final artSize = isSmall ? screenWidth * 0.5 : screenWidth * 0.45;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isSmall ? 20 : 32),
        child: Column(
          children: [
            SizedBox(height: isSmall ? 16 : 24),
            _buildAlbumArt(
              context,
              playerState,
              themeColor,
              track,
              size: artSize,
            ),
            SizedBox(height: isSmall ? 16 : 24),
            _buildTrackMetadata(context, themeColor, track, compact: isSmall),
            SizedBox(height: isSmall ? 16 : 24),
            SizedBox(
              height: isSmall ? 220 : 300,
              child: _buildLyricsPanel(
                context,
                playerState,
                themeColor,
                compact: isSmall,
              ),
            ),
            SizedBox(height: isSmall ? 8 : 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLyricsPanel(
    BuildContext context,
    PlayerState playerState,
    Color themeColor, {
    bool compact = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 40),
      child: CenteredSyncedLyrics(
        lyrics: playerState.lyrics,
        currentPosition: playerState.position,
        themeColor: themeColor,
        showTranslations: _showTranslations,
      ),
    );
  }

  Widget _buildAlbumPanel(
    BuildContext context,
    PlayerState playerState,
    Color themeColor,
    Track? track,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildAlbumArt(context, playerState, themeColor, track, size: 380),
          const SizedBox(height: 28),
          _buildTrackMetadata(context, themeColor, track),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(
    BuildContext context,
    PlayerState playerState,
    Color themeColor,
    Track? track, {
    double size = 380,
  }) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withValues(alpha: 0.65),
                  blurRadius: 60,
                  spreadRadius: -10,
                  offset: const Offset(0, 20),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AlbumArtWithTheme(
                imageUrl: track?.coverArt,
                size: size,
                borderRadius: BorderRadius.circular(16),
                onColorExtracted: (color) {
                  if (color != null && mounted) {
                    context.read<PlayerController>().updateThemeColor(color);
                    setState(() {});
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrackMetadata(
    BuildContext context,
    Color themeColor,
    Track? track, {
    bool compact = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          track?.title ?? AppLocalizations.of(context)!.noTrack,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: compact ? 18 : 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: compact ? 4 : 8),
        Text(
          track?.artist ?? AppLocalizations.of(context)!.unknownArtist,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            fontSize: compact ? 13 : 15,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFusedDock(
    BuildContext context,
    PlayerState playerState,
    Color themeColor,
    Track? track,
  ) {
    return FusedControlDock(
      playerState: playerState,
      themeColor: themeColor,
      track: track,
      showTranslations: _showTranslations,
      onPlayPause: () => _handlePlayPause(context, playerState),
      onPrevious: () => context.read<PlayerController>().playPrevious(),
      onNext: () => context.read<PlayerController>().playNext(),
      onVolumeChanged: (v) => context.read<PlayerController>().setVolume(v),
      onSeek: (progress) {
        final pos = Duration(
          milliseconds: (playerState.duration.inMilliseconds * progress)
              .round(),
        );
        context.read<PlayerController>().seek(pos);
      },
      onFavoriteToggle: track != null
          ? () => context.read<PlayerController>().toggleFavorite(track)
          : null,
      onPlaylistToggle: _drawerOpen ? _closeDrawer : _openDrawer,
      playlistToggleFocusNode: _playlistToggleNode,
      onToggleTranslations: () =>
          setState(() => _showTranslations = !_showTranslations),
    );
  }

  void _handlePlayPause(BuildContext context, PlayerState playerState) {
    final controller = context.read<PlayerController>();
    if (playerState.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
  }

  Widget _buildPlaylistDrawer(
    BuildContext context,
    PlayerState playerState,
    Color themeColor,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 600;

    return AnimatedBuilder(
      animation: _drawerController,
      builder: (context, _) {
        if (_drawerController.isDismissed) return const SizedBox.shrink();

        if (isNarrow) {
          return _buildBottomSheet(context, playerState);
        }
        return _buildSideDrawer(context, playerState);
      },
    );
  }

  Widget _buildBottomSheet(BuildContext context, PlayerState playerState) {
    return Stack(
      children: [
        GestureDetector(
          onTap: _closeDrawer,
          child: Opacity(
            opacity: _backdropOpacityAnimation.value,
            child: Container(color: Colors.black54),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: _drawerController,
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                  ),
                ),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.55,
              decoration: BoxDecoration(
                color: const Color(0xFF120F0D),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 40,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!.upNextCount(playerState.queue.length),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          autofocus: true,
                          focusNode: _drawerCloseNode,
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white54,
                            size: 20,
                          ),
                          onPressed: _closeDrawer,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: QueueView(
                      showHeader: false,
                      onClearQueue: () => playerState.clearQueue(),
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

  Widget _buildSideDrawer(BuildContext context, PlayerState playerState) {
    final drawerWidth = math.min(
      420.0,
      MediaQuery.of(context).size.width * 0.65,
    );
    return Stack(
      children: [
        GestureDetector(
          onTap: _closeDrawer,
          child: Opacity(
            opacity: _backdropOpacityAnimation.value,
            child: Container(color: Colors.black54),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: drawerWidth,
          child: SlideTransition(
            position: _drawerSlideAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF120F0D).withValues(alpha: 0.95),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 40,
                    offset: const Offset(-10, 0),
                  ),
                ],
                border: Border(
                  left: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!.upNextCount(playerState.queue.length),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          autofocus: true,
                          focusNode: _drawerCloseNode,
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white54,
                            size: 20,
                          ),
                          onPressed: _closeDrawer,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: QueueView(
                      showHeader: false,
                      onClearQueue: () => playerState.clearQueue(),
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
}

class _PillButton extends StatelessWidget {
  final String label;
  final Color themeColor;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.themeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
