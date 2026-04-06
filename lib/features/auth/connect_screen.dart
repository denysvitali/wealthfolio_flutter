import 'package:flutter/material.dart';
import 'package:wealthfolio_flutter/core/services/app_controller.dart';
import 'package:wealthfolio_flutter/ui/app_colors.dart';
import 'package:wealthfolio_flutter/ui/design_tokens.dart';
import 'package:wealthfolio_flutter/ui/shared_widgets.dart';

// ---------------------------------------------------------------------------
// ConnectScreen — server connection + optional login form.
// ---------------------------------------------------------------------------

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill the server URL from the last session if available.
    final lastUrl = widget.controller.session?.serverUrl;
    if (lastUrl != null && lastUrl.isNotEmpty) {
      _serverUrlController.text = lastUrl;
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  Future<void> _onConnect() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();

    await widget.controller.signIn(
      serverUrl: _serverUrlController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final busy = widget.controller.busy;
        final error = widget.controller.errorMessage;
        final theme = Theme.of(context);
        final cs = theme.colorScheme;

        return Scaffold(
          backgroundColor: cs.surface,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.huge,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(cs),
                      const SizedBox(height: AppSpacing.xxxl),
                      _buildCard(busy, error, cs, theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Header: icon + app name
  // -------------------------------------------------------------------------

  Widget _buildHeader(ColorScheme cs) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.cyanLight.withValues(alpha: 0.15),
            borderRadius: AppRadius.lg,
          ),
          child: Icon(
            Icons.account_balance_wallet_rounded,
            size: AppIconSize.xxl,
            color: AppColors.cyanLight,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Wealthfolio',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Connect to your Wealthfolio server',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: AppColors.mutedText(Theme.of(context))),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Form card
  // -------------------------------------------------------------------------

  Widget _buildCard(bool busy, String? error, ColorScheme cs, ThemeData theme) {
    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Server URL field -------------------------------------------
            _FieldLabel(label: 'Server URL'),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _serverUrlController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              enabled: !busy,
              decoration: const InputDecoration(
                hintText: 'https://wealthfolio.example.com',
                prefixIcon: Icon(Icons.dns_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a server URL.';
                }
                final trimmed = value.trim();
                if (!trimmed.startsWith('http://') &&
                    !trimmed.startsWith('https://')) {
                  return 'URL must start with http:// or https://';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // --- Username field ---------------------------------------------
            _FieldLabel(label: 'Username'),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _usernameController,
              keyboardType: TextInputType.text,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              enabled: !busy,
              decoration: const InputDecoration(
                hintText: 'admin',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // --- Password field ---------------------------------------------
            _FieldLabel(label: 'Password'),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _passwordController,
              keyboardType: TextInputType.visiblePassword,
              obscureText: !_passwordVisible,
              textInputAction: TextInputAction.done,
              enabled: !busy,
              onFieldSubmitted: (_) => _onConnect(),
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility_off : Icons.visibility,
                    size: AppIconSize.md,
                  ),
                  onPressed: () =>
                      setState(() => _passwordVisible = !_passwordVisible),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // --- Error message ----------------------------------------------
            if (error != null) ...[
              _ErrorBanner(message: error),
              const SizedBox(height: AppSpacing.xl),
            ],

            // --- Connect button ---------------------------------------------
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: busy ? null : _onConnect,
                child: busy
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                    : const Text('Connect'),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // --- Footer note -----------------------------------------------
            Text(
              'Leave username and password empty for servers\nthat do not require authentication.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.tertiaryText(Theme.of(context)),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small form-field label
// ---------------------------------------------------------------------------

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.mutedText(Theme.of(context)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Inline error banner
// ---------------------------------------------------------------------------

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.redLight.withValues(alpha: 0.15),
        borderRadius: AppRadius.sm,
        border: Border.all(
          color: AppColors.redLight.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: AppIconSize.md, color: AppColors.redLight),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.redLight,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
