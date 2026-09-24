import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiKeyController = TextEditingController();

  bool _isConnected = false;
  bool _isTesting = false;
  String? _connectionError;

  final LocalFileRepository _localRepository = LocalFileRepository();

  /// Folders scanned for local audio, as listed in settings.
  List<String> _musicDirs = [];

  /// Subset of [_musicDirs] that does not exist on disk anymore.
  final Set<String> _missingDirs = {};

  bool _musicDirsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadMusicDirs();
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverUrlController.text = prefs.getString('server_url') ?? '';
      _usernameController.text = prefs.getString('username') ?? '';
      _passwordController.text = prefs.getString('password') ?? '';
      _apiKeyController.text = prefs.getString('api_key') ?? '';
      _isConnected = prefs.getBool('is_connected') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', _serverUrlController.text.trim());
    await prefs.setString('username', _usernameController.text.trim());
    await prefs.setString('password', _passwordController.text.trim());
    await prefs.setString('api_key', _apiKeyController.text.trim());
    await prefs.setBool('is_connected', true);
  }

  Future<void> _clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // Only the server connection keys. Clearing everything would also wipe
    // the theme choice and the managed music folders.
    for (final key in [
      'server_url',
      'username',
      'password',
      'api_key',
      'is_connected',
    ]) {
      await prefs.remove(key);
    }
  }

  Future<void> _loadMusicDirs() async {
    final dirs = await _localRepository.getScanDirectories();
    final missing = await _findMissingDirs(dirs);
    if (!mounted) return;
    setState(() {
      _musicDirs = dirs;
      _missingDirs
        ..clear()
        ..addAll(missing);
      _musicDirsLoaded = true;
    });
  }

  Future<Set<String>> _findMissingDirs(List<String> dirs) async {
    final missing = <String>{};
    for (final dir in dirs) {
      try {
        if (!await Directory(dir).exists()) missing.add(dir);
      } catch (e) {
        // Unreadable path: treat it as missing so the row is flagged.
        missing.add(dir);
      }
    }
    return missing;
  }

  Future<void> _addMusicDir() async {
    final loc = AppLocalizations.of(context)!;
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: loc.addFolder,
    );
    if (path == null || !mounted) return;

    final saved = await _localRepository.saveScanDirectories([
      ..._musicDirs,
      path,
    ]);
    final missing = await _findMissingDirs(saved);
    if (!mounted) return;
    setState(() {
      _musicDirs = saved;
      _missingDirs
        ..clear()
        ..addAll(missing);
    });
  }

  Future<void> _removeMusicDir(String path) async {
    final saved = await _localRepository.saveScanDirectories(
      _musicDirs.where((dir) => dir != path).toList(),
    );
    if (!mounted) return;
    setState(() {
      _musicDirs = saved;
      _missingDirs.remove(path);
    });
  }

  Future<void> _restoreDefaultMusicDirs() async {
    final defaults = await _localRepository.defaultDirectories();
    final saved = await _localRepository.saveScanDirectories(defaults);
    final missing = await _findMissingDirs(saved);
    if (!mounted) return;
    setState(() {
      _musicDirs = saved;
      _missingDirs
        ..clear()
        ..addAll(missing);
    });
  }

  Future<void> _testConnection() async {
    final loc = AppLocalizations.of(context)!;
    final apiKey = _apiKeyController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (apiKey.isEmpty && (username.isEmpty || password.isEmpty)) {
      setState(() {
        _connectionError = loc.enterApiKeyOrCredentials;
      });
      return;
    }

    final updateRepo = context.read<Function(String, String, String)>();

    setState(() {
      _isTesting = true;
      _connectionError = null;
    });

    try {
      final auth = apiKey.isNotEmpty
          ? SubsonicAuth(username: 'unused', apiKey: apiKey)
          : SubsonicAuth(username: username, password: password);
      final client = SubsonicClient(
        baseUrl: _serverUrlController.text.trim().replaceAll(RegExp(r'/$'), ''),
        auth: auth,
      );

      final result = await client.ping();

      if (!mounted) return;

      setState(() {
        _isConnected = result;
        _connectionError = result ? null : loc.connectionFailed;
        if (result) {
          _saveSettings();
          updateRepo(_serverUrlController.text.trim(), username, password);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isConnected = false;
        _connectionError = loc.connectionError(e.toString());
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _disconnect() async {
    final clearRepo = context.read<Function()>();
    await _clearSettings();
    if (!mounted) return;
    setState(() {
      _serverUrlController.clear();
      _usernameController.clear();
      _passwordController.clear();
      _apiKeyController.clear();
      _isConnected = false;
      _connectionError = null;
    });
    clearRepo();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              loc.settingsTitle,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 32),

            // Navidrome/OpenSubsonic Section
            _buildSectionHeader(loc.navidromeSection),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _serverUrlController,
              label: loc.serverUrl,
              hint: loc.serverUrlHint,
              prefixIcon: Icons.link,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _usernameController,
              label: loc.username,
              hint: loc.usernameHint,
              prefixIcon: Icons.person,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _passwordController,
              label: loc.password,
              hint: loc.passwordHint,
              prefixIcon: Icons.lock,
              obscureText: true,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _apiKeyController,
              label: loc.apiKey,
              hint: loc.apiKeyHint,
              prefixIcon: Icons.vpn_key,
            ),
            const SizedBox(height: 24),

            if (_connectionError != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _connectionError!,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),

            if (_isConnected)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc.connectedTo(_serverUrlController.text),
                        style: TextStyle(color: colorScheme.onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
              ),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_find),
                    label: Text(_isTesting ? loc.testing : loc.testConnection),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (_isConnected) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _disconnect,
                      icon: const Icon(Icons.link_off),
                      label: Text(loc.disconnect),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 32),

            // Appearance Section
            _buildSectionHeader(loc.appearance),
            const SizedBox(height: 16),

            _buildThemeModeTile(context),
            const SizedBox(height: 32),

            // Local Music Section
            _buildLocalMusicSection(),
            const SizedBox(height: 32),

            // About Section
            _buildSectionHeader(loc.about),
            const SizedBox(height: 16),

            _buildSettingTile(
              icon: Icons.info_outline,
              title: loc.version,
              subtitle: '1.0.0',
              onTap: null,
            ),
            _buildSettingTile(
              icon: Icons.article_outlined,
              title: loc.licenses,
              subtitle: loc.openSourceLicenses,
              onTap: () => showLicensePage(context: context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildLocalMusicSection() {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildSectionHeader(loc.localMusicSection)),
            TextButton.icon(
              onPressed: _addMusicDir,
              icon: const Icon(Icons.add, size: 18),
              label: Text(loc.addFolder),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          loc.localMusicDirsHint,
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 16),
        if (!_musicDirsLoaded)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (_musicDirs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.folder_open,
                  color: colorScheme.onSurfaceVariant,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  loc.noLocalDirs,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _musicDirs.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, color: colorScheme.outlineVariant),
                  _buildMusicDirRow(_musicDirs[i]),
                ],
              ],
            ),
          ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _restoreDefaultMusicDirs,
            icon: const Icon(Icons.restart_alt, size: 18),
            label: Text(loc.restoreDefaultFolders),
          ),
        ),
      ],
    );
  }

  Widget _buildMusicDirRow(String path) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isMissing = _missingDirs.contains(path);

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 4, top: 4, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isMissing ? colorScheme.error : colorScheme.primary)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isMissing ? Icons.folder_off : Icons.folder,
              color: isMissing ? colorScheme.error : colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                ),
                if (isMissing)
                  Text(
                    loc.folderMissing,
                    style: TextStyle(color: colorScheme.error, fontSize: 12),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeMusicDir(path),
            tooltip: loc.removeFolder,
            icon: Icon(
              Icons.delete_outline,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    bool obscureText = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            prefixIcon: Icon(prefixIcon, color: colorScheme.onSurfaceVariant),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeModeTile(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final currentMode = context.read<ThemeMode>();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildRadioTile(
            context: context,
            icon: Icons.brightness_auto,
            title: loc.systemTheme,
            subtitle: loc.systemThemeHint,
            value: ThemeMode.system,
            groupValue: currentMode,
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          _buildRadioTile(
            context: context,
            icon: Icons.light_mode,
            title: loc.lightTheme,
            subtitle: loc.lightThemeHint,
            value: ThemeMode.light,
            groupValue: currentMode,
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          _buildRadioTile(
            context: context,
            icon: Icons.dark_mode,
            title: loc.darkTheme,
            subtitle: loc.darkThemeHint,
            value: ThemeMode.dark,
            groupValue: currentMode,
          ),
        ],
      ),
    );
  }

  Widget _buildRadioTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeMode value,
    required ThemeMode groupValue,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = value == groupValue;
    final setThemeMode = context.read<Function(ThemeMode)>();

    return InkWell(
      onTap: () => setThemeMode(value),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.15)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Radio<ThemeMode>(
              value: value,
              groupValue: groupValue,
              onChanged: (v) => setThemeMode(v!),
              activeColor: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
