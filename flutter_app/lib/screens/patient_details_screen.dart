// lib/screens/patient_details_screen.dart
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/dummy_data.dart';
import '../widgets/common_widgets.dart';
import 'contact_doctor_screen.dart';

class PatientDetailsScreen extends StatelessWidget {
  final PatientModel patient;

  const PatientDetailsScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(gradient: AppTheme.headerGradientBlue),
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back,
                        size: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Complete medical overview',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Patient Info Card
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AvatarCircle(initials: patient.initials, size: 52),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    patient.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                  Text(
                                    '${patient.age} years • ${patient.gender} • ${patient.bloodType}',
                                    style: const TextStyle(
                                        fontSize: 12, color: AppTheme.textGrey),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD1FAE5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Active Patient',
                                      style: TextStyle(
                                        color: AppTheme.primaryGreen,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                                child: _infoField('Phone', patient.phone)),
                            Expanded(
                                child: _infoField('Email', patient.email)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                                child: _infoField(
                                    'Last Visit', patient.updatedDate)),
                            Expanded(
                                child:
                                    _infoField('Patient ID', patient.patientId)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // AI Diagnosis Report
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.article_outlined,
                                color: AppTheme.primaryGreen, size: 18),
                            const SizedBox(width: 6),
                            const Text(
                              'AI Diagnosis Report',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.bgLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    patient.lastDiagnosis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                  RiskBadge(
                                    level: patient.status == 'Critical'
                                        ? 'High'
                                        : (patient.status == 'At risk'
                                            ? 'Medium'
                                            : 'Low'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Submitted on ${patient.updatedDate}',
                                style: const TextStyle(
                                    fontSize: 11, color: AppTheme.textGrey),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Reported Symptoms:',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Persistent cough with mucus, chest discomfort, shortness of breath, mild fever',
                                style: TextStyle(
                                    fontSize: 12, color: AppTheme.textGrey),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _diagStat(
                                      'AI Confidence', '${patient.aiConfidence}%'),
                                  _diagStat('Duration', '5 days'),
                                  _diagStat('Severity', '70%'),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ConfidenceBar(confidence: patient.aiConfidence),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  size: 14, color: AppTheme.mediumRisk),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'AI-generated diagnosis requires professional review and validation',
                                  style: TextStyle(
                                      fontSize: 11, color: AppTheme.mediumRisk),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Current Vitals
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.monitor_heart_outlined,
                                color: AppTheme.highRisk, size: 18),
                            const SizedBox(width: 6),
                            const Text(
                              'Current Vitals',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 2.0,
                          children: [
                            _vitalTile('Heart Rate', '${patient.heartRate}', 'bpm',
                                const Color(0xFFFFF1F2), AppTheme.highRisk),
                            _vitalTile('Blood Pressure', patient.bloodPressure,
                                'mmHg', const Color(0xFFEFF6FF), AppTheme.primaryBlue),
                            _vitalTile('Temperature', '${patient.temperature}',
                                '°F', const Color(0xFFFFFBEB), AppTheme.mediumRisk),
                            _vitalTile('Oxygen Level', '${patient.oxygenLevel}',
                                '%', const Color(0xFFECFDF5), AppTheme.primaryGreen),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Medical History
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined,
                                color: AppTheme.primaryBlue, size: 18),
                            const SizedBox(width: 6),
                            const Text(
                              'Medical History',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...patient.history.map((h) => _historyTile(h)).toList(),
                        if (patient.history.isEmpty)
                          const Text(
                            'No previous medical history',
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.textGrey),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  GradientButton(
                    label: 'Review & Provide Feedback',
                    onPressed: () {},
                    icon: Icons.article_outlined,
                  ),
                  const SizedBox(height: 12),
                  OutlineGradientButton(
                    label: 'Send Message',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ContactDoctorScreen()),
                    ),
                    icon: Icons.chat_bubble_outline_rounded,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
      ],
    );
  }

  Widget _diagStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textGrey)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark)),
      ],
    );
  }

  Widget _vitalTile(
      String label, String value, String unit, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: TextStyle(fontSize: 10, color: color)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color)),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(unit,
                    style: TextStyle(fontSize: 10, color: color)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _historyTile(DiagnosisModel history) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(history.condition,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textDark)),
              Text(history.date,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textGrey)),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'resolved',
                  style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Text('Confidence: ${history.confidence}%',
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.textGrey)),
            ],
          ),
        ],
      ),
    );
  }
}
