// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Sonata';

  @override
  String get playerTab => '播放器';

  @override
  String get libraryTab => '音乐库';

  @override
  String get settingsTab => '设置';

  @override
  String get libraryTitle => '音乐库';

  @override
  String get songsTab => '歌曲';

  @override
  String get albumsTab => '专辑';

  @override
  String get artistsTab => '艺术家';

  @override
  String get playlistsTab => '播放列表';

  @override
  String get localFilesTab => '本地文件';

  @override
  String get noSongs => '暂无歌曲';

  @override
  String get noSongsHint => '歌曲将显示在这里';

  @override
  String get noAlbums => '暂无专辑';

  @override
  String get noAlbumsHint => '专辑将显示在这里';

  @override
  String get noArtists => '暂无艺术家';

  @override
  String get noArtistsHint => '艺术家将显示在这里';

  @override
  String get noPlaylists => '暂无播放列表';

  @override
  String get noPlaylistsHint => '播放列表将显示在这里';

  @override
  String get createPlaylist => '创建播放列表';

  @override
  String get noLocalFiles => '暂无本地文件';

  @override
  String get scanning => '扫描中...';

  @override
  String get scanLocalHint => '扫描音乐文件夹或选择文件';

  @override
  String get scanDefaultFolders => '扫描本地目录';

  @override
  String get pickFolder => '选择文件夹';

  @override
  String localTracksCount(int count) {
    return '$count 首本地歌曲';
  }

  @override
  String get scanFolder => '扫描文件夹';

  @override
  String get addAudioFiles => '添加音频文件';

  @override
  String get rescan => '重新扫描';

  @override
  String get loadingLibrary => '加载音乐库中...';

  @override
  String failedToLoadLibrary(String error) {
    return '加载音乐库失败：$error';
  }

  @override
  String failedToScanLocalFiles(String error) {
    return '扫描本地文件失败：$error';
  }

  @override
  String get selectFolderToScan => '选择要扫描的文件夹';

  @override
  String failedToScanFolder(String error) {
    return '扫描文件夹失败：$error';
  }

  @override
  String failedToPickFiles(String error) {
    return '选择文件失败：$error';
  }

  @override
  String addedToQueue(String title) {
    return '已将「$title」添加到播放队列';
  }

  @override
  String get searchHint => '搜索歌曲、专辑、艺术家...';

  @override
  String get notConnected => '未连接到服务器';

  @override
  String searchFailed(String error) {
    return '搜索失败：$error';
  }

  @override
  String noResultsFor(String query) {
    return '未找到「$query」的结果';
  }

  @override
  String albumsCount(int albumCount) {
    return '$albumCount 张专辑';
  }

  @override
  String songsCount(int songCount) {
    return '$songCount 首歌曲';
  }

  @override
  String artistStats(int albumCount, int songCount) {
    return '$albumCount 张专辑 • $songCount 首歌曲';
  }

  @override
  String get play => '播放';

  @override
  String get addToQueue => '添加到队列';

  @override
  String get noTracksFound => '未找到歌曲';

  @override
  String addedTracksToQueue(int count) {
    return '已添加 $count 首歌曲到队列';
  }

  @override
  String get noAlbumsFound => '未找到专辑';

  @override
  String playlistStats(int songCount, String duration) {
    return '$songCount 首歌曲 • $duration';
  }

  @override
  String get unknownArtist => '未知艺术家';

  @override
  String get unknownAlbum => '未知专辑';

  @override
  String get localFiles => '本地文件';

  @override
  String get noTrackPlaying => '未在播放';

  @override
  String get selectTrackToPlay => '选择一首歌曲开始播放';

  @override
  String get noTrack => '未在播放';

  @override
  String get noLyricsAvailable => '暂无歌词';

  @override
  String get playbackError => '播放出错';

  @override
  String get queueEmpty => '播放队列为空';

  @override
  String get addTracksToStart => '添加歌曲开始播放';

  @override
  String upNextCount(int count) {
    return '即将播放 ($count)';
  }

  @override
  String get clearQueue => '清空队列';

  @override
  String get closeQueue => '关闭队列';

  @override
  String get removeFromQueue => '从队列中移除';

  @override
  String tracksRemaining(int count) {
    return '还有 $count 首歌曲';
  }

  @override
  String get removeFromFavorites => '取消收藏';

  @override
  String get addToFavorites => '收藏';

  @override
  String get settingsTitle => '设置';

  @override
  String get navidromeSection => 'Navidrome / OpenSubsonic';

  @override
  String get serverUrl => '服务器地址';

  @override
  String get serverUrlHint => 'https://your-navidrome.example.com';

  @override
  String get username => '用户名';

  @override
  String get usernameHint => '输入用户名';

  @override
  String get password => '密码';

  @override
  String get passwordHint => '输入密码';

  @override
  String get apiKey => 'API 密钥（可选）';

  @override
  String get apiKeyHint => '或在 Navidrome 设置中获取 API 密钥';

  @override
  String get enterApiKeyOrCredentials => '请输入 API 密钥或用户名和密码';

  @override
  String get connectionFailed => '连接失败 - 请检查凭据';

  @override
  String connectionError(String error) {
    return '错误：$error';
  }

  @override
  String connectedTo(String url) {
    return '已连接到 $url';
  }

  @override
  String get testing => '测试中...';

  @override
  String get testConnection => '测试连接';

  @override
  String get disconnect => '断开连接';

  @override
  String get appearance => '外观';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get licenses => '开源许可';

  @override
  String get openSourceLicenses => '开源许可信息';

  @override
  String get systemTheme => '跟随系统';

  @override
  String get systemThemeHint => '跟随设备设置';

  @override
  String get lightTheme => '浅色模式';

  @override
  String get lightThemeHint => '始终使用浅色';

  @override
  String get darkTheme => '深色模式';

  @override
  String get darkThemeHint => '始终使用深色';

  @override
  String get localMusicSection => '本地音乐';

  @override
  String get localMusicDirsHint => '用于扫描本地音频文件的目录。添加或移除后，请在音乐库标签页重新扫描生效。';

  @override
  String get addFolder => '添加目录';

  @override
  String get removeFolder => '移除目录';

  @override
  String get restoreDefaultFolders => '恢复默认目录';

  @override
  String get noLocalDirs => '尚未添加目录';

  @override
  String get folderMissing => '目录不存在';
}
