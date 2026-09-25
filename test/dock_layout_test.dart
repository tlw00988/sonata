import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sonata/l10n/app_localizations.dart';
import 'package:sonata/player/player.dart';
import 'package:sonata/widgets/fused_control_dock.dart';

/// 覆盖紧凑/窄窗口/常规/TV 各档宽度，含两个断点两侧的临界值。
const List<int> _widths = <int>[
  360,
  390,
  430,
  499,
  500,
  520,
  559,
  560,
  600,
  640,
  700,
  739,
  740,
  768,
  800,
  960,
  1280,
  1920,
];

Widget _buildDock() {
  return FusedControlDock(
    playerState: PlayerState()
      ..setPosition(const Duration(seconds: 30))
      ..setDuration(const Duration(seconds: 180)),
    onPlayPause: () {},
    onPrevious: () {},
    onNext: () {},
    onVolumeChanged: (_) {},
    onSeek: (_) {},
    onFavoriteToggle: () {},
    onPlaylistToggle: () {},
    onToggleTranslations: () {},
  );
}

Future<void> _pumpAt(WidgetTester tester, int width) async {
  addTearDown(tester.view.reset);
  tester.view.physicalSize = Size(width.toDouble(), 720);
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Column(children: [_buildDock()])),
    ),
  );
}

/// 右侧"队列"按钮的右边缘距离 dock 右边缘的距离。
double _queueGap(WidgetTester tester) {
  final RenderBox dock = tester.renderObject<RenderBox>(
    find.byType(FusedControlDock),
  );
  final RenderBox queue = tester.renderObject<RenderBox>(
    find.descendant(
      of: find.byType(FusedControlDock),
      matching: find.byIcon(Icons.queue_music_rounded),
    ),
  );
  final double dockRight = dock.localToGlobal(Offset(dock.size.width, 0)).dx;
  final double queueRight = queue.localToGlobal(Offset(queue.size.width, 0)).dx;
  return dockRight - queueRight;
}

Finder get _pillBadge => find.descendant(
  of: find.byType(FusedControlDock),
  matching: find.byIcon(Icons.music_note),
);

void main() {
  testWidgets('任意宽度都不溢出，且右侧控件始终贴住右边缘', (tester) async {
    for (final int width in _widths) {
      await _pumpAt(tester, width);
      expect(
        tester.takeException(),
        isNull,
        reason: '宽度 $width 时不应出现 RenderFlex 溢出',
      );

      // 内外水平留白：紧凑 12+12，常规 24+16。
      final double expectedGap = width < 500 ? 24.0 : 40.0;
      expect(
        _queueGap(tester),
        closeTo(expectedGap, 0.5),
        reason: '宽度 $width 时队列按钮应贴住右侧留白，不能留下空档',
      );
    }
    tester.view.reset();
  });

  testWidgets('空间不足时先隐藏药丸徽章', (tester) async {
    await _pumpAt(tester, 800);
    expect(_pillBadge, findsOneWidget, reason: '800 宽应显示徽章');

    await _pumpAt(tester, 739);
    expect(_pillBadge, findsNothing, reason: '739 宽放不下徽章，应隐藏');

    await _pumpAt(tester, 740);
    expect(_pillBadge, findsOneWidget, reason: '740 宽恢复显示徽章');
    expect(tester.takeException(), isNull);

    tester.view.reset();
  });

  testWidgets('窄窗口下改用弹出式音量开关，不再放内联滑条', (tester) async {
    await _pumpAt(tester, 800);
    expect(find.byType(Slider), findsOneWidget, reason: '800 宽有内联音量滑条');

    await _pumpAt(tester, 559);
    expect(find.byType(Slider), findsNothing, reason: '559 宽滑条让位给弹出开关');

    await _pumpAt(tester, 560);
    expect(find.byType(Slider), findsOneWidget, reason: '560 宽恢复内联滑条');

    await _pumpAt(tester, 499);
    expect(find.byType(Slider), findsNothing, reason: '紧凑布局用弹出开关');

    expect(tester.takeException(), isNull);
    tester.view.reset();
  });
}
