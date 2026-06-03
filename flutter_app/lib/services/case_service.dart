// lib/services/case_service.dart
// Connects to Django /api/v1/cases/ endpoints

import 'dart:io';
import '../models/case_model.dart';
import 'api_client.dart';

class CaseService {
  // ── Submit symptoms ───────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> submitCase({
    required List<String> symptoms,
    String? chiefComplaint,
    String? notes,
  }) async {
    return ApiClient.post('/cases/submit/', {
      'symptoms': symptoms,
      if (chiefComplaint != null && chiefComplaint.isNotEmpty)
        'chief_complaint': chiefComplaint,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
  }

  // ── Patient: own cases ────────────────────────────────────────────────────

  static Future<List<CaseModel>> getMyCases() async {
    final response = await ApiClient.get('/cases/my/');
    final results = response['results'] as List<dynamic>? ?? [];
    return results.map((j) => CaseModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<CaseModel> getCaseDetail(String caseId) async {
    final response = await ApiClient.get('/cases/my/$caseId/');
    return CaseModel.fromJson(response);
  }

  // ── Upload file to case ───────────────────────────────────────────────────

  static Future<Map<String, dynamic>> uploadAttachment({
    required String caseId,
    required File file,
    String fileType = 'other',
  }) async {
    return ApiClient.uploadFile(
      '/cases/my/$caseId/upload/',
      file: file,
      fieldName: 'file',
      fields: {'file_type': fileType},
    );
  }

  // ── Get prescription ──────────────────────────────────────────────────────

  static Future<PrescriptionModel> getPrescription(String caseId) async {
    final response = await ApiClient.get('/cases/my/$caseId/prescription/');
    return PrescriptionModel.fromJson(response);
  }

  // ── Doctor: case queue ────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getDoctorQueue() async {
    final response = await ApiClient.get('/cases/queue/');
    return List<Map<String, dynamic>>.from(response['results'] ?? []);
  }

  static Future<Map<String, dynamic>> getCaseForReview(String caseId) async {
    return ApiClient.get('/cases/$caseId/review/');
  }

  static Future<Map<String, dynamic>> submitDecision({
    required String caseId,
    required String action,   // 'approve' or 'reject'
    String? doctorNotes,
    String? rejectionReason,
    List<Map<String, dynamic>> drugDecisions = const [],
    String? instructions,
    String? followUpDate,
  }) async {
    return ApiClient.post('/cases/$caseId/decision/', {
      'action': action,
      if (doctorNotes != null) 'doctor_notes': doctorNotes,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
      'drug_decisions': drugDecisions,
      if (instructions != null) 'instructions': instructions,
      if (followUpDate != null) 'follow_up_date': followUpDate,
    });
  }
}
