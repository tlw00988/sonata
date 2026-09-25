import 'package:flutter/material.dart';

/// 主界面一个 tab 的内容外壳。
///
/// `IndexedStack` 会把所有页面**同时**挂进焦点树，隐藏页的按钮并不是不可
/// 聚焦的。遥控器的方向键按几何位置找下一个焦点，就会走进看不见的 tab，
/// 焦点看起来"丢了"（按哪都没反应）。
///
/// 这里在切换 tab 时把非选中页的整棵子树退出焦点树：被关闭的一侧子节点
/// 的 `canRequestFocus` 变成 false，焦点遍历会直接跳过整棵子树；同时它
/// 自己也 `canRequestFocus: false`，不会成为方向键的目标。
///
/// 只影响焦点，不改变布局、绘制或触摸事件。
class TabFocusScope extends StatelessWidget {
  const TabFocusScope({super.key, required this.active, required this.child});

  /// 是否为当前选中的 tab。
  final bool active;

  final Widget child;

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    descendantsAreFocusable: active,
    descendantsAreTraversable: active,
    child: child,
  );
}
