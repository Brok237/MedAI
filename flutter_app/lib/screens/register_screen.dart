// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  final _patientAccountKey = GlobalKey<FormState>();
  final _patientMedicalKey = GlobalKey<FormState>();
  final _doctorFormKey = GlobalKey<FormState>();

  bool _submitting = false;
  bool _obscure = true;
  int _patientStep = 0;

  // Patient account fields
  final _pName = TextEditingController();
  final _pEmail = TextEditingController();
  final _pPass = TextEditingController();

  // Patient medical fields
  final _pAge = TextEditingController();
  String? _gender;
  final _pWeight = TextEditingController();
  final _pHeight = TextEditingController();
  String? _bloodType;
  final _pPhone = TextEditingController();
  final _pAddress = TextEditingController();
  final _pChronicDiseases = TextEditingController();
  final _pAllergies = TextEditingController();
  final _pCurrentMeds = TextEditingController();

  // Doctor fields
  final _dName = TextEditingController();
  final _dEmail = TextEditingController();
  final _dPass = TextEditingController();
  final _dLicense = TextEditingController();
  final _dHospital = TextEditingController();
  String? _specialization;

  final _specializations = [
    'general',
    'cardiology',
    'neurology',
    'dermatology',
    'pediatrics',
    'orthopedics',
    'gastroenterology',
    'psychiatry',
    'endocrinology',
    'pulmonology',
  ];

  final _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();

    for (final c in [
      _pName,
      _pEmail,
      _pPass,
      _pAge,
      _pWeight,
      _pHeight,
      _pPhone,
      _pAddress,
      _pChronicDiseases,
      _pAllergies,
      _pCurrentMeds,
      _dName,
      _dEmail,
      _dPass,
      _dLicense,
      _dHospital,
    ]) {
      c.dispose();
    }

    super.dispose();
  }

  int? _intOrNull(String value) {
    final v = value.trim();
    if (v.isEmpty) return null;
    return int.tryParse(v);
  }

  double? _doubleOrNull(String value) {
    final v = value.trim();
    if (v.isEmpty) return null;
    return double.tryParse(v);
  }

  String? _textOrNull(String value) {
    final v = value.trim();
    return v.isEmpty ? null : v;
  }

  void _goToMedicalStep() {
    if (!_patientAccountKey.currentState!.validate()) return;
    setState(() => _patientStep = 1);
  }

  Future<void> _registerPatient() async {
    if (!_patientMedicalKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final auth = context.read<AuthProvider>();

    final ok = await auth.registerPatient(
      name: _pName.text.trim(),
      email: _pEmail.text.trim(),
      password: _pPass.text,
      age: _intOrNull(_pAge.text),
      gender: _gender,
      weightKg: _doubleOrNull(_pWeight.text),
      heightCm: _doubleOrNull(_pHeight.text),
      bloodType: _bloodType,
      phone: _textOrNull(_pPhone.text),
      address: _textOrNull(_pAddress.text),
      chronicDiseases: _textOrNull(_pChronicDiseases.text),
      allergies: _textOrNull(_pAllergies.text),
      currentMeds: _textOrNull(_pCurrentMeds.text),
    );

    if (!mounted) return;

    setState(() => _submitting = false);

    if (ok) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Registration failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _registerDoctor() async {
    if (!_doctorFormKey.currentState!.validate()) return;

    if (_specialization == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a specialization')),
      );
      return;
    }

    setState(() => _submitting = true);

    final auth = context.read<AuthProvider>();

    final ok = await auth.registerDoctor(
      name: _dName.text.trim(),
      email: _dEmail.text.trim(),
      password: _dPass.text,
      specialization: _specialization!,
      licenseNumber: _dLicense.text.trim(),
      hospital: _dHospital.text.trim(),
    );

    if (!mounted) return;

    setState(() => _submitting = false);

    if (ok) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Registration Submitted'),
          content: const Text(
            'Your doctor account is pending admin approval. You will receive an email once approved.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Registration failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool obscure = false,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: type,
        maxLines: obscure ? 1 : maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        validator: validator ??
            (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              return null;
            },
      ),
    );
  }

  Widget _optionalField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  }) {
    return _field(
      ctrl,
      label,
      icon,
      type: type,
      maxLines: maxLines,
      validator: (_) => null,
    );
  }

  Widget _patientAccountStep() {
    return Form(
      key: _patientAccountKey,
      child: Column(
        children: [
          _field(_pName, 'Full Name', Icons.person_outlined),
          _field(
            _pEmail,
            'Email',
            Icons.email_outlined,
            type: TextInputType.emailAddress,
            validator: (v) =>
                v == null || !v.contains('@') ? 'Invalid email' : null,
          ),
          _field(
            _pPass,
            'Password',
            Icons.lock_outlined,
            obscure: _obscure,
            validator: (v) =>
                v == null || v.length < 8 ? 'Min 8 characters' : null,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _goToMedicalStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Next: Patient  Information',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _patientMedicalStep() {
    return Form(
      key: _patientMedicalKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _patientStep = 0),
                icon: const Icon(Icons.arrow_back),
              ),
              const Expanded(
                child: Text(
                  'Medical Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
            ),
            child: const Text(
              'This information helps doctors review your AI diagnosis safely.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          _optionalField(
            _pAge,
            'Age',
            Icons.cake_outlined,
            type: TextInputType.number,
          ),
          DropdownButtonFormField<String>(
            value: _gender,
            decoration: const InputDecoration(
              labelText: 'Gender',
              prefixIcon: Icon(Icons.wc),
            ),
            items: ['male', 'female', 'other']
                .map(
                  (g) => DropdownMenuItem(
                    value: g,
                    child: Text(g.capitalize()),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _gender = v),
          ),
          const SizedBox(height: 14),
          _optionalField(
            _pWeight,
            'Weight (kg)',
            Icons.monitor_weight_outlined,
            type: TextInputType.number,
          ),
          _optionalField(
            _pHeight,
            'Height (cm)',
            Icons.height,
            type: TextInputType.number,
          ),
          DropdownButtonFormField<String>(
            value: _bloodType,
            decoration: const InputDecoration(
              labelText: 'Blood Type',
              prefixIcon: Icon(Icons.bloodtype_outlined),
            ),
            items: _bloodTypes
                .map(
                  (b) => DropdownMenuItem(
                    value: b,
                    child: Text(b),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _bloodType = v),
          ),
          const SizedBox(height: 14),
          _optionalField(
            _pPhone,
            'Phone',
            Icons.phone_outlined,
            type: TextInputType.phone,
          ),
          _optionalField(
            _pAddress,
            'Address',
            Icons.location_on_outlined,
            maxLines: 2,
          ),
          _optionalField(
            _pChronicDiseases,
            'Chronic Diseases',
            Icons.medical_information_outlined,
            maxLines: 2,
          ),
          _optionalField(
            _pAllergies,
            'Allergies',
            Icons.warning_amber_outlined,
            maxLines: 2,
          ),
          _optionalField(
            _pCurrentMeds,
            'Current Medications',
            Icons.medication_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submitting ? null : _registerPatient,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _submitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Create Patient Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _doctorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _doctorFormKey,
        child: Column(
          children: [
            _field(_dName, 'Full Name', Icons.person_outlined),
            _field(
              _dEmail,
              'Email',
              Icons.email_outlined,
              type: TextInputType.emailAddress,
              validator: (v) =>
                  v == null || !v.contains('@') ? 'Invalid email' : null,
            ),
            _field(
              _dPass,
              'Password',
              Icons.lock_outlined,
              obscure: _obscure,
              validator: (v) =>
                  v == null || v.length < 8 ? 'Min 8 characters' : null,
            ),
            _field(_dLicense, 'Medical License #', Icons.badge_outlined),
            _field(
              _dHospital,
              'Hospital (optional)',
              Icons.local_hospital_outlined,
              validator: (_) => null,
            ),
            DropdownButtonFormField<String>(
              value: _specialization,
              decoration: const InputDecoration(
                labelText: 'Specialization',
                prefixIcon: Icon(Icons.medical_services_outlined),
              ),
              items: _specializations
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.capitalize()),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _specialization = v),
              validator: (v) => v == null ? 'Select a specialization' : null,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Doctor accounts require admin approval before login.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _registerDoctor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit Doctor Registration',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _patientTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child:
            _patientStep == 0 ? _patientAccountStep() : _patientMedicalStep(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Patient'),
            Tab(text: 'Doctor'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _patientTab(),
          _doctorTab(),
        ],
      ),
    );
  }
}

extension StringCapitalize on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
