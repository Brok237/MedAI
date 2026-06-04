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

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatar,
    this.isActive = true,
    this.patientProfile,
    this.doctorProfile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        role: json['role'] ?? 'patient',
        avatar: json['avatar'],
        isActive: json['is_active'] ?? true,
        patientProfile: json['patient_profile'] != null
            ? PatientProfile.fromJson(json['patient_profile'])
            : null,
        doctorProfile: json['doctor_profile'] != null
            ? DoctorProfile.fromJson(json['doctor_profile'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'avatar': avatar,
        'is_active': isActive,
        'patient_profile': patientProfile?.toJson(),
        'doctor_profile': doctorProfile?.toJson(),
      };

  bool get isPatient => role == 'patient';
  bool get isDoctor => role == 'doctor';
  bool get isAdmin => role == 'admin';
}

class PatientProfile {
  final int? age;
  final String? gender;
  final String? bloodType;
  final String? phone;
  final String? address;
  final String? chronicDiseases;
  final String? allergies;
  final String? currentMeds;
  final String? weightKg;
  final String? heightCm;

  PatientProfile({
    this.age,
    this.gender,
    this.bloodType,
    this.phone,
    this.address,
    this.chronicDiseases,
    this.allergies,
    this.currentMeds,
    this.weightKg,
    this.heightCm,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) => PatientProfile(
        age: json['age'],
        gender: json['gender'],
        bloodType: json['blood_type'],
        phone: json['phone'],
        address: json['address'],
        chronicDiseases: json['chronic_diseases'],
        allergies: json['allergies'],
        currentMeds: json['current_meds'],
        weightKg: json['weight_kg']?.toString(),
        heightCm: json['height_cm']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'age': age,
        'gender': gender,
        'blood_type': bloodType,
        'phone': phone,
        'address': address,
        'chronic_diseases': chronicDiseases,
        'allergies': allergies,
        'current_meds': currentMeds,
        'weight_kg': weightKg,
        'height_cm': heightCm,
      };
}

class DoctorProfile {
  final String specialization;
  final String? hospital;
  final String status;
  final int totalCasesReviewed;

  DoctorProfile({
    required this.specialization,
    this.hospital,
    required this.status,
    this.totalCasesReviewed = 0,
  });

  factory DoctorProfile.fromJson(Map<String, dynamic> json) => DoctorProfile(
        specialization: json['specialization'] ?? '',
        hospital: json['hospital'],
        status: json['status'] ?? 'pending',
        totalCasesReviewed: json['total_cases_reviewed'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'specialization': specialization,
        'hospital': hospital,
        'status': status,
        'total_cases_reviewed': totalCasesReviewed,
      };

  bool get isApproved => status == 'approved';
}
