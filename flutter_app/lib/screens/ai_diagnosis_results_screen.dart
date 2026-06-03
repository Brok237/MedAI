// lib/screens/ai_diagnosis_results_screen.dart
// Shows prediction + prescription (after doctor approval).
import 'package:flutter/material.dart';
import '../models/case_model.dart';
import '../services/case_service.dart';
import '../app_theme.dart';
import 'contact_doctor_screen.dart';

class AIDiagnosisResultsScreen extends StatefulWidget {
  final String caseId;
  const AIDiagnosisResultsScreen({super.key, required this.caseId});
  @override
  State<AIDiagnosisResultsScreen> createState() => _State();
}

class _State extends State<AIDiagnosisResultsScreen> {
  CaseModel? _case;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _case = await CaseService.getCaseDetail(widget.caseId);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_case == null)
      return const Scaffold(body: Center(child: Text('Case not found')));
    final c = _case!;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
          title: Text(c.caseNumber),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _load)
          ]),
      body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            // Status banner
            _StatusBanner(c),
            const SizedBox(height: 16),
            // Prediction card
            if (c.predictedDisease != null) _PredictionCard(c),
            const SizedBox(height: 16),
            // Prescription (only if approved)
            if (c.isApproved && c.prescription != null)
              _PrescriptionCard(c.prescription!),
            // Rejection reason
            if (c.isRejected && c.rejectionReason != null)
              _RejectionCard(c.rejectionReason!),
            // Symptoms submitted
            const SizedBox(height: 8),
            _SymptomsCard(c.symptomsRaw),
            const SizedBox(height: 16),
            // AI chat button
            OutlinedButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ContactDoctorScreen(caseId: widget.caseId))),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Ask AI Assistant about this case'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14))),
            const SizedBox(height: 32),
          ])),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final CaseModel c;
  const _StatusBanner(this.c);
  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (c.status) {
      case 'approved':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case 'under_review':
        color = Colors.orange;
        icon = Icons.rate_review;
        break;
      default:
        color = Colors.blue;
        icon = Icons.hourglass_top;
    }
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Row(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(c.statusLabel,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                if (c.isPending)
                  const Text('Your case is being reviewed by a doctor.',
                      style: TextStyle(fontSize: 12, color: Colors.black54)),
              ])),
        ]));
  }
}

class _PredictionCard extends StatelessWidget {
  final CaseModel c;
  const _PredictionCard(this.c);
  @override
  Widget build(BuildContext context) => Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('AI Prediction',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            const SizedBox(height: 4),
            Text(c.predictedDisease!,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
            const SizedBox(height: 8),
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8)),
                child: const Text(
                    '⚠️ This is an AI-assisted suggestion. Final diagnosis is made by your doctor.',
                    style: TextStyle(fontSize: 11, color: Colors.black87))),
          ])));
}

class _PrescriptionCard extends StatelessWidget {
  final PrescriptionModel p;
  const _PrescriptionCard(this.p);
  @override
  Widget build(BuildContext context) => Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.green.shade50,
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.description, color: Colors.green),
              const SizedBox(width: 8),
              const Text('Approved Prescription',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              if (p.issuedByName != null)
                Text('Dr. ${p.issuedByName}',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black54)),
            ]),
            const Divider(),
            ...p.approvedDrugs.map((d) => _DrugTile(d)),
            if (p.instructions != null && p.instructions!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Doctor Instructions:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(p.instructions!,
                  style: const TextStyle(color: Colors.black87)),
            ],
            if (p.followUpDate != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text('Follow-up: ${p.followUpDate}',
                    style: const TextStyle(color: Colors.black87))
              ]),
            ],
          ])));
}

class _DrugTile extends StatelessWidget {
  final DrugRecommendation d;
  const _DrugTile(this.d);
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(d.drugName, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (d.egyptianBrand != null)
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(d.egyptianBrand!,
                    style: const TextStyle(fontSize: 11, color: Colors.blue))),
        ]),
        if (d.effectiveDosage != null)
          Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('💊 ${d.effectiveDosage}',
                  style: const TextStyle(color: Colors.black87))),
        if (d.keySideEffects != null)
          Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('⚠️ Side effects: ${d.keySideEffects}',
                  style: const TextStyle(fontSize: 12, color: Colors.orange))),
      ]));
}

class _RejectionCard extends StatelessWidget {
  final String reason;
  const _RejectionCard(this.reason);
  @override
  Widget build(BuildContext context) => Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.info, color: Colors.red),
              SizedBox(width: 8),
              Text('Doctor Feedback',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red))
            ]),
            const Divider(),
            Text(reason, style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 8),
            const Text('Please submit a new case with more details.',
                style: TextStyle(color: Colors.black54, fontSize: 12)),
          ])));
}

class _SymptomsCard extends StatelessWidget {
  final List<String> symptoms;
  const _SymptomsCard(this.symptoms);
  @override
  Widget build(BuildContext context) => Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Symptoms Submitted',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
                spacing: 6,
                runSpacing: 6,
                children: symptoms
                    .map((s) => Chip(
                        label: Text(s.replaceAll('_', ' '),
                            style: const TextStyle(fontSize: 11)),
                        backgroundColor: AppTheme.primary.withOpacity(0.08),
                        side: BorderSide(
                            color: AppTheme.primary.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 4)))
                    .toList()),
          ])));
}
