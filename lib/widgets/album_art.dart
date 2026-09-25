import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api/api.dart';

class AlbumArt extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AlbumArt({
    super.key,
    this.imageUrl,
    this.size = 200,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  String? _resolveUrl(BuildContext context) {
    return resolveCoverUrl(context, imageUrl ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);
    final url = _resolveUrl(context);

    if (url == null) {
      return _buildPlaceholder(context, radius);
    }

    return ClipRRect(
      borderRadius: radius,
      child: IgnorePointer(
        child: isLocalCoverPath(url)
            ? Image.file(
                url.startsWith('file://')
                    ? File.fromUri(Uri.parse(url))
                    : File(url),
                width: size,
                height: size,
                fit: fit,
                errorBuilder: (context, url, error) =>
                    _buildError(context, radius),
              )
            : CachedNetworkImage(
                imageUrl: url,
                width: size,
                height: size,
                fit: fit,
                placeholder: (context, url) =>
                    _buildPlaceholder(context, radius),
                errorWidget: (context, url, error) =>
                    _buildError(context, radius),
                memCacheWidth: size.toInt(),
                memCacheHeight: size.toInt(),
              ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context, BorderRadius radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surfaceContainerHighest,
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child:
          placeholder ??
          Icon(
            Icons.music_note,
            size: size * 0.4,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
    );
  }

  Widget _buildError(BuildContext context, BorderRadius radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child:
          errorWidget ??
          Icon(
            Icons.broken_image,
            size: size * 0.4,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
    );
  }
}

class AlbumArtWithTheme extends StatefulWidget {
  final String? imageUrl;
  final double size;
  final BorderRadius? borderRadius;
  final Function(Color?)? onColorExtracted;

  const AlbumArtWithTheme({
    super.key,
    this.imageUrl,
    this.size = 200,
    this.borderRadius,
    this.onColorExtracted,
  });

  @override
  State<AlbumArtWithTheme> createState() => _AlbumArtWithThemeState();
}

class _AlbumArtWithThemeState extends State<AlbumArtWithTheme> {
  bool _didExtract = false;

  @override
  Widget build(BuildContext context) {
    return AlbumArt(
      imageUrl: widget.imageUrl,
      size: widget.size,
      borderRadius: widget.borderRadius,
    );
  }

  @override
  void didUpdateWidget(covariant AlbumArtWithTheme oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _extractColor();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didExtract) {
      _didExtract = true;
      _extractColor();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _resolveUrl(BuildContext context) {
    return resolveCoverUrl(context, widget.imageUrl ?? '') ?? '';
  }

  Future<void> _extractColor() async {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      widget.onColorExtracted?.call(null);
      return;
    }

    try {
      final resolvedUrl = _resolveUrl(context);
      if (resolvedUrl.isEmpty) {
        widget.onColorExtracted?.call(null);
        return;
      }
      if (kDebugMode) print('ThemeColor: extracting from $resolvedUrl');
      final imageProvider = isLocalCoverPath(resolvedUrl)
          ? FileImage(
              resolvedUrl.startsWith('file://')
                  ? File.fromUri(Uri.parse(resolvedUrl))
                  : File(resolvedUrl),
            )
          : CachedNetworkImageProvider(resolvedUrl) as ImageProvider;
      final extractedColor = await extractColorFromCover(imageProvider);

      if (kDebugMode) {
        print('ThemeColor: extracted ${extractedColor?.toARGB32()}');
      }
      widget.onColorExtracted?.call(extractedColor);
    } catch (e) {
      if (kDebugMode) print('ThemeColor: error $e');
      widget.onColorExtracted?.call(null);
    }
  }
}

// Helper to extract color from image URL without widget
Future<Color?> extractColorFromImageUrl(String imageUrl) async {
  try {
    return await extractColorFromCover(CachedNetworkImageProvider(imageUrl));
  } catch (e) {
    return null;
  }
}
