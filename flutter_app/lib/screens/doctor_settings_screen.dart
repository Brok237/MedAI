// lib/screens/doctor_settings_screen.dart
// Updated: uses real AuthProvider
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/common_widgets.dart';

class DoctorSettingsScreen extends StatefulWidget {
  const DoctorSettingsScreen({super.key});
  @override State<DoctorSettingsScreen> createState() => _DoctorSettingsScreenState();
}

class _DoctorSettingsScreenState extends State<DoctorSettingsScreen> {
  bool _pushNotifications = true;
  bool _darkMode          = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final initials = user != null && user.name.isNotEmpty
        ? user.name.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
        : 'DR';

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: SingleChildScrollView(child: Column(children: [
        Container(color: const Color(0xFF1E293B),
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
          child: const Row(children: [
            SizedBox(width: 52),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Manage your preferences', style: TextStyle(fontSize: 12, color: Colors.white54)),
            ]),
          ])),
        Container(
          decoration: const BoxDecoration(color: Color(0xFFF0F4F8),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
          child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            const SizedBox(height: 8),
            AppCard(child: Row(children: [
              AvatarCircle(initials: initials, size: 50),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Dr. ${user?.name ?? 'Doctor'}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                Text(user?.email ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
                const SizedBox(height: 4),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(8)),
                  child: Text(user?.doctorProfile?.specialization ?? 'General',
                      style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.w600))),
              ])),
            ])),
            const SizedBox(height: 16),
            _sectionCard(title: 'Notifications', icon: Icons.notifications_outlined, iconColor: AppTheme.primaryBlue,
              children: [
                SettingsRow(title: 'New Case Alerts', subtitle: 'Get notified when a patient submits a case',
                    hasToggle: true, toggleValue: _pushNotifications,
                    onToggleChanged: (v) => setState(() => _pushNotifications = v)),
                const Divider(height: 1),
                const SettingsRow(title: 'Email Notifications', subtitle: 'Case updates via email'),
              ]),
            const SizedBox(height: 16),
            _sectionCard(title: 'Preferences', icon: Icons.tune, iconColor: AppTheme.primaryTeal,
              children: [
                SettingsRow(title: 'Dark Mode', subtitle: 'Switch to dark theme',
                    hasToggle: true, toggleValue: _darkMode,
                    onToggleChanged: (v) => setState(() => _darkMode = v)),
                const Divider(height: 1),
                const SettingsRow(title: 'Language', subtitle: 'English / العربية'),
                const Divider(height: 1),
                const SettingsRow(title: 'About', subtitle: 'MedAI v1.0.0'),
              ]),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => context.read<AuthProvider>().logout(),
              child: Container(width: double.infinity, height: 52,
                decoration: BoxDecoration(color: AppTheme.highRisk, borderRadius: BorderRadius.circular(14)),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.logout, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                ]))),
            const SizedBox(height: 24),
          ])),
        ),
      ])),
    );
  }

  Widget _sectionCard({required String title, required IconData icon,
      required Color iconColor, required List<Widget> children}) =>
    AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: iconColor, size: 18), const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark))]),
      const SizedBox(height: 8),
      ...children,
    ]));
}
