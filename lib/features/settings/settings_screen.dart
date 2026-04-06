import 'package:flutter/material.dart';
import 'package:wealthfolio_flutter/core/services/app_controller.dart';
import 'package:wealthfolio_flutter/core/services/theme_controller.dart';
import 'package:wealthfolio_flutter/core/utils/currency_format.dart';
import 'package:wealthfolio_flutter/ui/app_colors.dart';
import 'package:wealthfolio_flutter/ui/design_tokens.dart';
import 'package:wealthfolio_flutter/ui/shared_widgets.dart';

// ---------------------------------------------------------------------------
// Common currency options
// ---------------------------------------------------------------------------

const List<String> _kCurrencies = <String>[
  'USD',
  'EUR',
  'GBP',
  'CHF',
  'JPY',
  'CAD',
  'AUD',
  'NZD',
  'SEK',
  'NOK',
  'DKK',
  'HKD',
  'SGD',
  'CNY',
  'INR',
  'BRL',
  'MXN',
];

// ---------------------------------------------------------------------------
// SettingsScreen
// ---------------------------------------------------------------------------

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.controller,
    required this.themeController,
  });

  final AppController controller;
  final ThemeController themeController;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _refreshing = false;

  Future<void> _refreshPortfolio() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await Future.wait<void>([
        widget.controller.refreshAccounts(showSpinner: false),
        widget.controller.refreshHoldings(showSpinner: false),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Portfolio refreshed successfully.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Refresh failed: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect'),
        content: const Text(
          'You will be signed out of Wealthfolio. All local data will be cleared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.controller.signOut();
    }
  }

  Future<void> _changeCurrency(BuildContext context) async {
    final current = widget.controller.baseCurrency;
    // Capture messenger before any async gap.
    final messenger = ScaffoldMessenger.of(context);
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CurrencyPickerSheet(current: current),
    );

    if (selected != null && selected != current) {
      try {
        await widget.controller.updateSettings({'base_currency': selected});
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Base currency changed to $selected.'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } on Exception {
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Failed to update currency. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          widget.controller,
          widget.themeController,
        ]),
        builder: (context, _) {
          return ListView(
            padding: kPagePadding,
            children: [
              // ── Connection ────────────────────────────────────────────────
              _SettingsSectionHeader(label: 'Connection'),
              const SizedBox(height: AppSpacing.md),
              _ConnectionSection(
                controller: widget.controller,
                onSignOut: _signOut,
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── Appearance ────────────────────────────────────────────────
              _SettingsSectionHeader(label: 'Appearance'),
              const SizedBox(height: AppSpacing.md),
              _AppearanceSection(themeController: widget.themeController),

              const SizedBox(height: AppSpacing.xxl),

              // ── General ───────────────────────────────────────────────────
              _SettingsSectionHeader(label: 'General'),
              const SizedBox(height: AppSpacing.md),
              _GeneralSection(
                controller: widget.controller,
                onChangeCurrency: () => _changeCurrency(context),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── Data ──────────────────────────────────────────────────────
              _SettingsSectionHeader(label: 'Data'),
              const SizedBox(height: AppSpacing.md),
              _DataSection(
                refreshing: _refreshing,
                onRefresh: _refreshPortfolio,
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── About ─────────────────────────────────────────────────────
              _SettingsSectionHeader(label: 'About'),
              const SizedBox(height: AppSpacing.md),
              const _AboutSection(),

              const SizedBox(height: AppSpacing.huge),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header label
// ---------------------------------------------------------------------------

class _SettingsSectionHeader extends StatelessWidget {
  const _SettingsSectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.mutedText(theme),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Connection section
// ---------------------------------------------------------------------------

class _ConnectionSection extends StatelessWidget {
  const _ConnectionSection({
    required this.controller,
    required this.onSignOut,
  });

  final AppController controller;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final session = controller.session;
    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.dns_outlined,
            iconColor: AppColors.blueLight,
            title: 'Server URL',
            trailing: Text(
              session?.serverUrl ?? '—',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.mutedText(Theme.of(context)),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.person_outline,
            iconColor: AppColors.cyanLight,
            title: 'Username',
            trailing: Text(
              session?.username ?? '—',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.mutedText(Theme.of(context)),
              ),
            ),
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.logout_outlined,
            iconColor: AppColors.error,
            title: 'Disconnect',
            onTap: onSignOut,
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: AppIconSize.xs,
              color: AppColors.error,
            ),
            titleColor: AppColors.error,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Appearance section
// ---------------------------------------------------------------------------

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection({required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = themeController.themeMode;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBubble(
                icon: Icons.palette_outlined,
                color: AppColors.purpleLight,
              ),
              const SizedBox(width: AppSpacing.lg),
              Text(
                'Theme',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SegmentedButton<ThemeMode>(
            style: SegmentedButton.styleFrom(
              backgroundColor: AppColors.inputFill(theme),
              selectedBackgroundColor: theme.colorScheme.primary,
              selectedForegroundColor: theme.colorScheme.onPrimary,
              foregroundColor: AppColors.mutedText(theme),
              side: BorderSide(color: AppColors.outline(theme)),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.base,
              ),
              textStyle: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_outlined, size: AppIconSize.sm),
                label: Text('System'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined, size: AppIconSize.sm),
                label: Text('Light'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined, size: AppIconSize.sm),
                label: Text('Dark'),
              ),
            ],
            selected: {current},
            onSelectionChanged: (modes) {
              if (modes.isNotEmpty) {
                themeController.setThemeMode(modes.first);
              }
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// General section
// ---------------------------------------------------------------------------

class _GeneralSection extends StatelessWidget {
  const _GeneralSection({
    required this.controller,
    required this.onChangeCurrency,
  });

  final AppController controller;
  final VoidCallback onChangeCurrency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      padding: EdgeInsets.zero,
      child: _SettingsTile(
        icon: Icons.currency_exchange_outlined,
        iconColor: AppColors.yellowLight,
        title: 'Base Currency',
        onTap: onChangeCurrency,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              controller.baseCurrency,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.mutedText(theme),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.arrow_forward_ios,
              size: AppIconSize.xs,
              color: AppColors.tertiaryText(theme),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data section
// ---------------------------------------------------------------------------

class _DataSection extends StatelessWidget {
  const _DataSection({
    required this.refreshing,
    required this.onRefresh,
  });

  final bool refreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: EdgeInsets.zero,
      child: _SettingsTile(
        icon: Icons.sync_outlined,
        iconColor: AppColors.greenLight,
        title: 'Refresh Portfolio',
        subtitle: 'Reload accounts and holdings from the server',
        onTap: refreshing ? null : onRefresh,
        trailing: refreshing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.arrow_forward_ios,
                size: AppIconSize.xs,
                color: AppColors.tertiaryText(Theme.of(context)),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// About section
// ---------------------------------------------------------------------------

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.monetization_on_outlined,
            iconColor: AppColors.orangeLight,
            title: 'Wealthfolio Flutter',
            trailing: Text(
              'v1.0.0',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.mutedText(theme),
              ),
            ),
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.code_outlined,
            iconColor: AppColors.tx2,
            title: 'Source Code',
            trailing: Text(
              'github.com/afadil/wealthfolio',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.mutedText(theme),
              ),
            ),
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.info_outline,
            iconColor: AppColors.blueLight,
            title: 'Built with Flutter',
            trailing: Text(
              'Flexoki design',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.mutedText(theme),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Currency picker bottom sheet
// ---------------------------------------------------------------------------

class _CurrencyPickerSheet extends StatelessWidget {
  const _CurrencyPickerSheet({required this.current});

  final String current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.85,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline(theme),
                borderRadius: AppRadius.pill,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Row(
                children: [
                  Text(
                    'Select Currency',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(height: 1),
            // Currency list
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: _kCurrencies.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final code = _kCurrencies[index];
                  final isSelected = code == current;
                  return ListTile(
                    leading: _CurrencyAvatar(code: code),
                    title: Text(
                      code,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? cs.primary : cs.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      _currencyName(code),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedText(theme),
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: cs.primary,
                            size: AppIconSize.md,
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(code),
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        );
      },
    );
  }

  String _currencyName(String code) {
    return switch (code) {
      'USD' => 'US Dollar',
      'EUR' => 'Euro',
      'GBP' => 'British Pound',
      'CHF' => 'Swiss Franc',
      'JPY' => 'Japanese Yen',
      'CAD' => 'Canadian Dollar',
      'AUD' => 'Australian Dollar',
      'NZD' => 'New Zealand Dollar',
      'SEK' => 'Swedish Krona',
      'NOK' => 'Norwegian Krone',
      'DKK' => 'Danish Krone',
      'HKD' => 'Hong Kong Dollar',
      'SGD' => 'Singapore Dollar',
      'CNY' => 'Chinese Yuan',
      'INR' => 'Indian Rupee',
      'BRL' => 'Brazilian Real',
      'MXN' => 'Mexican Peso',
      _ => code,
    };
  }
}

class _CurrencyAvatar extends StatelessWidget {
  const _CurrencyAvatar({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use formatCurrency to get the symbol
    final symbol = formatCurrency(0, currency: code)
        .replaceAll(RegExp(r'[\d.,\s]'), '')
        .trim();
    final displaySymbol =
        symbol.isEmpty ? code.substring(0, 1) : symbol.length > 3
            ? symbol.substring(0, 1)
            : symbol;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.inputFill(theme),
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.outline(theme)),
      ),
      child: Center(
        child: Text(
          displaySymbol,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable settings tile
// ---------------------------------------------------------------------------

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.base,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            _IconBubble(icon: icon, color: iconColor),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? theme.colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedText(theme),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.lg),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Icon bubble
// ---------------------------------------------------------------------------

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.sm,
      ),
      child: Icon(icon, size: AppIconSize.md, color: color),
    );
  }
}
