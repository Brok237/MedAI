// lib/screens/patient_settings_screen.dart
// Updated: uses real AuthProvider for user info and logout
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../widgets/common_widgets.dart';
import 'edit_medical_profile_screen.dart';

class PatientSettingsScreen extends StatefulWidget {
  const PatientSettingsScreen({super.key});
  @override
  State<PatientSettingsScreen> createState() => _PatientSettingsScreenState();
}

class _PatientSettingsScreenState extends State<PatientSettingsScreen> {
  bool _pushNotifications = true;

  // Change password state
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confPassCtrl = TextEditingController();

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _showChangePassword() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: _oldPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password')),
          const SizedBox(height: 8),
          TextField(
              controller: _newPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password')),
          const SizedBox(height: 8),
          TextField(
              controller: _confPassCtrl,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Confirm new password')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () async {
                if (_newPassCtrl.text != _confPassCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Passwords do not match')));
                  return;
                }
                try {
                  await AuthService.changePassword(
                    oldPassword: _oldPassCtrl.text,
                    newPassword: _newPassCtrl.text,
                    confirmPassword: _confPassCtrl.text,
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Password changed successfully'),
                      backgroundColor: Colors.green));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red));
                }
              },
              child: const Text('Update')),
        ],
      ),
    );
    _oldPassCtrl.clear();
    _newPassCtrl.clear();
    _confPassCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final initials = user != null && user.name.isNotEmpty
        ? user.name
            .split(' ')
            .map((p) => p.isNotEmpty ? p[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SingleChildScrollView(
        child: Column(children: [
          // Header
          Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
              child: const Row(children: [
                SizedBox(width: 52),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Settings',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark)),
                  Text('Manage your preferences',
                      style: TextStyle(fontSize: 12, color: AppTheme.textGrey)),
                ]),
              ])),
          Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                // Profile card
                AppCard(
                    child: Column(children: [
                  Row(children: [
                    AvatarCircle(initials: initials, size: 50),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(user?.name ?? 'Patient',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark)),
                          Text(user?.email ?? '',
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textGrey)),
                          const SizedBox(height: 4),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFDBEAFE),
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Text('Patient',
                                  style: TextStyle(
                                      color: AppTheme.primaryBlue,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600))),
                        ])),
                  ]),
                ])),
                const SizedBox(height: 16),

                // Notifications
                _sectionCard(
                    title: 'Notifications',
                    icon: Icons.notifications_outlined,
                    iconColor: AppTheme.primaryBlue,
                    children: [
                      SettingsRow(
                          title: 'Push Notifications',
                          subtitle: 'Get alerts about your cases',
                          hasToggle: true,
                          toggleValue: _pushNotifications,
                          onToggleChanged: (v) =>
                              setState(() => _pushNotifications = v)),
                    ]),
                const SizedBox(height: 16),

                // Security
                _sectionCard(
                    title: 'Privacy & Security',
                    icon: Icons.shield_outlined,
                    iconColor: AppTheme.primaryGreen,
                    children: [
                      const Divider(height: 1),
                      SettingsRow(
                          title: 'Change Password',
                          subtitle: 'Update your account password',
                          onTap: _showChangePassword),
                    ]),
                const SizedBox(height: 16),

// Medical Profile
                _sectionCard(
                  title: 'Medical Profile',
                  icon: Icons.favorite_outline,
                  iconColor: Colors.red,
                  children: [
                    SettingsRow(
                      title: 'Patient info',
                      subtitle:
                          'Data, Medical history, allergies and medications',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditMedicalProfileScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Preferences
                _sectionCard(
                    title: 'Preferences',
                    icon: Icons.tune,
                    iconColor: AppTheme.primaryTeal,
                    children: [
                      const Divider(height: 1),
                      const SettingsRow(
                          title: 'Language', subtitle: 'English / العربية'),
                      const Divider(height: 1),
                      const SettingsRow(
                          title: 'About', subtitle: 'MedAI v1.0.0'),
                    ]),
                const SizedBox(height: 20),

                // Logout
                GestureDetector(
                    onTap: () => context.read<AuthProvider>().logout(),
                    child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                            color: AppTheme.highRisk,
                            borderRadius: BorderRadius.circular(14)),
                        child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text('Logout',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                            ]))),
                const SizedBox(height: 16),

                Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A))),
                    child: const Text(
                        '🔒 Your health data is encrypted. MedAI never sells your data.',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 11, color: AppTheme.textGrey))),
                const SizedBox(height: 24),
              ])),
        ]),
      ),
    );
  }

  Widget _sectionCard(
          {required String title,
          required IconData icon,
          required Color iconColor,
          required List<Widget> children}) =>
      AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark))
        ]),
        const SizedBox(height: 8),
        ...children,
      ]));
}
