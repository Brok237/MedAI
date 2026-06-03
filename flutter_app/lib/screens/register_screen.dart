// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _patientFormKey = GlobalKey<FormState>();
  final _doctorFormKey  = GlobalKey<FormState>();
  bool _submitting = false, _obscure = true;

  // Patient fields
  final _pName = TextEditingController();
  final _pEmail = TextEditingController();
  final _pPass  = TextEditingController();
  int?  _age; String? _gender;

  // Doctor fields
  final _dName     = TextEditingController();
  final _dEmail    = TextEditingController();
  final _dPass     = TextEditingController();
  final _dLicense  = TextEditingController();
  final _dHospital = TextEditingController();
  String? _specialization;

  final _specializations = ['general','cardiology','neurology','dermatology',
    'pediatrics','orthopedics','gastroenterology','psychiatry','endocrinology','pulmonology'];

  @override void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); }
  @override void dispose() {
    _tab.dispose();
    for (final c in [_pName,_pEmail,_pPass,_dName,_dEmail,_dPass,_dLicense,_dHospital]) c.dispose();
    super.dispose();
  }

  Future<void> _registerPatient() async {
    if (!_patientFormKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final ok   = await auth.registerPatient(name: _pName.text.trim(), email: _pEmail.text.trim(),
        password: _pPass.text, age: _age, gender: _gender);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error ?? 'Registration failed'), backgroundColor: Colors.red));
    }
    // AuthProvider notifies → _AppRouter navigates automatically
  }

  Future<void> _registerDoctor() async {
    if (!_doctorFormKey.currentState!.validate()) return;
    if (_specialization == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a specialization')));
      return;
    }
    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final ok   = await auth.registerDoctor(name: _dName.text.trim(), email: _dEmail.text.trim(),
        password: _dPass.text, specialization: _specialization!,
        licenseNumber: _dLicense.text.trim(), hospital: _dHospital.text.trim());
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      showDialog(context: context, builder: (_) => AlertDialog(
        title: const Text('Registration Submitted'),
        content: const Text('Your doctor account is pending admin approval. You will receive an email once approved.'),
        actions: [TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('OK'))],
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error ?? 'Registration failed'), backgroundColor: Colors.red));
    }
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {
    bool obscure = false, TextInputType type = TextInputType.text,
    String? Function(String?)? validator}) =>
    Padding(padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(controller: ctrl, obscureText: obscure, keyboardType: type,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        validator: validator ?? (v) => v == null || v.isEmpty ? 'Required' : null));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account'), backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
        bottom: TabBar(controller: _tab, labelColor: Colors.white, unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: 'Patient'), Tab(text: 'Doctor')])),
      body: TabBarView(controller: _tab, children: [
        // ── Patient tab ──────────────────────────────────────────────────
        SingleChildScrollView(padding: const EdgeInsets.all(24),
          child: Form(key: _patientFormKey, child: Column(children: [
            _field(_pName,  'Full Name',     Icons.person_outlined),
            _field(_pEmail, 'Email',         Icons.email_outlined,   type: TextInputType.emailAddress,
                validator: (v) => v == null || !v.contains('@') ? 'Invalid email' : null),
            _field(_pPass,  'Password',      Icons.lock_outlined,    obscure: _obscure,
                validator: (v) => v == null || v.length < 8 ? 'Min 8 characters' : null),
            DropdownButtonFormField<String>(value: _gender,
              decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.wc)),
              items: ['male','female','other'].map((g) => DropdownMenuItem(value: g, child: Text(g.capitalize()))).toList(),
              onChanged: (v) => setState(() => _gender = v)),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _registerPatient,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _submitting ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create Patient Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))),
          ]))),

        // ── Doctor tab ───────────────────────────────────────────────────
        SingleChildScrollView(padding: const EdgeInsets.all(24),
          child: Form(key: _doctorFormKey, child: Column(children: [
            _field(_dName,    'Full Name',         Icons.person_outlined),
            _field(_dEmail,   'Email',             Icons.email_outlined, type: TextInputType.emailAddress,
                validator: (v) => v == null || !v.contains('@') ? 'Invalid email' : null),
            _field(_dPass,    'Password',          Icons.lock_outlined, obscure: _obscure,
                validator: (v) => v == null || v.length < 8 ? 'Min 8 characters' : null),
            _field(_dLicense, 'Medical License #', Icons.badge_outlined),
            _field(_dHospital,'Hospital (optional)',Icons.local_hospital_outlined,
                validator: (_) => null),
            DropdownButtonFormField<String>(value: _specialization,
              decoration: const InputDecoration(labelText: 'Specialization', prefixIcon: Icon(Icons.medical_services_outlined)),
              items: _specializations.map((s) => DropdownMenuItem(value: s, child: Text(s.capitalize()))).toList(),
              onChanged: (v) => setState(() => _specialization = v),
              validator: (v) => v == null ? 'Select a specialization' : null),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200)),
              child: const Row(children: [
                Icon(Icons.info_outline, color: Colors.amber, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text('Doctor accounts require admin approval before login.',
                    style: TextStyle(fontSize: 12, color: Colors.black87))),
              ])),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _registerDoctor,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _submitting ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Doctor Registration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))),
          ]))),
      ]),
    );
  }
}

extension StringCapitalize on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
