// lib/models/case_model.dart

class CaseModel {
  final String id;
  final String caseNumber;
  final String status;
  final List<String> symptomsRaw;
  final String? chiefComplaint;
  final String? predictedDisease;
  final double? predictionConfidence;
  final String? doctorNotes;
  final String? rejectionReason;
  final PrescriptionModel? prescription;
  final DateTime createdAt;
  final DateTime updatedAt;

  CaseModel({
    required this.id,
    required this.caseNumber,
    required this.status,
    required this.symptomsRaw,
    this.chiefComplaint,
    this.predictedDisease,
    this.predictionConfidence,
    this.doctorNotes,
    this.rejectionReason,
    this.prescription,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      id: json['id'] ?? '',
      caseNumber: json['case_number'] ?? '',
      status: json['status'] ?? '',
      symptomsRaw: List<String>.from(json['symptoms_raw'] ?? []),
      chiefComplaint: json['chief_complaint'],
      predictedDisease: json['predicted_disease'],
      predictionConfidence: json['prediction_confidence']?.toDouble(),
      doctorNotes: json['doctor_notes'],
      rejectionReason: json['rejection_reason'],
      prescription: json['prescription'] != null
          ? PrescriptionModel.fromJson(json['prescription'])
          : null,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pending_prediction': return 'Analyzing Symptoms...';
      case 'prediction_ready':   return 'Awaiting Doctor Review';
      case 'under_review':       return 'Under Review';
      case 'approved':           return 'Prescription Ready ✓';
      case 'rejected':           return 'Needs Resubmission';
      case 'closed':             return 'Closed';
      default:                   return status;
    }
  }

  bool get isPending   => status == 'pending_prediction' || status == 'prediction_ready';
  bool get isApproved  => status == 'approved';
  bool get isRejected  => status == 'rejected';
  bool get isUnderReview => status == 'under_review';
}

class DrugRecommendation {
  final String id;
  final String drugName;
  final String? egyptianBrand;
  final String? role;
  final String? dosage;
  final String? effectiveDosage;
  final String? keySideEffects;
  final String? avoidIn;
  final String? allergyWarning;
  final String? drugInteractionWarning;
  final String approvalStatus;

  DrugRecommendation({
    required this.id,
    required this.drugName,
    this.egyptianBrand,
    this.role,
    this.dosage,
    this.effectiveDosage,
    this.keySideEffects,
    this.avoidIn,
    this.allergyWarning,
    this.drugInteractionWarning,
    this.approvalStatus = 'pending',
  });

  factory DrugRecommendation.fromJson(Map<String, dynamic> json) {
    return DrugRecommendation(
      id: json['id'] ?? '',
      drugName: json['drug_name'] ?? '',
      egyptianBrand: json['egyptian_brand'],
      role: json['role'],
      dosage: json['dosage'],
      effectiveDosage: json['effective_dosage'],
      keySideEffects: json['key_side_effects'],
      avoidIn: json['avoid_in'],
      allergyWarning: json['allergy_warning'],
      drugInteractionWarning: json['drug_interaction_warning'],
      approvalStatus: json['approval_status'] ?? 'pending',
    );
  }
}

class PrescriptionModel {
  final String id;
  final String? issuedByName;
  final List<DrugRecommendation> approvedDrugs;
  final String? instructions;
  final String? followUpDate;
  final DateTime issuedAt;

  PrescriptionModel({
    required this.id,
    this.issuedByName,
    required this.approvedDrugs,
    this.instructions,
    this.followUpDate,
    required this.issuedAt,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['id'] ?? '',
      issuedByName: json['issued_by_name'],
      approvedDrugs: (json['approved_drugs'] as List<dynamic>? ?? [])
          .map((d) => DrugRecommendation.fromJson(d))
          .toList(),
      instructions: json['instructions'],
      followUpDate: json['follow_up_date'],
      issuedAt: DateTime.parse(json['issued_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  NotificationModel({
    required this.id, required this.type, required this.title,
    required this.message, required this.isRead, this.data, required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id: json['id'] ?? '', type: json['type'] ?? '', title: json['title'] ?? '',
    message: json['message'] ?? '', isRead: json['is_read'] ?? false,
    data: json['data'], createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
  );
}
