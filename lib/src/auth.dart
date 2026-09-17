import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'art.dart';
import 'store.dart';
import 'theme.dart';

Future<void> showAuth(
  BuildContext context,
  ShopStore store, {
  bool signup = false,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: AppColors.lavender,
  constraints: const BoxConstraints(maxWidth: 520),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
  ),
  builder: (_) => AuthSheet(store: store, signup: signup),
);

class AuthSheet extends StatefulWidget {
  const AuthSheet({super.key, required this.store, required this.signup});
  final ShopStore store;
  final bool signup;
  @override
  State<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<AuthSheet> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  late bool signup = widget.signup;
  bool obscure = true, busy = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final client = widget.store.client;
    if (client == null) {
      setState(
        () => error = widget.store.startupError ?? 'This demo is not connected to a live store yet. Explore the app below; no account has been created.',
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final response = signup
          ? await client.auth.signUp(
              email: email.text.trim(),
              password: password.text,
              data: {
                'display_name': name.text.trim(),
                'onboarding_complete': false,
              },
            )
          : await client.auth.signInWithPassword(
              email: email.text.trim(),
              password: password.text,
            );
      // The database trigger confirms password-only accounts when the
      // dashboard's confirmation switch cannot be changed.
      if (signup && response.session == null) {
        await client.auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
      if (!mounted) return;
      if (client.auth.currentSession != null) {
        if (widget.store.needsOnboarding) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          Navigator.of(context).pop();
        }
      } else {
        setState(
          () => error =
              'We could not sign you in. Please try again.',
        );
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              error = 'Something interrupted the connection. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        28,
        12,
        28,
        MediaQuery.viewInsetsOf(context).bottom + 28,
      ),
      child: AutofillGroup(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Brand(small: true),
                  IconButton(
                    onPressed: busy ? null : () => Navigator.pop(context),
                    tooltip: 'Close sign-in',
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                signup
                    ? 'Your good days\nstart here.'
                    : 'Hey, good\nto see you.',
                style: headline(36),
              ),
              const SizedBox(height: 12),
              Text(
                signup
                    ? 'Make room for fresh finds and everyday favourites.'
                    : 'Sign in. Stock up. Get on with your day.',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              if (signup) ...[
                TextFormField(
                  controller: name,
                  enabled: !busy,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(LucideIcons.user, size: 20),
                  ),
                  validator: (value) => value == null || value.trim().length < 2
                      ? 'Enter your name.'
                      : null,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: email,
                enabled: !busy,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(LucideIcons.mail, size: 20),
                ),
                validator: (value) =>
                    value == null ||
                        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                            .hasMatch(value.trim())
                    ? 'Enter a valid email address.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: password,
                enabled: !busy,
                obscureText: obscure,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: [
                  signup ? AutofillHints.newPassword : AutofillHints.password,
                ],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (!busy) submit();
                },
                decoration: InputDecoration(
                  labelText: 'Password',
                  helperText: signup ? 'Use at least 8 characters.' : null,
                  prefixIcon: const Icon(LucideIcons.lock, size: 20),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => obscure = !obscure),
                    tooltip: obscure ? 'Show password' : 'Hide password',
                    icon: Icon(
                      obscure ? LucideIcons.eye : LucideIcons.eyeOff,
                      size: 20,
                    ),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter your password.'
                    : signup && value.length < 8
                    ? 'Use at least 8 characters.'
                    : null,
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEAE7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      error!,
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF8C3028),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: busy ? null : submit,
                  child: busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(signup ? 'Create account' : 'Sign in'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: busy
                      ? null
                      : () => setState(() {
                          signup = !signup;
                          error = null;
                          form.currentState?.reset();
                        }),
                  child: Text(
                    signup
                        ? 'Already a member? Sign in'
                        : 'New around here? Create an account',
                  ),
                ),
              ),
              if (widget.store.isDemo && signup)
                Center(
                  child: TextButton(
                    onPressed: busy
                        ? null
                        : () {
                            Navigator.pop(context);
                            widget.store.previewOnboarding();
                          },
                    child: const Text('Preview new-user onboarding'),
                  ),
                ),
              if (widget.store.isDemo)
                Center(
                  child: TextButton(
                    onPressed: busy
                        ? null
                        : () {
                            Navigator.pop(context);
                            widget.store.browse();
                          },
                    child: const Text('Explore the demo catalog'),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
