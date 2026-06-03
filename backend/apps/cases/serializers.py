"""
apps/cases/serializers.py
──────────────────────────
Serializers for cases, drug recommendations, and prescriptions.
Different serializers for different roles (patient vs doctor).
"""

from rest_framework import serializers
from .models import Case, CaseAttachment, DrugRecommendation, Prescription
from apps.accounts.serializers import UserSerializer, DoctorPublicSerializer


class CaseAttachmentSerializer(serializers.ModelSerializer):
    file_url = serializers.SerializerMethodField()

    class Meta:
        model = CaseAttachment
        fields = ['id', 'file_url', 'file_type', 'filename', 'uploaded_at']

    def get_file_url(self, obj):
        request = self.context.get('request')
        if request and obj.file:
            return request.build_absolute_uri(obj.file.url)
        return None


class DrugRecommendationSerializer(serializers.ModelSerializer):
    """Full drug details — for doctor review."""

    class Meta:
        model = DrugRecommendation
        fields = [
            'id', 'disease', 'drug_name', 'egyptian_brand', 'role',
            'dosage', 'key_side_effects', 'avoid_in',
            'allergy_warning', 'drug_interaction_warning',
            'approval_status', 'doctor_dosage_override', 'doctor_notes',
        ]
        read_only_fields = ['id', 'disease', 'drug_name', 'egyptian_brand']


class DrugRecommendationPatientSerializer(serializers.ModelSerializer):
    """
    Drug details visible to patient ONLY after doctor approval.
    Sensitive dosage/interaction info shown only for approved drugs.
    """
    effective_dosage = serializers.SerializerMethodField()

    class Meta:
        model = DrugRecommendation
        fields = [
            'id', 'drug_name', 'egyptian_brand', 'role',
            'effective_dosage', 'key_side_effects',
            'avoid_in', 'allergy_warning', 'drug_interaction_warning',
        ]

    def get_effective_dosage(self, obj):
        # Doctor override takes priority
        return obj.doctor_dosage_override or obj.dosage


class CaseListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for list views."""
    patient_name = serializers.CharField(source='patient.name', read_only=True)

    class Meta:
        model = Case
        fields = [
            'id', 'case_number', 'patient_name', 'status',
            'predicted_disease', 'prediction_confidence',
            'created_at', 'updated_at',
        ]


class CaseDetailSerializer(serializers.ModelSerializer):
    """Full case detail for doctor review."""
    patient      = UserSerializer(read_only=True)
    attachments  = CaseAttachmentSerializer(many=True, read_only=True)
    drug_recommendations = DrugRecommendationSerializer(many=True, read_only=True)

    class Meta:
        model = Case
        fields = [
            'id', 'case_number', 'patient', 'status',
            'symptoms_raw', 'chief_complaint', 'notes',
            'predicted_disease', 'prediction_confidence', 'top_predictions',
            'doctor_notes', 'doctor_reviewed_at', 'rejection_reason',
            'attachments', 'drug_recommendations',
            'created_at', 'updated_at',
        ]


class CasePatientSerializer(serializers.ModelSerializer):
    """Case view for patients — hides drug details until doctor approves."""
    attachments = CaseAttachmentSerializer(many=True, read_only=True)
    prescription = serializers.SerializerMethodField()

    class Meta:
        model = Case
        fields = [
            'id', 'case_number', 'status',
            'symptoms_raw', 'chief_complaint',
            'predicted_disease', 'prediction_confidence',
            'doctor_notes', 'rejection_reason',
            'attachments', 'prescription',
            'created_at', 'updated_at',
        ]

    def get_prescription(self, obj):
        if obj.status == Case.Status.APPROVED:
            try:
                return PrescriptionPatientSerializer(obj.prescription).data
            except Exception:
                pass
        return None


class SymptomSubmitSerializer(serializers.Serializer):
    """Input for submitting a new case."""
    symptoms        = serializers.ListField(
        child=serializers.CharField(max_length=100),
        min_length=1,
        max_length=50,
    )
    chief_complaint = serializers.CharField(required=False, allow_blank=True, max_length=2000)
    notes           = serializers.CharField(required=False, allow_blank=True, max_length=2000)


class DoctorReviewSerializer(serializers.Serializer):
    """Doctor submits review decision."""
    action           = serializers.ChoiceField(choices=['approve', 'reject'])
    doctor_notes     = serializers.CharField(required=False, allow_blank=True)
    rejection_reason = serializers.CharField(required=False, allow_blank=True)

    # Drug decisions: list of {drug_id, status, dosage_override, notes}
    drug_decisions = serializers.ListField(
        child=serializers.DictField(),
        required=False,
        default=list,
    )
    instructions   = serializers.CharField(required=False, allow_blank=True)
    follow_up_date = serializers.DateField(required=False, allow_null=True)

    def validate(self, data):
        if data['action'] == 'reject' and not data.get('rejection_reason'):
            raise serializers.ValidationError(
                {'rejection_reason': 'Please provide a reason for rejection.'}
            )
        return data


class PrescriptionPatientSerializer(serializers.ModelSerializer):
    """What the patient sees after approval."""
    approved_drugs = DrugRecommendationPatientSerializer(many=True, read_only=True)
    issued_by_name = serializers.CharField(source='issued_by.name', read_only=True)

    class Meta:
        model = Prescription
        fields = [
            'id', 'issued_by_name', 'approved_drugs',
            'instructions', 'follow_up_date', 'issued_at',
        ]


class PrescriptionDoctorSerializer(serializers.ModelSerializer):
    """Full prescription detail for doctor."""
    approved_drugs = DrugRecommendationSerializer(many=True, read_only=True)

    class Meta:
        model = Prescription
        fields = '__all__'
