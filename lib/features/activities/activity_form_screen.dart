import 'package:flutter/material.dart';
import 'package:wealthfolio_flutter/core/models/activity.dart';
import 'package:wealthfolio_flutter/core/services/app_controller.dart';
import 'package:wealthfolio_flutter/ui/app_colors.dart';
import 'package:wealthfolio_flutter/ui/design_tokens.dart';

/// Placeholder screen for creating or editing an Activity.
/// Returns `true` via [Navigator.pop] when the form is submitted successfully.
class ActivityFormScreen extends StatelessWidget {
  const ActivityFormScreen({
    super.key,
    required this.controller,
    this.activity,
  });

  final AppController controller;

  /// When non-null, the form is in edit mode for this activity.
  final Activity? activity;

  bool get _isEditing => activity != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Activity' : 'Add Activity'),
        leading: CloseButton(
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction_outlined,
                size: AppIconSize.huge,
                color: AppColors.tertiaryText(theme),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Activity form coming soon',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _isEditing
                    ? 'Editing activity ${activity!.id}'
                    : 'Create a new activity to track your portfolio.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedText(theme),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.huge),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
