import 'package:flutter/material.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';

class TrackInfo extends StatelessWidget {
  final Track? track;
  final TextStyle? titleStyle;
  final TextStyle? artistStyle;
  final TextStyle? albumStyle;
  final CrossAxisAlignment alignment;
  final MainAxisSize mainAxisSize;
  final double spacing;

  const TrackInfo({
    super.key,
    this.track,
    this.titleStyle,
    this.artistStyle,
    this.albumStyle,
    this.alignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.min,
    this.spacing = 4,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    if (track == null) {
      return Column(
        crossAxisAlignment: alignment,
        mainAxisSize: mainAxisSize,
        children: [
          Text(
            loc.noTrackPlaying,
            style: titleStyle ?? TextStyle(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            loc.selectTrackToPlay,
            style: artistStyle ?? TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: mainAxisSize,
      children: [
        Text(
          track!.title,
          style: titleStyle ?? TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignment == CrossAxisAlignment.center ? TextAlign.center : TextAlign.start,
        ),
        SizedBox(height: spacing),
        Text(
          track!.artist,
          style: artistStyle ?? TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignment == CrossAxisAlignment.center ? TextAlign.center : TextAlign.start,
        ),
        if (track!.album.isNotEmpty) ...[
          SizedBox(height: spacing),
          Text(
            track!.album,
            style: albumStyle ?? TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignment == CrossAxisAlignment.center ? TextAlign.center : TextAlign.start,
          ),
        ],
      ],
    );
  }
}

class NowPlayingTrackInfo extends StatelessWidget {
  final Track? track;
  final Color? themeColor;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const NowPlayingTrackInfo({
    super.key,
    this.track,
    this.themeColor,
    this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            track?.title ?? loc.noTrack,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            track?.artist ?? loc.unknownArtist,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (track?.album.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              track!.album,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
          if (onFavoriteToggle != null) ...[
            const SizedBox(height: 12),
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? colorScheme.error : colorScheme.onSurfaceVariant,
                size: 24,
              ),
              onPressed: onFavoriteToggle,
              tooltip: isFavorite ? loc.removeFromFavorites : loc.addToFavorites,
            ),
          ],
        ],
      ),
    );
  }
}