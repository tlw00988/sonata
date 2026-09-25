import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';

import 'repository.dart';

/// Whether [value] points at a file on this device instead of a server id.
bool isLocalCoverPath(String value) {
  if (value.startsWith('/') || value.startsWith(r'\')) return true;
  if (value.startsWith('file://')) return true;
  return RegExp(r'^[A-Za-z]:[\\/]').hasMatch(value);
}

File _asFile(String path) =>
    path.startsWith('file://') ? File.fromUri(Uri.parse(path)) : File(path);

/// Turns a [Track.coverArt] / album art reference into something displayable.
///
/// Remote urls pass through, local paths stay local, and server ids are
/// resolved through the connected repository. Returns `null` when the id
/// cannot be resolved, so callers can fall back to a placeholder.
String? resolveCoverUrl(BuildContext context, String coverArt) {
  if (coverArt.isEmpty) return null;
  if (coverArt.startsWith('http://') || coverArt.startsWith('https://')) {
    return coverArt;
  }
  if (isLocalCoverPath(coverArt)) return coverArt;
  try {
    return context.read<MusicRepository>().getCoverArtUrl(coverArt);
  } catch (_) {
    return null;
  }
}

/// Builds the [ImageProvider] for a cover reference, or `null` if unusable.
ImageProvider? coverImageProvider(BuildContext context, String coverArt) {
  final url = resolveCoverUrl(context, coverArt);
  if (url == null || url.isEmpty) return null;
  if (isLocalCoverPath(url)) {
    final file = _asFile(url);
    return file.existsSync() ? FileImage(file) : null;
  }
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return CachedNetworkImageProvider(url);
  }
  return null;
}

/// 不依赖 [BuildContext] 的封面取色用 [ImageProvider]。
///
/// 只接受本地路径与 http(s) 地址（服务器 id 需先经
/// [MusicRepository.getCoverArtUrl] 换成地址），无法解析时返回 null。
ImageProvider? coverColorImageProvider(String cover) {
  if (cover.isEmpty) return null;
  if (isLocalCoverPath(cover)) {
    final file = _asFile(cover);
    return file.existsSync() ? FileImage(file) : null;
  }
  if (cover.startsWith('http://') || cover.startsWith('https://')) {
    return CachedNetworkImageProvider(cover);
  }
  return null;
}

/// 从封面图片提取主题色：优先鲜艳色，其次主色，最后柔和色。
Future<Color?> extractColorFromCover(ImageProvider provider) async {
  final palette = await PaletteGenerator.fromImageProvider(provider);
  return palette.vibrantColor?.color ??
      palette.dominantColor?.color ??
      palette.mutedColor?.color;
}
