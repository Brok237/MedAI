// lib/models/user_model.dart

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? avatar;
  final bool isActive;
  final PatientProfile? patientProfile;
  final DoctorProfile? doctorProfile;

  UserModel({required this.id, required this.name, required this.email,
    required this.role, this.avatar, this.isActive = true,
    this.patientProfile, this.doctorProfile});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] ?? '', name: json['name'] ?? '', email: json['email'] ?? '',
    role: json['role'] ?? 'patient', avatar: json['avatar'],
    isActive: json['is_active'] ?? true,
    patientProfile: json['patient_profile'] != null ? PatientProfile.fromJson(json['patient_profile']) : null,
    doctorProfile: json['doctor_profile'] != null ? DoctorProfile.fromJson(json['doctor_profile']) : null,
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email, 'role': role};

  bool get isPatient => role == 'patient';
  bool get isDoctor  => role == 'doctor';
  bool get isAdmin   => role == 'admin';
}

class PatientProfile {
  final int? age; final String? gender; final String? bloodType;
  final String? phone; final String? chronicDiseases; final String? allergies;
  PatientProfile({this.age, this.gender, this.bloodType, this.phone, this.chronicDiseases, this.allergies});
  factory PatientProfile.fromJson(Map<String, dynamic> json) => PatientProfile(
    age: json['age'], gender: json['gender'], bloodType: json['blood_type'],
    phone: json['phone'], chronicDiseases: json['chronic_diseases'], allergies: json['allergies']);
}

class DoctorProfile {
  final String specialization; final String? hospital;
  final String status; final int totalCasesReviewed;
  DoctorProfile({required this.specialization, this.hospital, required this.status, this.totalCasesReviewed = 0});
  factory DoctorProfile.fromJson(Map<String, dynamic> json) => DoctorProfile(
    specialization: json['specialization'] ?? '', hospital: json['hospital'],
    status: json['status'] ?? 'pending', totalCasesReviewed: json['total_cases_reviewed'] ?? 0);
  bool get isApproved => status == 'approved';
}
