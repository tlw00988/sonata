import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api.dart';
import '../player/player.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';

String _resolveCoverArt(BuildContext context, String id) {
  return resolveCoverUrl(context, id) ?? '';
}

/// Hands control back to the player once playback starts from a detail
/// route. Those routes are pushed on top of the bottom navigation, so
/// without popping them the tab switch stays invisible.
void _returnToPlayer(BuildContext context) {
  context.read<ValueNotifier<int>>().value = 0;
  Navigator.of(context).popUntil((route) => route.isFirst);
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MusicRepository? _repository;
  final LocalFileRepository _localRepository = LocalFileRepository();
  bool _isLoading = false;
  bool _isScanningLocal = false;
  String? _error;

  // Data
  List<Track> _songs = [];
  List<Album> _albums = [];
  List<Artist> _artists = [];
  List<Playlist> _playlists = [];
  List<Track> _localTracks = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Use repository from Provider if available
    final repo = context.read<MusicRepository?>();
    if (repo != _repository) {
      _repository = repo;
      if (_repository != null) {
        _loadAllData();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    // Repository is now obtained from Provider in didChangeDependencies
  }

  Future<void> _loadAllData() async {
    if (_repository == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final songsFuture = _repository!.getSongs(size: 500);
      final albumsFuture = _repository!.getAlbums(size: 500);
      final artistsFuture = _repository!.getArtists(size: 500);
      final playlistsFuture = _repository!.getPlaylists();

      final songs = await songsFuture;
      final albums = await albumsFuture;
      final artists = await artistsFuture;
      final playlists = await playlistsFuture;

      if (!mounted) return;
      setState(() {
        _songs = songs;
        _albums = albums;
        _artists = artists;
        _playlists = playlists;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final loc = AppLocalizations.of(context)!;
      setState(() {
        _error = loc.failedToLoadLibrary(e.toString());
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadAllData();
  }

  Future<void> _scanLocalFiles() async {
    setState(() {
      _isScanningLocal = true;
    });

    try {
      final tracks = await _localRepository.scanForAudioFiles();
      if (!mounted) return;
      setState(() {
        _localTracks = tracks;
        _isScanningLocal = false;
      });
    } catch (e) {
      if (!mounted) return;
      final loc = AppLocalizations.of(context)!;
      setState(() {
        _isScanningLocal = false;
        _error = loc.failedToScanLocalFiles(e.toString());
      });
    }
  }

  Future<void> _scanFolder() async {
    final loc = AppLocalizations.of(context)!;
    final dirPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: loc.selectFolderToScan,
    );
    if (dirPath == null) return;

    // Remember the folder so the next "scan local folders" (and the list in
    // Settings) includes it instead of silently dropping the pick.
    final known = await _localRepository.getScanDirectories();
    if (!known.contains(dirPath)) {
      await _localRepository.saveScanDirectories([...known, dirPath]);
    }

    setState(() {
      _isScanningLocal = true;
    });

    try {
      final tracks = await _localRepository.scanDirectory(dirPath);
      if (!mounted) return;
      setState(() {
        _localTracks.addAll(tracks);
        _isScanningLocal = false;
      });
    } catch (e) {
      if (!mounted) return;
      final loc = AppLocalizations.of(context)!;
      setState(() {
        _isScanningLocal = false;
        _error = loc.failedToScanFolder(e.toString());
      });
    }
  }

  Future<void> _pickAudioFiles() async {
    final loc = AppLocalizations.of(context)!;
    try {
      final files = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (files != null && files.files.isNotEmpty) {
        final tracks = <Track>[];
        for (final file in files.files) {
          final path = file.path;
          if (path == null || path.isEmpty) continue;
          final track = await _localRepository.trackFromFile(
            path,
            unknownArtist: loc.unknownArtist,
            unknownAlbum: loc.localFiles,
          );
          if (track != null) tracks.add(track);
        }

        if (!mounted) return;
        setState(() {
          _localTracks.addAll(tracks);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = loc.failedToPickFiles(e.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = colorScheme.primary;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc.libraryTitle,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      if (_isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        IconButton(
                          icon: Icon(
                            Icons.refresh,
                            color: colorScheme.onSurface,
                            size: 26,
                          ),
                          onPressed: _refresh,
                        ),
                      IconButton(
                        icon: Icon(
                          Icons.search,
                          color: colorScheme.onSurface,
                          size: 26,
                        ),
                        onPressed: () => _showSearch(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Connection status / error
            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: colorScheme.errorContainer,
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: colorScheme.onErrorContainer,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Tab bar
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: accentColor,
              indicatorWeight: 3,
              labelColor: colorScheme.onSurface,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(text: loc.songsTab),
                Tab(text: loc.albumsTab),
                Tab(text: loc.artistsTab),
                Tab(text: loc.playlistsTab),
                Tab(text: loc.localFilesTab),
              ],
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSongsTab(),
                  _buildAlbumsTab(),
                  _buildArtistsTab(),
                  _buildPlaylistsTab(),
                  _buildLocalFilesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongsTab() {
    final loc = AppLocalizations.of(context)!;
    if (_isLoading) return _buildLoadingIndicator();
    if (_songs.isEmpty) {
      return _buildEmptyState(
        icon: Icons.music_note_outlined,
        title: loc.noSongs,
        subtitle: _error ?? loc.noSongsHint,
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _songs.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 0.5,
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          indent: 72,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final track = _songs[index];
          return _LibraryTrackTile(
            track: track,
            onTap: () => _playTrack(context, track, index),
            onAddToQueue: () => _addToQueue(track),
          );
        },
      ),
    );
  }

  Widget _buildAlbumsTab() {
    final loc = AppLocalizations.of(context)!;
    if (_isLoading) return _buildLoadingIndicator();
    if (_albums.isEmpty) {
      return _buildEmptyState(
        icon: Icons.album_outlined,
        title: loc.noAlbums,
        subtitle: _error ?? loc.noAlbumsHint,
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = width > 1200
              ? 6
              : width > 900
              ? 5
              : width > 600
              ? 4
              : width > 400
              ? 3
              : 2;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _albums.length,
            itemBuilder: (context, index) {
              final album = _albums[index];
              return _AlbumGridTile(
                album: album,
                onTap: () => _navigateToAlbum(context, album),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildArtistsTab() {
    final loc = AppLocalizations.of(context)!;
    if (_isLoading) return _buildLoadingIndicator();
    if (_artists.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_outline,
        title: loc.noArtists,
        subtitle: _error ?? loc.noArtistsHint,
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _artists.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 0.5,
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          indent: 72,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final artist = _artists[index];
          return _ArtistListTile(
            artist: artist,
            onTap: () => _navigateToArtist(context, artist),
          );
        },
      ),
    );
  }

  Widget _buildPlaylistsTab() {
    final loc = AppLocalizations.of(context)!;
    if (_isLoading) return _buildLoadingIndicator();
    if (_playlists.isEmpty) {
      return _buildEmptyState(
        icon: Icons.queue_music_outlined,
        title: loc.noPlaylists,
        subtitle: _error ?? loc.noPlaylistsHint,
        actionLabel: loc.createPlaylist,
        onAction: () {},
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _playlists.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final playlist = _playlists[index];
          return _PlaylistTile(
            playlist: playlist,
            onTap: () => _navigateToPlaylist(context, playlist),
          );
        },
      ),
    );
  }

  Widget _buildLocalFilesTab() {
    final loc = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: _scanLocalFiles,
      child: _localTracks.isEmpty
          ? _buildEmptyState(
              icon: Icons.folder_outlined,
              title: loc.noLocalFiles,
              subtitle: _isScanningLocal ? loc.scanning : loc.scanLocalHint,
              actionLabel: _isScanningLocal ? null : loc.scanDefaultFolders,
              onAction: _isScanningLocal ? null : _scanLocalFiles,
              secondActionLabel: _isScanningLocal ? null : loc.pickFolder,
              onSecondAction: _isScanningLocal ? null : _scanFolder,
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _localTracks.length + 1,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 0.5,
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.1),
                indent: 72,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.folder,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          loc.localTracksCount(_localTracks.length),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.create_new_folder,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          onPressed: _scanFolder,
                          tooltip: loc.scanFolder,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.file_open,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          onPressed: _pickAudioFiles,
                          tooltip: loc.addAudioFiles,
                        ),
                        if (_isScanningLocal)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          IconButton(
                            icon: Icon(
                              Icons.refresh,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            onPressed: _scanLocalFiles,
                            tooltip: loc.rescan,
                          ),
                      ],
                    ),
                  );
                }
                final track = _localTracks[index - 1];
                return _LibraryTrackTile(
                  track: track,
                  onTap: () => _playLocalTrack(context, track, index - 1),
                  onAddToQueue: () => _addToQueue(track),
                );
              },
            ),
    );
  }

  Widget _buildLoadingIndicator() {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            loc.loadingLibrary,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
    String? secondActionLabel,
    VoidCallback? onSecondAction,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 20),
                label: Text(actionLabel),
              ),
            ],
            if (secondActionLabel != null && onSecondAction != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onSecondAction,
                icon: const Icon(Icons.folder_open, size: 20),
                label: Text(secondActionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _playTrack(BuildContext context, Track track, int index) {
    // Create queue from all songs starting at index
    final controller = context.read<PlayerController>();
    controller.playQueue(_songs, startIndex: index);
  }

  void _addToQueue(Track track) {
    final loc = AppLocalizations.of(context)!;
    context.read<PlayerController>().addToQueue(track);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.addedToQueue(track.title)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _playLocalTrack(BuildContext context, Track track, int index) {
    final controller = context.read<PlayerController>();
    controller.playQueue(_localTracks, startIndex: index);
  }

  void _navigateToAlbum(BuildContext context, Album album) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AlbumDetailScreen(album: album, repository: _repository!),
      ),
    );
  }

  void _navigateToArtist(BuildContext context, Artist artist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ArtistDetailScreen(artist: artist, repository: _repository!),
      ),
    );
  }

  void _navigateToPlaylist(BuildContext context, Playlist playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PlaylistDetailScreen(playlist: playlist, repository: _repository!),
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _MusicSearchDelegate(repository: _repository),
    );
  }
}

// Search delegate that uses the repository
class _MusicSearchDelegate extends SearchDelegate<String> {
  final MusicRepository? _repository;

  _MusicSearchDelegate({required this._repository});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context, playOnTap: true);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context, playOnTap: true);
  }

  Widget _buildSearchResults(BuildContext context, {bool playOnTap = false}) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              loc.searchHint,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_repository == null) {
      return Center(
        child: Text(
          loc.notConnected,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return FutureBuilder<List<Track>>(
      future: _repository!.search(query: query, songCount: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              loc.searchFailed(snapshot.error.toString()),
              style: TextStyle(color: colorScheme.error),
            ),
          );
        }

        final tracks = snapshot.data ?? [];

        if (tracks.isEmpty) {
          return Center(
            child: Text(
              loc.noResultsFor(query),
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];
            return ListTile(
              leading: track.coverArt.isNotEmpty
                  ? Image.network(
                      _resolveCoverArt(context, track.coverArt),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    )
                  : Icon(Icons.music_note, color: colorScheme.onSurfaceVariant),
              title: Text(track.title),
              subtitle: Text('${track.artist} • ${track.album}'),
              onTap: () {
                final controller = context.read<PlayerController>();
                final allTracks = snapshot.data ?? [];
                controller.playQueue(allTracks, startIndex: index);
                close(context, track.id);
              },
            );
          },
        );
      },
    );
  }
}

// Library item widgets
class _LibraryTrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;
  final VoidCallback onAddToQueue;

  const _LibraryTrackTile({
    required this.track,
    required this.onTap,
    required this.onAddToQueue,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onAddToQueue,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    track.coverArt.isNotEmpty &&
                        coverImageProvider(context, track.coverArt) != null
                    ? Image(
                        image: coverImageProvider(context, track.coverArt)!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.music_note,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      track.title,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${track.artist} • ${track.album}',
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
              Text(
                track.formattedDuration,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.add,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                onPressed: onAddToQueue,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlbumGridTile extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  const _AlbumGridTile({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: album.coverArt.isNotEmpty
                    ? Image.network(
                        _resolveCoverArt(context, album.coverArt),
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.album,
                          size: 48,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              album.name,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              album.artist,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtistListTile extends StatelessWidget {
  final Artist artist;
  final VoidCallback onTap;

  const _ArtistListTile({required this.artist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colorScheme.surfaceContainerHighest,
                backgroundImage: artist.coverArt.isNotEmpty
                    ? NetworkImage(_resolveCoverArt(context, artist.coverArt))
                    : null,
                child: artist.coverArt.isEmpty
                    ? Icon(
                        Icons.person,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.3,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      artist.name,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      loc.artistStats(artist.albumCount, artist.songCount),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;

  const _PlaylistTile({required this.playlist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: playlist.coverArt.isNotEmpty
                    ? Image.network(
                        _resolveCoverArt(context, playlist.coverArt),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.queue_music,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.3,
                          ),
                          size: 28,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      playlist.name,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      loc.playlistStats(
                        playlist.songCount,
                        _formatDuration(playlist.duration),
                      ),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int milliseconds) {
    final minutes = milliseconds ~/ 60000;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${remainingMinutes}m';
    }
    return '${remainingMinutes}m';
  }
}

// Detail screens
class AlbumDetailScreen extends StatefulWidget {
  final Album album;
  final MusicRepository repository;

  const AlbumDetailScreen({
    super.key,
    required this.album,
    required this.repository,
  });

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  List<Track> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    try {
      final tracks = await widget.repository.getSongsByAlbum(widget.album.id);
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: colorScheme.surface,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.album.coverArt.isNotEmpty
                      ? Image.network(
                          _resolveCoverArt(context, widget.album.coverArt),
                          fit: BoxFit.cover,
                        )
                      : Container(color: colorScheme.surfaceContainerHighest),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          colorScheme.surface.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.album.name,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.album.artist,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        loc.songsCount(widget.album.songCount),
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (widget.album.year > 0)
                        Text(
                          '${widget.album.year}',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _playAlbum(context),
                        icon: const Icon(Icons.play_arrow, size: 20),
                        label: Text(loc.play),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _addAlbumToQueue(context),
                        icon: const Icon(Icons.add, size: 20),
                        label: Text(loc.addToQueue),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_tracks.isEmpty)
                    Text(
                      loc.noTracksFound,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    )
                  else
                    ..._tracks.asMap().entries.map((entry) {
                      final index = entry.key;
                      final track = entry.value;
                      return _LibraryTrackTile(
                        track: track,
                        onTap: () => _playTrack(context, index),
                        onAddToQueue: () =>
                            context.read<PlayerController>().addToQueue(track),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _playAlbum(BuildContext context) {
    if (_tracks.isNotEmpty) {
      context.read<PlayerController>().playQueue(_tracks);
      _returnToPlayer(context);
    }
  }

  void _addAlbumToQueue(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    for (final track in _tracks) {
      context.read<PlayerController>().addToQueue(track);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.addedTracksToQueue(_tracks.length))),
    );
  }

  void _playTrack(BuildContext context, int index) {
    context.read<PlayerController>().playQueue(_tracks, startIndex: index);
    _returnToPlayer(context);
  }
}

class ArtistDetailScreen extends StatefulWidget {
  final Artist artist;
  final MusicRepository repository;

  const ArtistDetailScreen({
    super.key,
    required this.artist,
    required this.repository,
  });

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  List<Album> _albums = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    try {
      final albums = await widget.repository.getArtistAlbums(widget.artist.id);
      setState(() {
        _albums = albums;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: colorScheme.surface,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.artist.coverArt.isNotEmpty
                      ? Image.network(
                          _resolveCoverArt(context, widget.artist.coverArt),
                          fit: BoxFit.cover,
                        )
                      : Container(color: colorScheme.surfaceContainerHighest),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          colorScheme.surface.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.artist.name,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.artistStats(
                      widget.artist.albumCount,
                      widget.artist.songCount,
                    ),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_albums.isEmpty)
                    Text(
                      loc.noAlbumsFound,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: _albums.length,
                      itemBuilder: (context, index) {
                        final album = _albums[index];
                        return _AlbumGridTile(
                          album: album,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AlbumDetailScreen(
                                album: album,
                                repository: widget.repository,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;
  final MusicRepository repository;

  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
    required this.repository,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  List<Track> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    try {
      final playlist = await widget.repository.getPlaylist(widget.playlist.id);
      setState(() {
        _tracks = playlist?.tracks ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: colorScheme.surface,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.playlist.coverArt.isNotEmpty
                      ? Image.network(
                          _resolveCoverArt(context, widget.playlist.coverArt),
                          fit: BoxFit.cover,
                        )
                      : Container(color: colorScheme.surfaceContainerHighest),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          colorScheme.surface.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.playlist.name,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.playlistStats(
                      widget.playlist.songCount,
                      _formatDuration(widget.playlist.duration),
                    ),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _playPlaylist(context),
                        icon: const Icon(Icons.play_arrow, size: 20),
                        label: Text(loc.play),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _addToQueue(context),
                        icon: const Icon(Icons.add, size: 20),
                        label: Text(loc.addToQueue),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_tracks.isEmpty)
                    Text(
                      loc.noTracksFound,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    )
                  else
                    ..._tracks.asMap().entries.map((entry) {
                      final index = entry.key;
                      final track = entry.value;
                      return _LibraryTrackTile(
                        track: track,
                        onTap: () => _playTrack(context, index),
                        onAddToQueue: () =>
                            context.read<PlayerController>().addToQueue(track),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _playPlaylist(BuildContext context) {
    if (_tracks.isNotEmpty) {
      context.read<PlayerController>().playQueue(_tracks);
      _returnToPlayer(context);
    }
  }

  void _addToQueue(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    for (final track in _tracks) {
      context.read<PlayerController>().addToQueue(track);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.addedTracksToQueue(_tracks.length))),
    );
  }

  void _playTrack(BuildContext context, int index) {
    context.read<PlayerController>().playQueue(_tracks, startIndex: index);
    _returnToPlayer(context);
  }

  String _formatDuration(int milliseconds) {
    final minutes = milliseconds ~/ 60000;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${remainingMinutes}m';
    }
    return '${remainingMinutes}m';
  }
}
