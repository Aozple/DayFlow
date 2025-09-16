import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class StatusBarPadding extends StatelessWidget {
  final Color? color;
  final double? height;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  const StatusBarPadding({
    super.key,
    this.color,
    this.height,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      height: height ?? topInset,
      margin: margin,
      padding: padding,
      color: color ?? AppColors.surface.withAlpha(200),
    );
  }
}
