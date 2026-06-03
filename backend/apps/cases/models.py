"""
apps/cases/models.py
─────────────────────
Core models for the case/prediction/prescription workflow.

Flow:
  Patient submits symptoms (Case created)
      → FastAPI ML service predicts disease + suggests drugs
      → Doctor reviews and approves/rejects
      → Patient sees approved prescription
"""

import uuid
from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()


class Case(models.Model):
    """
    A patient case: from symptom submission to approved prescription.
    """

    class Status(models.TextChoices):
        PENDING_PREDICTION = 'pending_prediction', 'Pending ML Prediction'
        PREDICTION_READY   = 'prediction_ready',   'Prediction Ready (Awaiting Doctor)'
        UNDER_REVIEW       = 'under_review',        'Under Doctor Review'
        APPROVED           = 'approved',            'Prescription Approved'
        REJECTED           = 'rejected',            'Rejected by Doctor'
        CLOSED             = 'closed',              'Closed'

    # ── Identifiers ───────────────────────────────────────────────────────
    id      = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    case_number = models.CharField(max_length=20, unique=True, editable=False)

    # ── Relationships ─────────────────────────────────────────────────────
    patient = models.ForeignKey(
        User, on_delete=models.CASCADE,
        related_name='cases',
        limit_choices_to={'role': 'patient'}
    )
    assigned_doctor = models.ForeignKey(
        User, on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='assigned_cases',
        limit_choices_to={'role': 'doctor'}
    )

    # ── Status ────────────────────────────────────────────────────────────
    status = models.CharField(
        max_length=30,
        choices=Status.choices,
        default=Status.PENDING_PREDICTION
    )

    # ── Patient input ─────────────────────────────────────────────────────
    symptoms_raw    = models.JSONField(help_text='List of selected symptom strings')
    chief_complaint = models.TextField(null=True, blank=True,
                                       help_text='Patient-written description in natural language')
    notes           = models.TextField(null=True, blank=True)

    # ── ML Prediction (filled after FastAPI call) ─────────────────────────
    predicted_disease = models.CharField(max_length=200, null=True, blank=True)
    prediction_confidence = models.FloatField(null=True, blank=True)
    top_predictions   = models.JSONField(null=True, blank=True,
                                         help_text='[{disease, confidence}] top-3 predictions')
    ml_raw_response   = models.JSONField(null=True, blank=True,
                                         help_text='Full response from FastAPI service')

    # ── Doctor review ─────────────────────────────────────────────────────
    doctor_notes           = models.TextField(null=True, blank=True)
    doctor_reviewed_at     = models.DateTimeField(null=True, blank=True)
    rejection_reason       = models.TextField(null=True, blank=True)

    # ── Timestamps ────────────────────────────────────────────────────────
    created_at  = models.DateTimeField(auto_now_add=True)
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Case'
        verbose_name_plural = 'Cases'

    def __str__(self):
        return f'Case {self.case_number} – {self.patient.name} [{self.status}]'

    def save(self, *args, **kwargs):
        if not self.case_number:
            self.case_number = self._generate_case_number()
        super().save(*args, **kwargs)

    def _generate_case_number(self):
        from django.utils import timezone
        count = Case.objects.count() + 1
        return f'MED-{timezone.now().year}-{count:05d}'


class CaseAttachment(models.Model):
    """Files uploaded by the patient for a case (images, PDFs)."""

    class FileType(models.TextChoices):
        IMAGE       = 'image',       'Image'
        PDF         = 'pdf',         'PDF'
        PRESCRIPTION = 'prescription', 'Prescription Scan'
        LAB_RESULT  = 'lab_result',  'Lab Result'
        OTHER       = 'other',       'Other'

    id       = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    case     = models.ForeignKey(Case, on_delete=models.CASCADE, related_name='attachments')
    file     = models.FileField(upload_to='case_attachments/%Y/%m/')
    file_type = models.CharField(max_length=20, choices=FileType.choices, default=FileType.OTHER)
    filename = models.CharField(max_length=255)
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'{self.filename} – {self.case.case_number}'


class DrugRecommendation(models.Model):
    """
    Individual drug recommendation returned by the ML service.
    The doctor selects which ones to approve.
    """

    class ApprovalStatus(models.TextChoices):
        PENDING  = 'pending',  'Pending Review'
        APPROVED = 'approved', 'Approved by Doctor'
        REJECTED = 'rejected', 'Rejected by Doctor'

    id   = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    case = models.ForeignKey(Case, on_delete=models.CASCADE, related_name='drug_recommendations')

    # ── Drug info (from CSV) ──────────────────────────────────────────────
    disease          = models.CharField(max_length=200)
    drug_name        = models.CharField(max_length=200)
    egyptian_brand   = models.CharField(max_length=200, null=True, blank=True)
    role             = models.CharField(max_length=50, null=True, blank=True,
                                        help_text='e.g. First-line, Second-line')
    dosage           = models.CharField(max_length=300, null=True, blank=True)
    key_side_effects = models.TextField(null=True, blank=True)
    avoid_in         = models.TextField(null=True, blank=True)
    allergy_warning  = models.TextField(null=True, blank=True)
    drug_interaction_warning = models.TextField(null=True, blank=True)

    # ── Doctor decision ───────────────────────────────────────────────────
    approval_status  = models.CharField(
        max_length=10,
        choices=ApprovalStatus.choices,
        default=ApprovalStatus.PENDING
    )
    doctor_dosage_override = models.CharField(max_length=300, null=True, blank=True,
                                               help_text='Doctor can override the suggested dosage')
    doctor_notes     = models.TextField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['role', 'drug_name']

    def __str__(self):
        return f'{self.drug_name} ({self.egyptian_brand}) – {self.approval_status}'


class Prescription(models.Model):
    """
    Final approved prescription issued by the doctor.
    This is what the patient ultimately sees.
    """

    id           = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    case         = models.OneToOneField(Case, on_delete=models.CASCADE, related_name='prescription')
    issued_by    = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True,
        related_name='issued_prescriptions',
        limit_choices_to={'role': 'doctor'}
    )

    approved_drugs = models.ManyToManyField(
        DrugRecommendation,
        blank=True,
        help_text='Drugs selected and approved by the doctor'
    )

    # ── Doctor instructions ───────────────────────────────────────────────
    instructions   = models.TextField(null=True, blank=True,
                                       help_text='Additional patient instructions')
    follow_up_date = models.DateField(null=True, blank=True)
    is_active      = models.BooleanField(default=True)

    issued_at      = models.DateTimeField(auto_now_add=True)
    updated_at     = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-issued_at']

    def __str__(self):
        return f'Prescription for {self.case.case_number} – {self.case.patient.name}'
