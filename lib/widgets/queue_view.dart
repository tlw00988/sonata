import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../player/player.dart';
import '../models/models.dart';
import '../api/api.dart';
import '../l10n/app_localizations.dart';

class QueueView extends StatelessWidget {
  final bool showHeader;
  final VoidCallback? onClearQueue;
  final VoidCallback? onClose;

  const QueueView({
    super.key,
    this.showHeader = true,
    this.onClearQueue,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerState>(
      builder: (context, playerState, child) {
        if (!playerState.hasQueue) {
          return _buildEmptyQueue(context);
        }

        return Column(
          children: [
            if (showHeader) _buildHeader(context, playerState),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: playerState.queue.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                  indent: 72,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) => _QueueItem(
                  track: playerState.queue[index],
                  index: index,
                  isCurrent: index == playerState.currentIndex,
                  onTap: () => _playAtIndex(context, playerState, index),
                  onRemove: () => _removeFromQueue(playerState, index),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyQueue(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.queue_music_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            loc.queueEmpty,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.addTracksToStart,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PlayerState playerState) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            loc.upNextCount(playerState.queue.length),
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              if (onClearQueue != null)
                IconButton(
                  icon: Icon(
                    Icons.clear_all,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onClearQueue,
                  tooltip: loc.clearQueue,
                ),
              if (onClose != null)
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onClose,
                  tooltip: loc.closeQueue,
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _playAtIndex(BuildContext context, PlayerState playerState, int index) {
    final controller = context.read<PlayerController>();
    controller.playQueue(playerState.queue, startIndex: index);
  }

  void _removeFromQueue(PlayerState playerState, int index) {
    playerState.removeFromQueue(index);
  }
}

class _QueueItem extends StatelessWidget {
  final Track track;
  final int index;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _QueueItem({
    required this.track,
    required this.index,
    required this.isCurrent,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Track number / playing indicator
              SizedBox(
                width: 40,
                child: Center(
                  child: isCurrent
                      ? Icon(
                          Icons.equalizer,
                          size: 18,
                          color: accentColor,
                        )
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                        ),
                ),
              ),
              // Album art
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: colorScheme.surfaceVariant,
                ),
                clipBehavior: Clip.antiAlias,
                child: track.coverArt.isNotEmpty &&
                        coverImageProvider(context, track.coverArt) != null
                    ? Image(
                        image: coverImageProvider(context, track.coverArt)!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.music_note,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
                      )
                    : Icon(
                        Icons.music_note,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      ),
              ),
              const SizedBox(width: 12),
              // Track info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      track.title,
                      style: TextStyle(
                        color: isCurrent ? accentColor : colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      track.artist,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Duration and remove button
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    track.formattedDuration,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    onPressed: onRemove,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: AppLocalizations.of(context)!.removeFromQueue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MiniQueueBar extends StatelessWidget {
  final PlayerState playerState;
  final VoidCallback onTap;

  const MiniQueueBar({
    super.key,
    required this.playerState,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!playerState.hasQueue) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    final remaining = playerState.queue.length - playerState.currentIndex - 1;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.queue_music,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                loc.tracksRemaining(remaining),
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}