"""
apps/cases/views.py
────────────────────
Views implementing the full case workflow:

Patient endpoints:
  POST   /api/v1/cases/submit/            – submit symptoms → trigger ML
  GET    /api/v1/cases/                   – patient's own cases
  GET    /api/v1/cases/<id>/              – case detail
  POST   /api/v1/cases/<id>/attachments/  – upload files

Doctor endpoints:
  GET    /api/v1/cases/queue/             – cases awaiting review
  GET    /api/v1/cases/<id>/review/       – full case for review
  POST   /api/v1/cases/<id>/decision/     – approve or reject

Admin endpoints:
  GET    /api/v1/cases/admin/all/         – all cases
  GET    /api/v1/cases/admin/stats/       – dashboard stats
"""

import logging
from django.utils import timezone
from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser

from .models import Case, CaseAttachment, DrugRecommendation, Prescription
from .serializers import (
    SymptomSubmitSerializer,
    CaseDetailSerializer,
    CaseListSerializer,
    CasePatientSerializer,
    CaseAttachmentSerializer,
    DoctorReviewSerializer,
    PrescriptionPatientSerializer,
)
from .ml_client import ml_client, MLServiceError
from apps.accounts.permissions import IsPatient, IsDoctor, IsAdminUser, IsDoctorOrAdmin
from apps.notifications.tasks import (
    notify_doctors_new_case,
    notify_patient_case_approved,
    notify_patient_case_rejected,
)

logger = logging.getLogger(__name__)


# ── Patient: Submit Case ──────────────────────────────────────────────────────

class SubmitCaseView(APIView):
    """
    Patient submits symptoms.
    1. Create Case record
    2. Call FastAPI ML service
    3. Store predictions + drug recommendations
    4. Notify available doctors
    """
    permission_classes = [IsAuthenticated, IsPatient]

    def post(self, request):
        serializer = SymptomSubmitSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        symptoms        = serializer.validated_data['symptoms']
        chief_complaint = serializer.validated_data.get('chief_complaint', '')
        notes           = serializer.validated_data.get('notes', '')

        # Create case
        case = Case.objects.create(
            patient=request.user,
            symptoms_raw=symptoms,
            chief_complaint=chief_complaint,
            notes=notes,
            status=Case.Status.PENDING_PREDICTION,
        )

        # Call ML service
        try:
            ml_response = ml_client.predict(symptoms)

            # Store predictions — FastAPI returns: predicted_disease, confidence, recommended_drugs
            case.predicted_disease      = ml_response.get('predicted_disease', '')
            case.prediction_confidence  = ml_response.get('confidence', None)
            case.top_predictions        = []   # single prediction model; no top-3 list
            case.ml_raw_response        = ml_response
            case.status = Case.Status.PREDICTION_READY
            case.save()

            # Store drug recommendations
            drug_rows = ml_response.get('recommended_drugs', [])
            for row in drug_rows:
                # FastAPI returns keys like 'Egyptian_Brand', 'Key_Side_Effects'
                # (underscores, from the Pydantic model). Handle both formats.
                DrugRecommendation.objects.create(
                    case=case,
                    disease=row.get('Disease', ''),
                    drug_name=row.get('Drug', ''),
                    egyptian_brand=row.get('Egyptian_Brand') or row.get('Egyptian Brand', ''),
                    role=row.get('Role', ''),
                    dosage=row.get('Dosage', ''),
                    key_side_effects=row.get('Key_Side_Effects') or row.get('Key Side Effects', ''),
                    avoid_in=row.get('Avoid_In') or row.get('Avoid In', ''),
                    allergy_warning=row.get('Allergy_Warning') or row.get('Allergy Warning', ''),
                    drug_interaction_warning=row.get('Drug_Interaction_Warning') or row.get('Drug Interaction Warning', ''),
                )

            # Notify doctors
            try:
                notify_doctors_new_case.delay(str(case.id))
            except Exception:
                pass

            return Response({
                'message': 'Case submitted. Awaiting doctor review.',
                'case_id': str(case.id),
                'case_number': case.case_number,
                'status': case.status,
                'predicted_disease': case.predicted_disease,
                'confidence': case.prediction_confidence,
            }, status=status.HTTP_201_CREATED)

        except MLServiceError as e:
            # ML failed — keep case open, flag it
            case.status = Case.Status.PENDING_PREDICTION
            case.notes  = (case.notes or '') + f'\n[ML Error]: {str(e)}'
            case.save()
            return Response({
                'message': 'Case created but prediction failed. Our team will follow up.',
                'case_id': str(case.id),
                'case_number': case.case_number,
                'error': str(e),
            }, status=status.HTTP_202_ACCEPTED)


# ── Patient: Own Cases ────────────────────────────────────────────────────────

class PatientCaseListView(APIView):
    """List the current patient's cases."""
    permission_classes = [IsAuthenticated, IsPatient]

    def get(self, request):
        cases = Case.objects.filter(patient=request.user).order_by('-created_at')
        serializer = CaseListSerializer(cases, many=True)
        return Response({'results': serializer.data, 'count': cases.count()})


class PatientCaseDetailView(APIView):
    """Full case detail for the owning patient."""
    permission_classes = [IsAuthenticated, IsPatient]

    def get(self, request, case_id):
        case = get_object_or_404(Case, id=case_id, patient=request.user)
        return Response(CasePatientSerializer(case, context={'request': request}).data)


class CaseAttachmentUploadView(APIView):
    """Patient uploads a file to a case."""
    permission_classes = [IsAuthenticated, IsPatient]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request, case_id):
        case = get_object_or_404(Case, id=case_id, patient=request.user)

        # Prevent uploads on closed/approved cases
        if case.status in [Case.Status.APPROVED, Case.Status.CLOSED]:
            return Response(
                {'error': 'Cannot upload files to a closed or approved case.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        file      = request.FILES.get('file')
        file_type = request.data.get('file_type', CaseAttachment.FileType.OTHER)

        if not file:
            return Response({'error': 'No file provided.'}, status=status.HTTP_400_BAD_REQUEST)

        attachment = CaseAttachment.objects.create(
            case=case,
            file=file,
            file_type=file_type,
            filename=file.name,
        )
        return Response(
            CaseAttachmentSerializer(attachment, context={'request': request}).data,
            status=status.HTTP_201_CREATED
        )


# ── Doctor: Case Queue ────────────────────────────────────────────────────────

class DoctorCaseQueueView(APIView):
    """
    Returns cases awaiting doctor review.
    Doctors see all prediction-ready cases (not assigned to another doctor).
    """
    permission_classes = [IsAuthenticated, IsDoctor]

    def get(self, request):
        status_filter = request.query_params.get('status', None)

        qs = Case.objects.filter(
            status__in=[
                Case.Status.PREDICTION_READY,
                Case.Status.UNDER_REVIEW,
            ]
        ).select_related('patient').order_by('-created_at')

        if status_filter:
            qs = qs.filter(status=status_filter)

        # Also include cases this doctor already claimed
        my_cases = Case.objects.filter(
            assigned_doctor=request.user
        ).exclude(status__in=[Case.Status.APPROVED, Case.Status.CLOSED])

        all_cases = (qs | my_cases).distinct()
        serializer = CaseListSerializer(all_cases, many=True)
        return Response({'results': serializer.data, 'count': all_cases.count()})


class DoctorCaseDetailView(APIView):
    """Full case detail for a doctor reviewing it."""
    permission_classes = [IsAuthenticated, IsDoctorOrAdmin]

    def get(self, request, case_id):
        case = get_object_or_404(Case, id=case_id)
        # Auto-assign to this doctor if unassigned
        if not case.assigned_doctor and request.user.is_doctor:
            case.assigned_doctor = request.user
            case.status = Case.Status.UNDER_REVIEW
            case.save(update_fields=['assigned_doctor', 'status'])

        return Response(
            CaseDetailSerializer(case, context={'request': request}).data
        )


class DoctorCaseDecisionView(APIView):
    """
    Doctor approves or rejects a case.
    On approval: creates Prescription with selected drugs.
    """
    permission_classes = [IsAuthenticated, IsDoctor]

    def post(self, request, case_id):
        case = get_object_or_404(Case, id=case_id)

        # Only the assigned doctor (or any doctor if unassigned) can act
        if case.assigned_doctor and case.assigned_doctor != request.user:
            return Response(
                {'error': 'This case is assigned to another doctor.'},
                status=status.HTTP_403_FORBIDDEN
            )

        serializer = DoctorReviewSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data   = serializer.validated_data
        action = data['action']

        case.assigned_doctor    = request.user
        case.doctor_notes       = data.get('doctor_notes', '')
        case.doctor_reviewed_at = timezone.now()

        if action == 'approve':
            # Process drug decisions
            drug_decisions = data.get('drug_decisions', [])
            approved_drug_ids = []

            for decision in drug_decisions:
                drug_id = decision.get('drug_id')
                dec_status = decision.get('status', 'approved')
                try:
                    drug = DrugRecommendation.objects.get(id=drug_id, case=case)
                    drug.approval_status = dec_status
                    drug.doctor_dosage_override = decision.get('dosage_override', '')
                    drug.doctor_notes = decision.get('notes', '')
                    drug.save()
                    if dec_status == 'approved':
                        approved_drug_ids.append(drug.id)
                except DrugRecommendation.DoesNotExist:
                    pass

            # Create prescription
            prescription, _ = Prescription.objects.get_or_create(
                case=case,
                defaults={
                    'issued_by': request.user,
                    'instructions': data.get('instructions', ''),
                    'follow_up_date': data.get('follow_up_date', None),
                }
            )
            if approved_drug_ids:
                prescription.approved_drugs.set(
                    DrugRecommendation.objects.filter(id__in=approved_drug_ids)
                )
            prescription.instructions = data.get('instructions', '')
            prescription.follow_up_date = data.get('follow_up_date', None)
            prescription.save()

            case.status = Case.Status.APPROVED
            case.save()

            # Update doctor stats
            try:
                request.user.doctor_profile.total_cases_reviewed += 1
                request.user.doctor_profile.save(update_fields=['total_cases_reviewed'])
            except Exception:
                pass

            try:
                notify_patient_case_approved.delay(str(case.id))
            except Exception:
                pass

            return Response({
                'message': 'Case approved and prescription issued.',
                'case_number': case.case_number,
                'prescription_id': str(prescription.id),
            })

        elif action == 'reject':
            case.status = Case.Status.REJECTED
            case.rejection_reason = data.get('rejection_reason', '')
            case.save()

            try:
                notify_patient_case_rejected.delay(str(case.id))
            except Exception:
                pass

            return Response({
                'message': 'Case rejected.',
                'case_number': case.case_number,
            })


# ── Patient: Prescription ─────────────────────────────────────────────────────

class PatientPrescriptionView(APIView):
    """Patient retrieves their approved prescription."""
    permission_classes = [IsAuthenticated, IsPatient]

    def get(self, request, case_id):
        case = get_object_or_404(Case, id=case_id, patient=request.user)

        if case.status != Case.Status.APPROVED:
            return Response({
                'message': 'Prescription not yet available.',
                'status': case.status,
            }, status=status.HTTP_404_NOT_FOUND)

        try:
            prescription = case.prescription
        except Prescription.DoesNotExist:
            return Response({'error': 'Prescription not found.'}, status=status.HTTP_404_NOT_FOUND)

        return Response(PrescriptionPatientSerializer(prescription).data)


# ── Admin: All Cases ──────────────────────────────────────────────────────────

class AdminCaseListView(APIView):
    """Admin views all cases with optional filters."""
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get(self, request):
        status_filter = request.query_params.get('status', None)
        qs = Case.objects.select_related('patient', 'assigned_doctor').order_by('-created_at')
        if status_filter:
            qs = qs.filter(status=status_filter)
        serializer = CaseListSerializer(qs, many=True)
        return Response({'results': serializer.data, 'count': qs.count()})


class AdminDashboardStatsView(APIView):
    """Admin: high-level platform statistics."""
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get(self, request):
        from django.contrib.auth import get_user_model
        from apps.accounts.models import DoctorProfile
        User = get_user_model()

        return Response({
            'total_patients':      User.objects.filter(role='patient').count(),
            'total_doctors':       User.objects.filter(role='doctor').count(),
            'pending_doctors':     DoctorProfile.objects.filter(status='pending').count(),
            'total_cases':         Case.objects.count(),
            'pending_cases':       Case.objects.filter(status=Case.Status.PREDICTION_READY).count(),
            'approved_cases':      Case.objects.filter(status=Case.Status.APPROVED).count(),
            'rejected_cases':      Case.objects.filter(status=Case.Status.REJECTED).count(),
            'under_review_cases':  Case.objects.filter(status=Case.Status.UNDER_REVIEW).count(),
        })
