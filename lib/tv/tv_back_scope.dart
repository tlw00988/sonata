import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'tv_input.dart';

/// 把"返回键"接到遥控器的模式切换上。
///
/// 为什么不放在 [TvInputController] 的键事件拦截里：真机（Android TV）上
/// 实测，返回键是走 `SystemChannels.navigation` → `Navigator.maybePop` 这
/// 条路到达的，在硬件键盘事件层吞掉键事件拦不住它——按下返回键 app 会
/// 直接退到桌面。而 [PopScope] 正好挂在这条路上，能真正否决掉这次 pop。
///
/// 优先级也刚好对：[ModalRoute.popDisposition] 只要有一个注册的
/// [PopEntry] 说不行就整体不弹，然后**逐个**通知所有
/// `onPopInvokedWithResult`。所以本 scope 和播放页自己的抽屉 scope 互不
/// 干扰——谁该拦谁拦。
class TvBackScope extends StatelessWidget {
  const TvBackScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TvInputController>();
    // 抽屉开着时轮不到控件模式说话，播放页的 PopScope 会去关抽屉。
    final blocking = controller.mode == TvMode.control && !controller.queueOpen;

    return PopScope(
      canPop: !blocking,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (controller.mode == TvMode.control && !controller.queueOpen) {
          controller.exitControlMode();
        }
      },
      child: child,
    );
  }
}
