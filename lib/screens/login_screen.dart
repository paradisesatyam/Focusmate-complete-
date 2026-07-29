import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_text_field.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _auth = AuthService();
  bool _loading = false, _hide = true;
  String? _error;

  @override
  void dispose() { _email.dispose(); _pass.dispose(); super.dispose(); }

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await _auth.login(email: _email.text, password: _pass.text);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _auth.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 24),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 36)),
          const SizedBox(height: 28),
          const Text('Welcome back 👋', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('Log in to continue your focus journey.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 36),

          AuthTextField(label: 'Email', hint: 'you@example.com', icon: Icons.mail_outline_rounded, controller: _email, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 20),
          AuthTextField(label: 'Password', hint: 'Your password', icon: Icons.lock_outline_rounded, controller: _pass, obscureText: _hide,
            suffix: IconButton(icon: Icon(_hide ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary, size: 20), onPressed: () => setState(() => _hide = !_hide))),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.danger.withOpacity(0.3))),
              child: Row(children: [const Icon(Icons.error_outline, color: AppColors.danger, size: 16), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)))])),
          ],

          const SizedBox(height: 28),
          SizedBox(width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: _loading ? null : _login,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Text('Log In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            )),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text("Don't have an account? ", style: TextStyle(color: AppColors.textSecondary)),
            GestureDetector(onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignupScreen())), child: const Text('Sign Up', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
          ]),
        ]),
      )),
    );
  }
}
