// App 启动流程的冒烟测试。
//
// 只 pump 一帧的话 `_isInitialized` 还是 false，走不到 Provider 树，所以这里
// 要等异步初始化完成后多 pump 几帧，让真正的 MultiProvider 建起来。
//
// flutter_secure_storage 在 Linux 上走真实 D-Bus，FakeAsync 里永远跑不完，
// 必须放到 tester.runAsync() 里让真实事件循环推进。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sonata/app.dart';

/// 等 App 完成异步初始化并切出加载页。
Future<void> _waitForInitialized(WidgetTester tester) async {
  for (
    int i = 0;
    i < 30 && find.byType(MainNavigation).evaluate().isEmpty;
    i++
  ) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
  }
  for (int i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SonataApp());

    // Verify that the app loads
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('初始化完成后 Provider 树能正常构建', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const SonataApp());
    await _waitForInitialized(tester);

    expect(
      find.byType(MainNavigation),
      findsOneWidget,
      reason: 'App 应该已经走出加载页',
    );
    expect(
      tester.takeException(),
      isNull,
      reason:
          'Provider 不接受 Listenable 子类（ValueNotifier），'
          '会在这里直接抛异常把整棵树打断，界面只剩红屏',
    );
  });
}
