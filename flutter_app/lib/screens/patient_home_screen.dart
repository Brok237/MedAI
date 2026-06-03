// lib/screens/patient_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/case_provider.dart';
import '../models/case_model.dart';
import '../app_theme.dart';
import 'add_symptoms_screen.dart';
import 'ai_diagnosis_results_screen.dart';
import 'contact_doctor_screen.dart';
import 'medical_history_screen.dart';
import 'patient_settings_screen.dart';

import 'notifications_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});
  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CaseProvider>().loadMyCases();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Hello, ${user.name.split(' ').first}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen()))),
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<AuthProvider>().logout()),
        ],
      ),
      body: IndexedStack(index: _tab, children: const [
        _HomeTab(),
        _CasesTab(),
        _ChatTab(),
        PatientSettingsScreen(),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.folder_outlined), label: 'My Cases'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_outlined), label: 'Chat'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

// ── Home tab ──────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  const _HomeTab();
  @override
  Widget build(BuildContext context) {
    final cases = context.watch<CaseProvider>().cases;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Quick action card
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppTheme.primary,
                  AppTheme.primary.withOpacity(0.7)
                ]),
                borderRadius: BorderRadius.circular(16)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('How are you feeling?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Submit your symptoms for AI analysis',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddSymptomsScreen())),
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text('Submit Symptoms'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)))),
            ])),
        const SizedBox(height: 24),
        // Quick actions
        Text('Quick Access',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(children: [
          _QuickAction(
              icon: Icons.history,
              label: 'History',
              color: Colors.blue,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MedicalHistoryScreen()))),
          const SizedBox(width: 12),
          _QuickAction(
              icon: Icons.chat,
              label: 'AI Chat',
              color: Colors.green,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ContactDoctorScreen()))),
          const SizedBox(width: 12),
          _QuickAction(
              icon: Icons.folder,
              label: 'My Cases',
              color: Colors.orange,
              onTap: () {}),
        ]),
        const SizedBox(height: 24),
        // Recent cases
        if (cases.isNotEmpty) ...[
          Text('Recent Cases',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...cases.take(3).map((c) => _CaseCard(c)),
        ],
      ]),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 8),
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ]))));
}

// ── Cases tab ─────────────────────────────────────────────────────────────────
class _CasesTab extends StatelessWidget {
  const _CasesTab();
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CaseProvider>();
    if (provider.loading)
      return const Center(child: CircularProgressIndicator());
    if (provider.cases.isEmpty)
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.folder_open, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text('No cases yet',
            style: TextStyle(color: Colors.grey[500], fontSize: 18)),
        const SizedBox(height: 8),
        ElevatedButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddSymptomsScreen())),
            child: const Text('Submit First Case')),
      ]));
    return RefreshIndicator(
        onRefresh: () => provider.loadMyCases(),
        child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.cases.length,
            itemBuilder: (_, i) => _CaseCard(provider.cases[i])));
  }
}

class _CaseCard extends StatelessWidget {
  final CaseModel c;
  const _CaseCard(this.c);
  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (c.status) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      case 'under_review':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.blue;
    }
    return Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.1),
                child: Icon(Icons.medical_information, color: statusColor)),
            title: Text(c.caseNumber,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 4),
              if (c.predictedDisease != null)
                Text(c.predictedDisease!,
                    style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 4),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(c.statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600))),
            ]),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AIDiagnosisResultsScreen(caseId: c.id)))));
  }
}

// ── Chat stub tab ─────────────────────────────────────────────────────────────
class _ChatTab extends StatelessWidget {
  const _ChatTab();
  @override
  Widget build(BuildContext context) => Center(
      child: ElevatedButton.icon(
          icon: const Icon(Icons.chat),
          label: const Text('Open AI Assistant'),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ContactDoctorScreen()))));
}
