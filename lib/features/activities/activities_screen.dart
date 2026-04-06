import 'package:flutter/material.dart';
import 'package:wealthfolio_flutter/core/services/app_controller.dart';

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Activities')));
  }
}
