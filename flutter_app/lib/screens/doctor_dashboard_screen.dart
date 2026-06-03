// lib/screens/doctor_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/case_service.dart';
import '../app_theme.dart';
import 'notifications_screen.dart';
import 'doctor_case_review_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});
  @override State<DoctorDashboardScreen> createState() => _State();
}

class _State extends State<DoctorDashboardScreen> {
  List<Map<String, dynamic>> _queue = [];
  bool _loading = true;
  int _tab = 0;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _queue = await CaseService.getDoctorQueue(); } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Dr. ${user.name.split(' ').first}', style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => context.read<AuthProvider>().logout()),
        ]),
      body: IndexedStack(index: _tab, children: [
        _QueueTab(queue: _queue, loading: _loading, onRefresh: _load),
        const _StatsTab(),
      ]),
      bottomNavigationBar: BottomNavigationBar(currentIndex: _tab, onTap: (i) => setState(() => _tab = i),
        selectedItemColor: AppTheme.primary, unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.inbox_outlined), label: 'Queue'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Stats'),
        ]),
    );
  }
}

class _QueueTab extends StatelessWidget {
  final List<Map<String, dynamic>> queue;
  final bool loading;
  final VoidCallback onRefresh;
  const _QueueTab({required this.queue, required this.loading, required this.onRefresh});
  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (queue.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.check_circle_outline, size: 64, color: Colors.green[200]),
      const SizedBox(height: 16),
      Text('No pending cases', style: TextStyle(color: Colors.grey[500], fontSize: 18)),
      const SizedBox(height: 12),
      ElevatedButton.icon(onPressed: onRefresh, icon: const Icon(Icons.refresh), label: const Text('Refresh')),
    ]));
    return RefreshIndicator(onRefresh: () async => onRefresh(),
      child: ListView.builder(padding: const EdgeInsets.all(16),
        itemCount: queue.length,
        itemBuilder: (_, i) {
          final c = queue[i];
          return Card(margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: Icon(Icons.person, color: AppTheme.primary)),
              title: Text(c['patient_name'] ?? 'Patient', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 4),
                Text(c['case_number'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                if (c['predicted_disease'] != null)
                  Text(c['predicted_disease'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                _StatusChip(c['status'] ?? ''),
              ]),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => DoctorCaseReviewScreen(caseId: c['id'])))));
        }));
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);
  @override
  Widget build(BuildContext context) {
    Color c; String label;
    if (status == 'prediction_ready') { c = Colors.blue;  label = 'Awaiting Review'; }
    else if (status == 'under_review') { c = Colors.orange; label = 'Under Review'; }
    else { c = Colors.grey; label = status; }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)));
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab();
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final total = user.doctorProfile?.totalCasesReviewed ?? 0;
    return Padding(padding: const EdgeInsets.all(24), child: Column(children: [
      const SizedBox(height: 20),
      CircleAvatar(radius: 40, backgroundColor: AppTheme.primary.withOpacity(0.1),
          child: Icon(Icons.medical_services, color: AppTheme.primary, size: 40)),
      const SizedBox(height: 12),
      Text('Dr. ${user.name}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      Text(user.doctorProfile?.specialization ?? '', style: TextStyle(color: Colors.grey[600])),
      const SizedBox(height: 32),
      _StatCard(label: 'Cases Reviewed', value: '$total', icon: Icons.folder_open, color: Colors.blue),
      const SizedBox(height: 16),
      _StatCard(label: 'Specialization', value: user.doctorProfile?.specialization ?? 'General',
          icon: Icons.biotech, color: Colors.green),
    ]));
  }
}

class _StatCard extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2))),
    child: Row(children: [
      Icon(icon, color: color, size: 32),
      const SizedBox(width: 16),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20)),
      ]),
    ]));
}
