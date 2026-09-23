import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../player/player.dart';
import '../models/models.dart';
import '../api/repository.dart';
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
  });

  @override
  State<FusedControlDock> createState() => _FusedControlDockState();
}

class _FusedControlDockState extends State<FusedControlDock> {
  bool _volumeExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    final accent = widget.themeColor ?? colorScheme.primary;
    final progress = widget.playerState.progress.clamp(0.0, 1.0);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 500;

    return Padding(
      padding: EdgeInsets.fromLTRB(isSmall ? 12 : 24, 0, isSmall ? 12 : 24, isSmall ? 12 : 16),
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
                      if (!isSmall) ...[
                        _buildPillBadge(accent, loc),
                        const Spacer(),
                      ],
                      _buildCenterControls(accent, isSmall: isSmall),
                      const Spacer(),
                      Flexible(
                        child: _buildRightSection(accent, isSmall: isSmall),
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
        border: Border.all(
          color: accent.withValues(alpha: 0.3),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.track != null && widget.track!.coverArt.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Builder(
                builder: (context) {
                  final url = widget.track!.coverArt.startsWith('http')
                      ? widget.track!.coverArt
                      : context.read<MusicRepository>().getCoverArtUrl(widget.track!.coverArt);
                  return Image.network(
                    url,
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
                      child: const Icon(Icons.music_note,
                          color: Colors.white54, size: 16),
                    ),
                  );
                },
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
              child: const Icon(Icons.music_note, color: Colors.white54, size: 16),
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
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPlayPause,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: isSmall ? 34 : 40,
              height: isSmall ? 34 : 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                  ),
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

  Widget _buildRightSection(Color accent, {bool isSmall = false}) {
    final volumeIcon = widget.playerState.volume > 0.5
        ? Icons.volume_up_rounded
        : widget.playerState.volume > 0
            ? Icons.volume_down_rounded
            : Icons.volume_off_rounded;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Time
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
        if (!isSmall) ...[
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
        if (isSmall)
          _buildVolumeToggle(volumeIcon, accent),
        // Heart
        if (widget.onFavoriteToggle != null)
          GestureDetector(
            onTap: widget.onFavoriteToggle,
            child: Icon(
              widget.playerState.isFavorite ? Icons.favorite : Icons.favorite_border,
              size: 14,
              color: widget.playerState.isFavorite
                  ? const Color(0xFFF43F5E)
                  : Colors.white54,
            ),
          ),
        const SizedBox(width: 10),
        // Playlist toggle
        if (widget.onPlaylistToggle != null)
          GestureDetector(
            onTap: widget.onPlaylistToggle,
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
      ],
    );
  }

  Widget _buildVolumeToggle(IconData volumeIcon, Color accent) {
    return GestureDetector(
      onTap: () => setState(() => _volumeExpanded = !_volumeExpanded),
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
                      color: const Color(0xFF120F0D).withValues(alpha: 0.95),
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
                  ),
                ),
              ),
          ],
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: size, color: color),
        ),
      ),
    );
  }
}
