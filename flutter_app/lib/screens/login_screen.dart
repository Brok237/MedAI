// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../app_theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true, _submitting = false;

  @override void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final ok   = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!ok && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error!), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Form(key: _formKey, child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              Center(child: Column(children: [
                Container(width: 80, height: 80,
                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Icon(Icons.medical_services_rounded, color: AppTheme.primary, size: 44)),
                const SizedBox(height: 16),
                Text('MedAI', style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                const SizedBox(height: 6),
                Text('AI-Assisted Medical Platform',
                    style: TextStyle(color: Colors.grey[600])),
              ])),
              const SizedBox(height: 48),
              Text('Welcome back', style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Sign in to your account', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 28),
              TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _passCtrl, obscureText: _obscure,
                decoration: InputDecoration(labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure))),
                validator: (v) => v == null || v.length < 6 ? 'Password too short' : null),
              const SizedBox(height: 32),
              SizedBox(height: 52, child: ElevatedButton(
                onPressed: _submitting ? null : _login,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _submitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Sign In', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)))),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text("Don't have an account?", style: TextStyle(color: Colors.grey[600])),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: Text('Register', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600))),
              ]),
            ],
          )),
        ),
      ),
    );
  }
}
