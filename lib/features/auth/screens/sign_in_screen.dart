import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared_controllers/app_controller.dart';
import '../../home/screens/home_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final user = await _authService.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _error = 'Email or password is incorrect.';
      });
      return;
    }
    AppController.of(context).refreshUser(user);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => HomeScreen(userId: user.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      eyebrow: 'LifePilot',
      title: 'Welcome back',
      subtitle: 'Sign in to continue your life planning.',
      form: Form(
        key: _formKey,
        child: Column(
          children: [
            AppAuthField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              validator: validateEmail,
            ),
            const SizedBox(height: 12),
            AppAuthField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline,
              obscureText: !_showPassword,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                tooltip: _showPassword ? 'Hide password' : 'Show password',
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Password is required'
                  : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const ForgotPasswordScreen(),
                  ),
                ),
                child: const Text('Forgot password?'),
              ),
            ),
            if (_error != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 8),
            AuthActionButton(
              label: 'Log in',
              loading: _isLoading,
              onPressed: _isLoading ? null : _login,
            ),
            const SizedBox(height: 12),
            AuthFooterLink(
              leading: 'New to LifePilot?',
              action: 'Create an account',
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final user = await _auth.register(
      name: _name.text,
      email: _email.text,
      password: _password.text,
    );
    if (!mounted) return;
    AppController.of(context).refreshUser(user);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => HomeScreen(userId: user.id)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'Start planning smarter, today.',
      form: Form(
        key: _formKey,
        child: Column(
          children: [
            AppAuthField(
              controller: _name,
              label: 'Full name',
              icon: Icons.person_outline,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Name is required'
                  : null,
            ),
            const SizedBox(height: 12),
            AppAuthField(
              controller: _email,
              label: 'Email address',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              validator: validateEmail,
            ),
            const SizedBox(height: 12),
            AppAuthField(
              controller: _password,
              label: 'Create password',
              icon: Icons.lock_outline,
              obscureText: !_showPassword,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                tooltip: _showPassword ? 'Hide password' : 'Show password',
              ),
              validator: validatePassword,
            ),
            const SizedBox(height: 12),
            AppAuthField(
              controller: _confirm,
              label: 'Confirm password',
              icon: Icons.verified_user_outlined,
              obscureText: true,
              validator: (value) =>
                  value != _password.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 12),
            Text(
              "By continuing you agree to LifePilot's Terms & Privacy Policy.",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            AuthActionButton(
              label: 'Create account',
              loading: _loading,
              onPressed: _loading ? null : _register,
            ),
            const SizedBox(height: 16),
            const AuthDivider(),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.g_mobiledata, size: 22),
              label: const Text('Continue with Google'),
            ),
            const SizedBox(height: 12),
            AuthFooterLink(
              leading: 'Already have an account?',
              action: 'Log in',
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBackButton: true,
      title: 'Reset your password',
      subtitle:
          "Enter the email linked to your account - we'll send a 6-digit code to reset it.",
      form: Column(
        children: [
          AppAuthField(
            controller: _email,
            label: 'Email address',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          AuthActionButton(
            label: 'Send reset code',
            onPressed: () => setState(
              () => _message = validateEmail(_email.text) == null
                  ? 'Check your inbox for the reset code.'
                  : 'Enter a valid email address.',
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.form,
    this.eyebrow,
    this.showBackButton = false,
    super.key,
  });

  final String? eyebrow;
  final String title;
  final String subtitle;
  final Widget form;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showBackButton)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Back',
                      ),
                    ),
                  const Center(child: _BrandMark()),
                  const SizedBox(height: 12),
                  if (eyebrow != null)
                    Text(
                      eyebrow!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  form,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.primaryTint,
      borderRadius: BorderRadius.circular(18),
    ),
    child: const SizedBox(
      width: 60,
      height: 60,
      child: Icon(Icons.auto_awesome, color: AppColors.primary, size: 28),
    ),
  );
}

class AppAuthField extends StatelessWidget {
  const AppAuthField({
    required this.controller,
    required this.label,
    this.icon,
    this.suffixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: obscureText,
    keyboardType: keyboardType,
    validator: validator,
    decoration: InputDecoration(
      hintText: label,
      prefixIcon: icon == null ? null : Icon(icon),
      suffixIcon: suffixIcon,
    ),
  );
}

class AuthActionButton extends StatelessWidget {
  const AuthActionButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: onPressed,
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label),
    ),
  );
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          'or continue with',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      const Expanded(child: Divider()),
    ],
  );
}

class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    required this.leading,
    required this.action,
    required this.onPressed,
    super.key,
  });

  final String leading;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(leading, style: Theme.of(context).textTheme.bodySmall),
      TextButton(onPressed: onPressed, child: Text(action)),
    ],
  );
}

String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) return 'Email is required';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
    return 'Enter a valid email address';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Password is required';
  if (value.length < 8) return 'Use at least 8 characters';
  return null;
}
