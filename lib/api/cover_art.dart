import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
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
