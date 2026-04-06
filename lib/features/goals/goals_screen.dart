import 'package:flutter/material.dart';
import 'package:wealthfolio_flutter/core/models/goal.dart';
import 'package:wealthfolio_flutter/core/services/app_controller.dart';
import 'package:wealthfolio_flutter/core/utils/currency_format.dart';
import 'package:wealthfolio_flutter/ui/app_colors.dart';
import 'package:wealthfolio_flutter/ui/design_tokens.dart';
import 'package:wealthfolio_flutter/ui/shared_widgets.dart';
import 'goal_form_screen.dart';

// ---------------------------------------------------------------------------
// GoalsScreen
// ---------------------------------------------------------------------------

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<Goal> _goals = [];
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  // -------------------------------------------------------------------------
  // Data loading
  // -------------------------------------------------------------------------

  Future<void> _loadGoals() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final goals = await widget.controller.fetchGoals();
      if (mounted) {
        setState(() {
          _goals = goals;
          _loading = false;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _loading = false;
        });
      }
    }
  }

  // -------------------------------------------------------------------------
  // Navigation
  // -------------------------------------------------------------------------

  Future<void> _openCreateForm() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => GoalFormScreen(controller: widget.controller),
        fullscreenDialog: true,
      ),
    );
    if (created == true && mounted) {
      _loadGoals();
    }
  }

  Future<void> _openEditForm(Goal goal) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => GoalFormScreen(
          controller: widget.controller,
          goal: goal,
        ),
        fullscreenDialog: true,
      ),
    );
    if (updated == true && mounted) {
      _loadGoals();
    }
  }

  // -------------------------------------------------------------------------
  // Delete
  // -------------------------------------------------------------------------

  Future<void> _confirmDelete(Goal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteGoal(goal.id);
    }
  }

  Future<void> _deleteGoal(String id) async {
    try {
      await widget.controller.deleteGoal(id);
      if (mounted) {
        setState(() {
          _goals = _goals.where((g) => g.id != id).toList();
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.xl),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateForm,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    // Error state
    if (_errorMessage != null && _goals.isEmpty) {
      return ErrorRetryWidget(
        message: _errorMessage!,
        onRetry: _loadGoals,
      );
    }

    // Loading skeleton
    if (_loading && _goals.isEmpty) {
      return const _GoalsSkeleton();
    }

    // Empty state
    if (_goals.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadGoals,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: kPagePadding,
          children: const [
            SizedBox(height: AppSpacing.xxl),
            EmptyStateCard(
              icon: Icons.flag_outlined,
              title: 'No goals yet',
              subtitle: 'Track your financial milestones by adding your first goal.',
            ),
          ],
        ),
      );
    }

    // Goal list
    return RefreshIndicator(
      onRefresh: _loadGoals,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.lg,
          bottom: 80,
        ),
        itemCount: _goals.length,
        itemBuilder: (context, index) {
          final goal = _goals[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Dismissible(
              key: ValueKey(goal.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) async {
                await _confirmDelete(goal);
                return false;
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: AppRadius.base,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
              ),
              child: _GoalCard(
                goal: goal,
                controller: widget.controller,
                onTap: () => _openEditForm(goal),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Goal card
// ---------------------------------------------------------------------------

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.controller,
    required this.onTap,
  });

  final Goal goal;
  final AppController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.base,
      child: SectionCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          goal.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (goal.isAchieved)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.green.withValues(alpha: 0.1),
                            borderRadius: AppRadius.pill,
                            border: Border.all(
                              color: AppColors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Text(
                            'Achieved',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (goal.description != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      goal.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedText(Theme.of(context)),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    formatCurrency(
                      goal.targetAmount,
                      currency: controller.baseCurrency,
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton loading state
// ---------------------------------------------------------------------------

class _GoalsSkeleton extends StatelessWidget {
  const _GoalsSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shimmer = AppColors.skeleton(theme);
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SkeletonBox(
                        width: 140,
                        height: 16,
                        color: shimmer,
                      ),
                    ),
                    _SkeletonBox(
                      width: 60,
                      height: 20,
                      color: shimmer,
                      radius: AppRadius.pill,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _SkeletonBox(
                  width: double.infinity,
                  height: 12,
                  color: shimmer,
                ),
                const SizedBox(height: AppSpacing.md),
                _SkeletonBox(
                  width: 100,
                  height: 20,
                  color: shimmer,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.color,
    this.radius,
  });

  final double width;
  final double height;
  final Color color;
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius ?? AppRadius.xs,
      ),
    );
  }
}
