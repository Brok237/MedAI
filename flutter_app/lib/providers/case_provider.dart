// lib/providers/case_provider.dart

import 'package:flutter/foundation.dart';
import '../models/case_model.dart';
import '../services/case_service.dart';

class CaseProvider extends ChangeNotifier {
  List<CaseModel> _cases    = [];
  CaseModel?      _selected;
  bool            _loading  = false;
  String?         _error;

  List<CaseModel> get cases    => _cases;
  CaseModel?      get selected => _selected;
  bool            get loading  => _loading;
  String?         get error    => _error;

  // ── Load patient cases ────────────────────────────────────────────────────

  Future<void> loadMyCases() async {
    _loading = true;
    _error   = null;
    notifyListeners();
    try {
      _cases = await CaseService.getMyCases();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Load single case ──────────────────────────────────────────────────────

  Future<void> loadCaseDetail(String caseId) async {
    _loading = true;
    notifyListeners();
    try {
      _selected = await CaseService.getCaseDetail(caseId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Submit new case ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> submitCase({
    required List<String> symptoms,
    String? chiefComplaint,
    String? notes,
  }) async {
    _loading = true;
    _error   = null;
    notifyListeners();
    try {
      final result = await CaseService.submitCase(
        symptoms: symptoms,
        chiefComplaint: chiefComplaint,
        notes: notes,
      );
      await loadMyCases();
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
