import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cylinder_management/config/app_config.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;

  const LoadingIndicator({
    Key? key,
    this.size = 24.0,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final indicatorColor = color ?? AppConfig.primaryColor;

    return Center(
      child: SpinKitFadingCircle(
        color: indicatorColor,
        size: size,
      ),
    );
  }
}
