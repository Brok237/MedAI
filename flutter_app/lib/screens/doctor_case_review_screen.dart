// lib/screens/doctor_case_review_screen.dart
import 'package:flutter/material.dart';
import '../services/case_service.dart';
import '../app_theme.dart';

class DoctorCaseReviewScreen extends StatefulWidget {
  final String caseId;
  const DoctorCaseReviewScreen({super.key, required this.caseId});
  @override
  State<DoctorCaseReviewScreen> createState() => _State();
}

class _State extends State<DoctorCaseReviewScreen> {
  Map<String, dynamic>? _case;
  bool _loading = true;
  bool _submitting = false;
  final _notesCtrl = TextEditingController();
  final _rejectReasonCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();

  // Drug decision state: drugId → 'approved' | 'rejected'
  final Map<String, String> _drugDecisions = {};
  final Map<String, TextEditingController> _dosageOverrides = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _rejectReasonCtrl.dispose();
    _instructionsCtrl.dispose();
    for (final c in _dosageOverrides.values) c.dispose();
    super.dispose();
  }

  String _display(dynamic value) {
    if (value == null) return 'Not provided';
    final text = value.toString().trim();
    return text.isEmpty ? 'Not provided' : text;
  }

  String _displayWithUnit(dynamic value, String unit) {
    if (value == null) return 'Not provided';
    final text = value.toString().trim();
    if (text.isEmpty) return 'Not provided';
    return '$text $unit';
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _case = await CaseService.getCaseForReview(widget.caseId);
    } catch (_) {}
    // Initialize drug decisions to 'approved'
    if (_case != null) {
      final drugs =
          List<Map<String, dynamic>>.from(_case!['drug_recommendations'] ?? []);
      for (final d in drugs) {
        final id = d['id'] as String;
        _drugDecisions[id] = 'approved';
        _dosageOverrides[id] = TextEditingController(text: d['dosage'] ?? '');
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _submit(String action) async {
    if (action == 'reject' && _rejectReasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please provide a rejection reason.')));
      return;
    }
    setState(() => _submitting = true);

    final drugDecisionList = _drugDecisions.entries
        .map((e) => {
              'drug_id': e.key,
              'status': e.value,
              'dosage_override': _dosageOverrides[e.key]?.text ?? '',
            })
        .toList();

    try {
      await CaseService.submitDecision(
        caseId: widget.caseId,
        action: action,
        doctorNotes: _notesCtrl.text.trim(),
        rejectionReason: _rejectReasonCtrl.text.trim(),
        drugDecisions: drugDecisionList,
        instructions: _instructionsCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(action == 'approve'
              ? 'Prescription approved and sent to patient!'
              : 'Case rejected.'),
          backgroundColor: action == 'approve' ? Colors.green : Colors.red));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_case == null)
      return const Scaffold(body: Center(child: Text('Case not found')));

    final c = _case!;
    final patient = c['patient'] as Map<String, dynamic>? ?? {};
    final patientProfile =
        patient['patient_profile'] as Map<String, dynamic>? ?? {};
    final drugs =
        List<Map<String, dynamic>>.from(c['drug_recommendations'] ?? []);
    final symptoms = List<String>.from(c['symptoms_raw'] ?? []);
    final alreadyDecided =
        c['status'] == 'approved' || c['status'] == 'rejected';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
          title: Text(c['case_number'] ?? 'Review Case'),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Patient info
            _Section(
              title: 'Patient',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow('Name', patient['name']?.toString() ?? 'N/A'),
                  _InfoRow('Email', patient['email']?.toString() ?? 'N/A'),
                  if (c['chief_complaint'] != null &&
                      (c['chief_complaint'] as String).isNotEmpty)
                    _InfoRow('Complaint', c['chief_complaint'].toString()),
                ],
              ),
            ),
            const SizedBox(height: 12),

// Patient medical profile
            _Section(
              title: 'Patient Medical Profile',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow('Age', _display(patientProfile['age'])),
                  _InfoRow('Gender', _display(patientProfile['gender'])),
                  _InfoRow('Weight',
                      _displayWithUnit(patientProfile['weight_kg'], 'kg')),
                  _InfoRow('Height',
                      _displayWithUnit(patientProfile['height_cm'], 'cm')),
                  _InfoRow('Blood', _display(patientProfile['blood_type'])),
                  const Divider(height: 18),
                  _InfoRow(
                      'Chronic', _display(patientProfile['chronic_diseases'])),
                  _InfoRow('Allergies', _display(patientProfile['allergies'])),
                  _InfoRow('Meds', _display(patientProfile['current_meds'])),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Prediction
            _Section(
                title: 'AI Prediction',
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['predicted_disease'] ?? 'N/A',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      if (c['prediction_confidence'] != null)
                        Text(
                            'Confidence: ${(c['prediction_confidence'] * 100).toStringAsFixed(1)}%',
                            style: TextStyle(color: Colors.grey[600])),
                    ])),
            const SizedBox(height: 12),

            // Symptoms
            _Section(
                title: 'Symptoms (${symptoms.length})',
                child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: symptoms
                        .map((s) => Chip(
                            label: Text(s.replaceAll('_', ' '),
                                style: const TextStyle(fontSize: 11)),
                            backgroundColor: AppTheme.primary.withOpacity(0.06),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero))
                        .toList())),
            const SizedBox(height: 12),

            // Drug recommendations
            if (drugs.isNotEmpty)
              _Section(
                  title: 'Recommended Drugs',
                  child: Column(
                      children: drugs.map((d) {
                    final id = d['id'] as String;
                    final dec = _drugDecisions[id] ?? 'approved';
                    return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: dec == 'approved'
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: dec == 'approved'
                                    ? Colors.green.shade200
                                    : Colors.red.shade200)),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                        child: Text(d['drug_name'] ?? '',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    if (!alreadyDecided)
                                      Row(children: [
                                        _DecisionBtn(
                                            label: '✓ Approve',
                                            selected: dec == 'approved',
                                            color: Colors.green,
                                            onTap: () => setState(() =>
                                                _drugDecisions[id] =
                                                    'approved')),
                                        const SizedBox(width: 6),
                                        _DecisionBtn(
                                            label: '✗ Reject',
                                            selected: dec == 'rejected',
                                            color: Colors.red,
                                            onTap: () => setState(() =>
                                                _drugDecisions[id] =
                                                    'rejected')),
                                      ]),
                                  ]),
                              if (d['egyptian_brand'] != null)
                                Text('Brand: ${d['egyptian_brand']}',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 12)),
                              if (d['role'] != null)
                                Text('Role: ${d['role']}',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 12)),
                              const SizedBox(height: 8),
                              if (!alreadyDecided)
                                TextField(
                                    controller: _dosageOverrides[id],
                                    decoration: InputDecoration(
                                        labelText: 'Dosage (editable)',
                                        isDense: true,
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 8))),
                              if (alreadyDecided && d['dosage'] != null)
                                Text('Dosage: ${d['dosage']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                              if (d['key_side_effects'] != null)
                                Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                        'Side effects: ${d['key_side_effects']}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange))),
                            ]));
                  }).toList())),

            if (!alreadyDecided) ...[
              const SizedBox(height: 12),
              // Doctor notes
              _Section(
                  title: 'Your Notes',
                  child: TextField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          hintText: 'Add notes for the patient or records...',
                          border: OutlineInputBorder(),
                          isDense: true))),
              const SizedBox(height: 12),
              _Section(
                  title: 'Patient Instructions (shown after approval)',
                  child: TextField(
                      controller: _instructionsCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          hintText:
                              'e.g. Take with food, drink plenty of water...',
                          border: OutlineInputBorder(),
                          isDense: true))),
              const SizedBox(height: 12),
              // Reject reason (shown always, required if rejecting)
              _Section(
                  title: 'Rejection Reason (required if rejecting)',
                  child: TextField(
                      controller: _rejectReasonCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                          hintText:
                              'Explain why this case is being rejected...',
                          border: OutlineInputBorder(),
                          isDense: true))),
              const SizedBox(height: 24),
              // Action buttons
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: _submitting ? null : () => _submit('reject'),
                        icon: const Icon(Icons.cancel_outlined,
                            color: Colors.red),
                        label: const Text('Reject',
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))))),
                const SizedBox(width: 16),
                Expanded(
                    child: ElevatedButton.icon(
                        onPressed:
                            _submitting ? null : () => _submit('approve'),
                        icon: _submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_outline,
                                color: Colors.white),
                        label: const Text('Approve',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))))),
              ]),
              const SizedBox(height: 32),
            ] else ...[
              const SizedBox(height: 20),
              Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('This case has already been ${c['status']}.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]))),
              const SizedBox(height: 32),
            ],
          ])),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Divider(height: 16),
            child,
          ])));
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 80,
            child: Text('$label:',
                style: TextStyle(color: Colors.grey[600], fontSize: 13))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500))),
      ]));
}

class _DecisionBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _DecisionBtn(
      {required this.label,
      required this.selected,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: selected ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color)),
          child: Text(label,
              style: TextStyle(
                  color: selected ? Colors.white : color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600))));
}
