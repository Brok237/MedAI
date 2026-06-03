// lib/models/dummy_data.dart

class UserMode {
  final String name;
  final String email;
  final String role; // 'patient' or 'doctor'
  final String initials;

  UserMode({
    required this.name,
    required this.email,
    required this.role,
    required this.initials,
  });
}

class DiagnosisModel {
  final String condition;
  final String date;
  final String riskLevel; // 'Low', 'Medium', 'High'
  final int confidence;
  final String symptoms;
  final int durationDays;
  final String status; // 'Ongoing', 'Resolved'

  DiagnosisModel({
    required this.condition,
    required this.date,
    required this.riskLevel,
    required this.confidence,
    required this.symptoms,
    required this.durationDays,
    required this.status,
  });
}

class PatientModel {
  final String name;
  final String initials;
  final int age;
  final String status; // 'Stable', 'At risk', 'Critical'
  final String lastDiagnosis;
  final int aiConfidence;
  final String updatedDate;
  final String phone;
  final String email;
  final String gender;
  final String bloodType;
  final String patientId;
  final int heartRate;
  final String bloodPressure;
  final double temperature;
  final int oxygenLevel;
  final List<DiagnosisModel> history;

  PatientModel({
    required this.name,
    required this.initials,
    required this.age,
    required this.status,
    required this.lastDiagnosis,
    required this.aiConfidence,
    required this.updatedDate,
    required this.phone,
    required this.email,
    required this.gender,
    required this.bloodType,
    required this.patientId,
    required this.heartRate,
    required this.bloodPressure,
    required this.temperature,
    required this.oxygenLevel,
    required this.history,
  });
}

class VitalsModel {
  final int heartRate;
  final String bloodPressure;
  final double temperature;
  final int oxygenLevel;

  VitalsModel({
    required this.heartRate,
    required this.bloodPressure,
    required this.temperature,
    required this.oxygenLevel,
  });
}

// ─── Dummy Data ───────────────────────────────────────────────────────────────

class DummyData {
  static final UserMode patientUser = UserMode(
    name: 'John Doe',
    email: 'john@gmail.com',
    role: 'patient',
    initials: 'JD',
  );

  static final UserMode doctorUser = UserMode(
    name: 'John Doe',
    email: 'john@gmail.com',
    role: 'doctor',
    initials: 'JD',
  );

  static final VitalsModel currentVitals = VitalsModel(
    heartRate: 72,
    bloodPressure: '120/80',
    temperature: 98.6,
    oxygenLevel: 98,
  );

  static final VitalsModel liveVitals = VitalsModel(
    heartRate: 76,
    bloodPressure: '123/83',
    temperature: 98.6,
    oxygenLevel: 98,
  );

  static final DiagnosisModel recentDiagnosis = DiagnosisModel(
    condition: 'Seasonal Allergies',
    date: 'Dec 20, 2024',
    riskLevel: 'Medium',
    confidence: 87,
    symptoms: 'Sneezing, runny nose, itchy eyes',
    durationDays: 3,
    status: 'Ongoing',
  );

  static final List<DiagnosisModel> medicalHistory = [
    DiagnosisModel(
      condition: 'Seasonal Allergies',
      date: 'Dec 20, 2024',
      riskLevel: 'Medium',
      confidence: 87,
      symptoms: 'Sneezing, runny nose, itchy eyes',
      durationDays: 3,
      status: 'Ongoing',
    ),
    DiagnosisModel(
      condition: 'Common Cold',
      date: 'Dec 10, 2024',
      riskLevel: 'Low',
      confidence: 91,
      symptoms: 'Sore throat, mild cough, fatigue',
      durationDays: 5,
      status: 'Resolved',
    ),
    DiagnosisModel(
      condition: 'Migraine',
      date: 'Nov 28, 2024',
      riskLevel: 'Medium',
      confidence: 84,
      symptoms: 'Severe headache, nausea, light sensitivity',
      durationDays: 2,
      status: 'Resolved',
    ),
    DiagnosisModel(
      condition: 'Back Pain',
      date: 'Nov 5, 2024',
      riskLevel: 'Low',
      confidence: 79,
      symptoms: 'Lower back pain, stiffness',
      durationDays: 7,
      status: 'Resolved',
    ),
  ];

  static final List<Map<String, dynamic>> aiDiagnosisResults = [
    {
      'condition': 'Seasonal Allergies',
      'riskLevel': 'Medium',
      'isMostLikely': true,
      'confidence': 87,
    },
    {
      'condition': 'Common Cold',
      'riskLevel': 'Low',
      'isMostLikely': false,
      'confidence': 70,
    },
    {
      'condition': 'Sinusitis',
      'riskLevel': 'Low',
      'isMostLikely': false,
      'confidence': 64,
    },
  ];

  static final List<PatientModel> patients = [
    PatientModel(
      name: 'John Doe',
      initials: 'JD',
      age: 45,
      status: 'Stable',
      lastDiagnosis: 'Seasonal Allergies',
      aiConfidence: 87,
      updatedDate: '12/26/2024',
      phone: '+1 (555) 234-5678',
      email: 'john.doe@email.com',
      gender: 'Male',
      bloodType: 'A+',
      patientId: 'PT-000002',
      heartRate: 72,
      bloodPressure: '120/80',
      temperature: 98.6,
      oxygenLevel: 98,
      history: [
        DiagnosisModel(
          condition: 'Common Cold',
          date: '11/15/2024',
          riskLevel: 'Low',
          confidence: 89,
          symptoms: 'Sore throat, cough',
          durationDays: 4,
          status: 'Resolved',
        ),
      ],
    ),
    PatientModel(
      name: 'Emma Wilson',
      initials: 'EW',
      age: 32,
      status: 'At risk',
      lastDiagnosis: 'Acute Bronchitis',
      aiConfidence: 82,
      updatedDate: '12/26/2024',
      phone: '+1 (555) 123-4567',
      email: 'emma.wilson@email.com',
      gender: 'Female',
      bloodType: 'O+',
      patientId: 'PT-000001',
      heartRate: 88,
      bloodPressure: '130/85',
      temperature: 99.2,
      oxygenLevel: 96,
      history: [
        DiagnosisModel(
          condition: 'Common Cold',
          date: '11/15/2024',
          riskLevel: 'Low',
          confidence: 89,
          symptoms: 'Sore throat, mild cough',
          durationDays: 4,
          status: 'Resolved',
        ),
        DiagnosisModel(
          condition: 'Seasonal Allergies',
          date: '9/20/2024',
          riskLevel: 'Low',
          confidence: 91,
          symptoms: 'Sneezing, itchy eyes',
          durationDays: 5,
          status: 'Resolved',
        ),
      ],
    ),
    PatientModel(
      name: 'Michael Chen',
      initials: 'MC',
      age: 58,
      status: 'Stable',
      lastDiagnosis: 'Type 2 Diabetes Management',
      aiConfidence: 91,
      updatedDate: '12/25/2024',
      phone: '+1 (555) 345-6789',
      email: 'michael.chen@email.com',
      gender: 'Male',
      bloodType: 'B+',
      patientId: 'PT-000003',
      heartRate: 80,
      bloodPressure: '128/82',
      temperature: 98.4,
      oxygenLevel: 97,
      history: [],
    ),
    PatientModel(
      name: 'Sarah Johnson',
      initials: 'SJ',
      age: 28,
      status: 'Stable',
      lastDiagnosis: 'Common Cold',
      aiConfidence: 89,
      updatedDate: '12/25/2024',
      phone: '+1 (555) 456-7890',
      email: 'sarah.johnson@email.com',
      gender: 'Female',
      bloodType: 'AB+',
      patientId: 'PT-000004',
      heartRate: 68,
      bloodPressure: '115/75',
      temperature: 98.2,
      oxygenLevel: 99,
      history: [],
    ),
    PatientModel(
      name: 'Robert Davis',
      initials: 'RD',
      age: 67,
      status: 'Critical',
      lastDiagnosis: 'Cardiac Arrhythmia',
      aiConfidence: 76,
      updatedDate: '12/26/2024',
      phone: '+1 (555) 567-8901',
      email: 'robert.davis@email.com',
      gender: 'Male',
      bloodType: 'A-',
      patientId: 'PT-000005',
      heartRate: 102,
      bloodPressure: '145/95',
      temperature: 99.8,
      oxygenLevel: 93,
      history: [],
    ),
  ];

  static final List<Map<String, String>> chatMessages = [
    {
      'sender': 'doctor',
      'message': "Hello! I've reviewed your recent diagnosis. How are you feeling today?",
      'time': '09:30 AM',
    },
    {
      'sender': 'patient',
      'message': "Hi Dr. Smith, I'm feeling better. The medications you recommended are helping.",
      'time': '09:35 AM',
    },
    {
      'sender': 'doctor',
      'message': "That's great to hear! Continue the treatment for another 3-5 days. Let me know if symptoms persist.",
      'time': '09:40 AM',
    },
    {
      'sender': 'patient',
      'message': 'Will do. Thank you, doctor!',
      'time': '09:42 AM',
    },
  ];

  static const List<String> healthTips = [
    '💧 Stay hydrated throughout the day',
    '🥗 Maintain a balanced diet with fresh vegetables',
    '🏃 Exercise for at least 30 minutes daily',
    '😴 Get 7-8 hours of quality sleep',
  ];

  static final List<Map<String, dynamic>> heartRateTrend = [
    {'time': '10:00', 'value': 72},
    {'time': '10:05', 'value': 75},
    {'time': '10:10', 'value': 73},
    {'time': '10:15', 'value': 70},
    {'time': '10:20', 'value': 74},
    {'time': '10:25', 'value': 76},
  ];
}
