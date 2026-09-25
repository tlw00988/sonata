import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sonata/l10n/app_localizations.dart';
import 'package:sonata/player/player.dart';
import 'package:sonata/widgets/fused_control_dock.dart';
import 'package:sonata/widgets/tab_focus_scope.dart';

/// 主界面用 IndexedStack 同时挂载三个页面，隐藏页如果还留在焦点树里，
/// 遥控器的方向键就会走进看不见的界面。
void main() {
  group('TabFocusScope', () {
    testWidgets('方向键只在当前 tab 内移动，切 tab 后另一侧恢复可聚焦', (tester) async {
      final a1 = FocusNode(debugLabel: 'a1');
      final a2 = FocusNode(debugLabel: 'a2');
      final b1 = FocusNode(debugLabel: 'b1');
      addTearDown(a1.dispose);
      addTearDown(a2.dispose);
      addTearDown(b1.dispose);

      Widget build(int index) => MaterialApp(
        home: Scaffold(
          body: IndexedStack(
            index: index,
            children: [
              TabFocusScope(
                active: index == 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton(
                      focusNode: a1,
                      onPressed: () {},
                      child: const Text('A1'),
                    ),
                    TextButton(
                      focusNode: a2,
                      onPressed: () {},
                      child: const Text('A2'),
                    ),
                  ],
                ),
              ),
              TabFocusScope(
                active: index == 1,
                // 故意放到 A2 下面，这样 ↓ 本来是可以走到它的。
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 120),
                    TextButton(
                      focusNode: b1,
                      onPressed: () {},
                      child: const Text('B1'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pumpWidget(build(0));

      expect(b1.canRequestFocus, isFalse, reason: '隐藏 tab 的整棵子树应当退出焦点树');

      a1.requestFocus();
      await tester.pump();
      expect(a1.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(a2.hasPrimaryFocus, isTrue, reason: '当前 tab 内部的方向键导航必须照常工作');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(b1.hasPrimaryFocus, isFalse, reason: '方向键不能穿到被隐藏的 tab 上');

      // 切到第二个 tab，隐藏焦点树的一侧要恢复。
      await tester.pumpWidget(build(1));
      await tester.pump();
      expect(b1.canRequestFocus, isTrue);

      b1.requestFocus();
      await tester.pump();
      expect(b1.hasPrimaryFocus, isTrue);
    });
  });

  group('播放页底部控件', () {
    late PlayerState state;
    late int previousCount;
    late int nextCount;
    late int playPauseCount;
    late double? seekProgress;
    late int seekCount;

    Future<void> pumpDock(
      WidgetTester tester, {
      Duration duration = const Duration(seconds: 180),
    }) async {
      // 目标设备是 Android TV 盒子/电视，按真实桌面尺寸来测。
      // （800px 宽时 dock 右侧会溢出，那是改动前就存在的老问题，与焦点无关。）
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      state = PlayerState()
        ..setPosition(const Duration(seconds: 30))
        ..setDuration(duration)
        ..setPlaybackState(PlaybackState.stopped);
      previousCount = 0;
      nextCount = 0;
      playPauseCount = 0;
      seekProgress = null;
      seekCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Column(
              children: [
                FusedControlDock(
                  playerState: state,
                  onPlayPause: () => playPauseCount++,
                  onPrevious: () => previousCount++,
                  onNext: () => nextCount++,
                  onVolumeChanged: (_) {},
                  onSeek: (progress) {
                    seekCount++;
                    seekProgress = progress;
                  },
                  onFavoriteToggle: () {},
                  onPlaylistToggle: () {},
                  onToggleTranslations: () {},
                ),
              ],
            ),
          ),
        ),
      );
    }

    /// 取 dock 里某个图标对应控件的焦点节点：InkWell 在自己的内容外面
    /// 包了一层 Focus，图标元素向上找到的就是它。
    FocusNode nodeOf(WidgetTester tester, IconData icon) => Focus.of(
      tester.element(
        find.descendant(
          of: find.byType(FusedControlDock),
          matching: find.byIcon(icon),
        ),
      ),
    );

    testWidgets('方向键能在控件之间移动，回车激活当前焦点', (tester) async {
      await pumpDock(tester);

      final shuffle = nodeOf(tester, Icons.shuffle);
      final previous = nodeOf(tester, Icons.skip_previous_rounded);
      final play = nodeOf(tester, Icons.play_arrow_rounded);

      shuffle.requestFocus();
      await tester.pump();
      expect(shuffle.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(previous.hasPrimaryFocus, isTrue, reason: '方向键应当把焦点移到右边相邻的控件');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(previousCount, 1, reason: '回车应当触发当前焦点控件的 onTap');

      play.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(playPauseCount, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(nextCount, 0, reason: '方向键只移动焦点，不能顺带触发动作');
      expect(
        nodeOf(tester, Icons.skip_next_rounded).hasPrimaryFocus,
        isTrue,
        reason: '播放键右边是下一曲',
      );
    });

    testWidgets('时间显示是进度条：左右键快进快退，上下键只移焦点', (tester) async {
      await pumpDock(tester);

      final readout = Focus.of(tester.element(find.text('00:30/03:00')));
      readout.requestFocus();
      await tester.pump();
      expect(readout.hasPrimaryFocus, isTrue);

      // 30s + 5s，总长 180s。
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(seekCount, 1);
      expect(seekProgress, closeTo(35 / 180, 1e-9));
      expect(
        readout.hasPrimaryFocus,
        isTrue,
        reason: '快进之后焦点必须留在进度条上，不能被方向键带跑',
      );

      // 30s - 5s。
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(seekCount, 2);
      expect(seekProgress, closeTo(25 / 180, 1e-9));
      expect(readout.hasPrimaryFocus, isTrue);

      // 上下键不 seek，交给框架做焦点移动。
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(seekCount, 2, reason: '上下键不应当触发快进快退');
    });

    testWidgets('没有总时长时左右键不 seek，也不把焦点放跑', (tester) async {
      await pumpDock(tester, duration: Duration.zero);

      final readout = Focus.of(tester.element(find.text('00:30/00:00')));
      readout.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(seekCount, 0);
      expect(readout.hasPrimaryFocus, isTrue);
    });
  });
}
