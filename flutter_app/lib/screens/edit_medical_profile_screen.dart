import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/auth_provider.dart';

class EditMedicalProfileScreen extends StatefulWidget {
  const EditMedicalProfileScreen({super.key});

  @override
  State<EditMedicalProfileScreen> createState() =>
      _EditMedicalProfileScreenState();
}

class _EditMedicalProfileScreenState extends State<EditMedicalProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  final _age = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _chronicDiseases = TextEditingController();
  final _allergies = TextEditingController();
  final _currentMeds = TextEditingController();

  String? _gender;
  String? _bloodType;

  final _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void initState() {
    super.initState();

    final profile = context.read<AuthProvider>().user?.patientProfile;

    if (profile != null) {
      _age.text = profile.age?.toString() ?? '';
      _gender = profile.gender;
      _bloodType = profile.bloodType;
      _phone.text = profile.phone ?? '';
      _address.text = profile.address ?? '';
      _chronicDiseases.text = profile.chronicDiseases ?? '';
      _allergies.text = profile.allergies ?? '';
      _currentMeds.text = profile.currentMeds ?? '';
      _weight.text = profile.weightKg ?? '';
      _height.text = profile.heightCm ?? '';
    }
  }

  @override
  void dispose() {
    _age.dispose();
    _weight.dispose();
    _height.dispose();
    _phone.dispose();
    _address.dispose();
    _chronicDiseases.dispose();
    _allergies.dispose();
    _currentMeds.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final auth = context.read<AuthProvider>();

    final ok = await auth.updatePatientProfile(
      age: _intOrNull(_age.text),
      gender: _gender,
      weightKg: _doubleOrNull(_weight.text),
      heightCm: _doubleOrNull(_height.text),
      bloodType: _bloodType,
      phone: _textOrNull(_phone.text),
      address: _textOrNull(_address.text),
      chronicDiseases: _textOrNull(_chronicDiseases.text),
      allergies: _textOrNull(_allergies.text),
      currentMeds: _textOrNull(_currentMeds.text),
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medical profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Failed to update medical profile'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Medical Profile'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(
                _age,
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
                        child: Text(g),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _gender = v),
              ),
              const SizedBox(height: 14),
              _field(
                _weight,
                'Weight (kg)',
                Icons.monitor_weight_outlined,
                type: TextInputType.number,
              ),
              _field(
                _height,
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
              _field(
                _phone,
                'Phone',
                Icons.phone_outlined,
                type: TextInputType.phone,
              ),
              _field(
                _address,
                'Address',
                Icons.location_on_outlined,
                maxLines: 2,
              ),
              _field(
                _chronicDiseases,
                'Chronic Diseases',
                Icons.medical_information_outlined,
                maxLines: 2,
              ),
              _field(
                _allergies,
                'Allergies',
                Icons.warning_amber_outlined,
                maxLines: 2,
              ),
              _field(
                _currentMeds,
                'Current Medications',
                Icons.medication_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Medical Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
