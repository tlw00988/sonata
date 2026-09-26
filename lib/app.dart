import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'l10n/app_localizations.dart';
import 'credentials.dart';
import 'theme/theme.dart';
import 'player/player.dart';
import 'screens/screens.dart';
import 'api/api.dart';
import 'widgets/tab_focus_scope.dart';

class SonataApp extends StatefulWidget {
  const SonataApp({super.key});

  @override
  State<SonataApp> createState() => _SonataAppState();
}

class _SonataAppState extends State<SonataApp> {
  MusicRepository? _repository;
  bool _isInitialized = false;
  ThemeMode _themeMode = ThemeMode.system;

  /// Currently visible bottom-tab. Lives above the Navigator so detail
  /// routes pushed from the library can hand control back to the player.
  final ValueNotifier<int> _tabIndex = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _initializeRepository();
  }

  @override
  void dispose() {
    _tabIndex.dispose();
    super.dispose();
  }

  Future<void> _initializeRepository() async {
    final prefs = await SharedPreferences.getInstance();
    final credentials = Credentials();

    final themeModeIndex = prefs.getInt('theme_mode') ?? 0;
    _themeMode = ThemeMode.values[themeModeIndex.clamp(0, 2)];

    final serverUrl = prefs.getString('server_url');
    final username = prefs.getString('username');
    final password = await credentials.readPassword();
    final apiKey = await credentials.readApiKey();

    if (serverUrl != null && serverUrl.isNotEmpty) {
      final SubsonicAuth auth;
      if (apiKey != null && apiKey.isNotEmpty) {
        auth = SubsonicAuth(username: 'unused', apiKey: apiKey);
      } else if (username != null &&
          password != null &&
          username.isNotEmpty &&
          password.isNotEmpty) {
        auth = SubsonicAuth(username: username, password: password);
      } else {
        setState(() {
          _isInitialized = true;
        });
        return;
      }
      final client = SubsonicClient(baseUrl: serverUrl, auth: auth);
      _repository = MusicRepository(client);
    }
    setState(() {
      _isInitialized = true;
    });
  }

  void _updateRepository(String serverUrl, String username, String password) {
    final auth = SubsonicAuth(username: username, password: password);
    final client = SubsonicClient(baseUrl: serverUrl, auth: auth);
    setState(() {
      _repository = MusicRepository(client);
    });
  }

  void _clearRepository() {
    setState(() {
      _repository = null;
    });
  }

  void setThemeMode(ThemeMode mode) async {
    setState(() {
      _themeMode = mode;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerState()),
        ChangeNotifierProvider(
          create: (context) {
            final state = context.read<PlayerState>();
            final controller = PlayerController(state: state);
            if (_repository != null) {
              controller.setRepository(_repository!);
            }
            return controller;
          },
        ),
        if (_repository != null)
          Provider<MusicRepository>.value(value: _repository!),
        Provider<Function(String, String, String)>.value(
          value: _updateRepository,
        ),
        Provider<Function()>.value(value: _clearRepository),
        Provider<Function(ThemeMode)>.value(value: setThemeMode),
        Provider<ThemeMode>.value(value: _themeMode),
        // _tabIndex 是 ValueNotifier，Provider 会拒绝 Listenable 子类（debug 下
        // 直接抛异常打断构建），改用 ChangeNotifierProvider；它的消费者都用
        // context.read + ValueListenableBuilder，不依赖 Provider 驱动重建。
        ChangeNotifierProvider<ValueNotifier<int>>.value(value: _tabIndex),
      ],
      child: DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) {
          final lightScheme =
              lightDynamic ??
              ColorScheme.fromSeed(
                seedColor: AppTheme.lightTheme.colorScheme.primary,
                brightness: Brightness.light,
              );
          final darkScheme =
              darkDynamic ??
              ColorScheme.fromSeed(
                seedColor: AppTheme.darkTheme.colorScheme.primary,
                brightness: Brightness.dark,
              );

          final effectiveLight = AppTheme.lightTheme.copyWith(
            colorScheme: lightScheme,
            navigationBarTheme: AppTheme.lightTheme.navigationBarTheme.copyWith(
              indicatorColor: lightScheme.primary.withValues(alpha: 0.12),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return TextStyle(
                    color: lightScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  );
                }
                return TextStyle(
                  color: lightScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                );
              }),
            ),
            sliderTheme: AppTheme.lightTheme.sliderTheme.copyWith(
              activeTrackColor: lightScheme.primary,
              thumbColor: lightScheme.primary,
              overlayColor: lightScheme.primary.withValues(alpha: 0.12),
              valueIndicatorColor: lightScheme.primary,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: lightScheme.primary,
                foregroundColor: lightScheme.onPrimary,
              ),
            ),
          );

          final effectiveDark = AppTheme.darkTheme.copyWith(
            colorScheme: darkScheme,
            navigationBarTheme: AppTheme.darkTheme.navigationBarTheme.copyWith(
              indicatorColor: darkScheme.primary.withValues(alpha: 0.15),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return TextStyle(
                    color: darkScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  );
                }
                return TextStyle(
                  color: darkScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                );
              }),
            ),
            sliderTheme: AppTheme.darkTheme.sliderTheme.copyWith(
              activeTrackColor: darkScheme.primary,
              thumbColor: darkScheme.primary,
              overlayColor: darkScheme.primary.withValues(alpha: 0.15),
              valueIndicatorColor: darkScheme.primary,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: darkScheme.primary,
                foregroundColor: darkScheme.onPrimary,
              ),
            ),
          );

          return MaterialApp(
            title: 'Sonata',
            debugShowCheckedModeBanner: false,
            themeMode: _themeMode,
            theme: effectiveLight,
            darkTheme: effectiveDark,
            themeAnimationDuration: Duration.zero,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('zh')],
            // The cover-seeded theme has to wrap the Navigator rather than
            // `home` alone: detail routes pushed from the library are
            // siblings of `home`, so a Theme below the Navigator leaves them
            // stuck on the static scheme and they never pick up the colour
            // of the track being played.
            builder: (context, child) {
              final color = context.watch<PlayerState>().themeColor;
              if (color == null) return child ?? const SizedBox.shrink();

              // Read the brightness without Theme.of: the builder context may
              // sit above the static theme depending on MaterialApp's
              // internals, which would silently report light in dark mode.
              final brightness = switch (_themeMode) {
                ThemeMode.system =>
                  WidgetsBinding.instance.platformDispatcher.platformBrightness,
                ThemeMode.dark => Brightness.dark,
                ThemeMode.light => Brightness.light,
              };

              final seedScheme = ColorScheme.fromSeed(
                seedColor: color,
                brightness: brightness,
              );

              final themed =
                  (brightness == Brightness.light
                          ? AppTheme.lightTheme
                          : AppTheme.darkTheme)
                      .copyWith(colorScheme: seedScheme);

              return Theme(data: themed, child: child!);
            },
            home: const MainNavigation(),
          );
        },
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final List<Widget> _screens = const [
    PlayerScreen(),
    LibraryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    final tabIndex = context.read<ValueNotifier<int>>();

    return ValueListenableBuilder<int>(
      valueListenable: tabIndex,
      builder: (context, index, _) {
        return Scaffold(
          // 隐藏的 tab 整棵子树退出焦点树，遥控器方向键才不会走到看不见
          // 的界面上。详见 TabFocusScope。
          body: IndexedStack(
            index: index,
            children: [
              for (int i = 0; i < _screens.length; i++)
                TabFocusScope(active: i == index, child: _screens[i]),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) => tabIndex.value = i,
            height: 70,
            backgroundColor: colorScheme.surface,
            indicatorColor: colorScheme.primary.withValues(alpha: 0.15),
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return TextStyle(
                  color: colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                );
              }
              return TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              );
            }),
            destinations: [
              NavigationDestination(
                icon: Icon(
                  Icons.music_note_outlined,
                  size: 24,
                  color: colorScheme.onSurfaceVariant,
                ),
                selectedIcon: Icon(
                  Icons.music_note,
                  size: 24,
                  color: colorScheme.primary,
                ),
                label: loc.playerTab,
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.library_music_outlined,
                  size: 24,
                  color: colorScheme.onSurfaceVariant,
                ),
                selectedIcon: Icon(
                  Icons.library_music,
                  size: 24,
                  color: colorScheme.primary,
                ),
                label: loc.libraryTab,
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.settings_outlined,
                  size: 24,
                  color: colorScheme.onSurfaceVariant,
                ),
                selectedIcon: Icon(
                  Icons.settings,
                  size: 24,
                  color: colorScheme.primary,
                ),
                label: loc.settingsTab,
              ),
            ],
          ),
        );
      },
    );
  }
}
