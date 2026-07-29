import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_text_field.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  final _auth = AuthService();
  bool _loading = false, _h1 = true, _h2 = true;
  String? _error;

  @override
  void dispose() { _name.dispose(); _email.dispose(); _pass.dispose(); _confirm.dispose(); super.dispose(); }

  Future<void> _signup() async {
    if (_name.text.trim().isEmpty) { setState(() => _error = 'Please enter your name.'); return; }
    if (_pass.text != _confirm.text) { setState(() => _error = 'Passwords do not match.'); return; }
    if (_pass.text.length < 6) { setState(() => _error = 'Password must be at least 6 characters.'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      await _auth.signUp(name: _name.text, email: _email.text, password: _pass.text);
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
          const Text('Create account ✨', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('Start your productivity journey today.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 36),

          AuthTextField(label: 'Your Name', hint: 'e.g. Rahul Sharma', icon: Icons.person_outline_rounded, controller: _name),
          const SizedBox(height: 20),
          AuthTextField(label: 'Email', hint: 'you@example.com', icon: Icons.mail_outline_rounded, controller: _email, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 20),
          AuthTextField(label: 'Password', hint: 'At least 6 characters', icon: Icons.lock_outline_rounded, controller: _pass, obscureText: _h1, suffix: IconButton(icon: Icon(_h1 ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppColors.textSecondary), onPressed: () => setState(() => _h1 = !_h1))),
          const SizedBox(height: 20),
          AuthTextField(label: 'Confirm Password', hint: 'Re-enter password', icon: Icons.lock_outline_rounded, controller: _confirm, obscureText: _h2, suffix: IconButton(icon: Icon(_h2 ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppColors.textSecondary), onPressed: () => setState(() => _h2 = !_h2))),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.danger.withOpacity(0.3))),
              child: Row(children: [const Icon(Icons.error_outline, color: AppColors.danger, size: 16), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)))])),
          ],

          const SizedBox(height: 28),
          SizedBox(width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: _loading ? null : _signup,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            )),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Already have an account? ', style: TextStyle(color: AppColors.textSecondary)),
            GestureDetector(onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())), child: const Text('Log In', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
          ]),
        ]),
      )),
    );
  }
}
