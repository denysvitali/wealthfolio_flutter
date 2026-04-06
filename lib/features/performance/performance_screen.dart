import 'package:flutter/material.dart';
import 'package:wealthfolio_flutter/core/services/app_controller.dart';

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Performance')));
  }
}
