// lib/screens/medical_history_screen.dart
// Updated: loads real cases from backend instead of DummyData
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/case_provider.dart';
import '../models/case_model.dart';
import 'ai_diagnosis_results_screen.dart';

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});
  @override State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  String _filter = 'All';
  final _filters = ['All', 'Approved', 'Pending', 'Rejected'];
  String _search = '';

  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CaseProvider>().loadMyCases();
    });
  }

  List<CaseModel> _filtered(List<CaseModel> cases) {
    return cases.where((c) {
      final matchSearch = _search.isEmpty ||
          (c.predictedDisease?.toLowerCase().contains(_search.toLowerCase()) ?? false) ||
          c.caseNumber.toLowerCase().contains(_search.toLowerCase());
      final matchFilter = _filter == 'All' ||
          (_filter == 'Approved' && c.isApproved) ||
          (_filter == 'Pending'  && c.isPending)  ||
          (_filter == 'Rejected' && c.isRejected);
      return matchSearch && matchFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CaseProvider>();
    final filtered = _filtered(provider.cases);
    final total    = provider.cases.length;
    final approved = provider.cases.where((c) => c.isApproved).length;
    final pending  = provider.cases.where((c) => c.isPending).length;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Column(children: [
        // Header
        Container(
          decoration: BoxDecoration(gradient: AppTheme.headerGradientPurple),
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
          child: Column(children: [
            Row(children: [
              GestureDetector(onTap: () => Navigator.pop(context),
                child: Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back, size: 18, color: Colors.white))),
              const SizedBox(width: 16),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Medical History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Your case timeline', style: TextStyle(fontSize: 13, color: Colors.white70)),
              ]),
            ]),
          ]),
        ),
        Expanded(child: Column(children: [
          Container(color: Colors.white, padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(children: [
              // Search
              TextField(onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(hintText: 'Search by disease or case number...',
                  hintStyle: const TextStyle(color: AppTheme.textLight, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textLight, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  filled: true, fillColor: AppTheme.bgLight,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12))),
              const SizedBox(height: 12),
              // Filter chips
              SingleChildScrollView(scrollDirection: Axis.horizontal,
                child: Row(children: _filters.map((f) => GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: Container(margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _filter == f ? AppTheme.primaryBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _filter == f ? AppTheme.primaryBlue : const Color(0xFFE2E8F0))),
                    child: Text(f, style: TextStyle(
                      color: _filter == f ? Colors.white : AppTheme.textGrey, fontSize: 12,
                      fontWeight: _filter == f ? FontWeight.w600 : FontWeight.normal)))
                )).toList())),
              const SizedBox(height: 16),
            ])),
          // Stats row
          Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(children: [
              Expanded(child: _statCard(total.toString(), 'Total')),
              const SizedBox(width: 10),
              Expanded(child: _statCard(approved.toString(), 'Approved', const Color(0xFFD1FAE5), AppTheme.primaryGreen)),
              const SizedBox(width: 10),
              Expanded(child: _statCard(pending.toString(), 'Pending', const Color(0xFFDBEAFE), AppTheme.primaryBlue)),
            ])),
          // List
          Expanded(child: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : filtered.isEmpty
              ? Center(child: Text('No cases found', style: TextStyle(color: Colors.grey[500])))
              : RefreshIndicator(
                  onRefresh: () => provider.loadMyCases(),
                  child: ListView.builder(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _CaseHistoryTile(filtered[i])))),
        ])),
      ]),
    );
  }

  Widget _statCard(String value, String label, [Color? bg, Color? textColor]) =>
    Container(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(color: bg ?? Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor ?? AppTheme.textDark)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: textColor ?? AppTheme.textGrey)),
      ]));
}

class _CaseHistoryTile extends StatelessWidget {
  final CaseModel c;
  const _CaseHistoryTile(this.c);
  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    if (c.isApproved)     { statusColor = AppTheme.primaryGreen; statusIcon = Icons.check_circle; }
    else if (c.isRejected){ statusColor = AppTheme.highRisk;     statusIcon = Icons.cancel; }
    else                  { statusColor = AppTheme.primaryBlue;  statusIcon = Icons.hourglass_top; }

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          child: Icon(statusIcon, color: Colors.white, size: 16)),
        Container(width: 2, height: 80, color: const Color(0xFFE2E8F0)),
      ]),
      const SizedBox(width: 12),
      Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 16),
        child: Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AIDiagnosisResultsScreen(caseId: c.id))),
            borderRadius: BorderRadius.circular(12),
            child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text(c.predictedDisease ?? 'Pending prediction',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.isApproved ? const Color(0xFFD1FAE5) : c.isRejected ? const Color(0xFFFEE2E2) : const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(20)),
                  child: Text(c.isApproved ? 'Approved' : c.isRejected ? 'Rejected' : 'Pending',
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 4),
              Text(c.caseNumber, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${c.symptomsRaw.length} symptoms', style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                if (c.predictionConfidence != null)
                  Text('${(c.predictionConfidence! * 100).toStringAsFixed(0)}% confidence',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
              ]),
              if (c.predictionConfidence != null) ...[
                const SizedBox(height: 6),
                ClipRRect(borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: c.predictionConfidence!, minHeight: 4,
                    backgroundColor: Colors.grey.shade200, color: statusColor)),
              ],
            ])))))),
    ]);
  }
}
