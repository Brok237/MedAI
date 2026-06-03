"""
apps/notifications/models.py
─────────────────────────────
In-app notification model.
"""

import uuid
from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()


class Notification(models.Model):
    """A notification record for a specific user."""

    class Type(models.TextChoices):
        CASE_SUBMITTED   = 'case_submitted',    'New Case Submitted'
        CASE_APPROVED    = 'case_approved',     'Case Approved'
        CASE_REJECTED    = 'case_rejected',     'Case Rejected'
        DOCTOR_APPROVED  = 'doctor_approved',   'Doctor Account Approved'
        DOCTOR_REJECTED  = 'doctor_rejected',   'Doctor Account Rejected'
        NEW_DOCTOR       = 'new_doctor',        'New Doctor Registration'
        GENERAL          = 'general',           'General'

    id         = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user       = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    type       = models.CharField(max_length=30, choices=Type.choices, default=Type.GENERAL)
    title      = models.CharField(max_length=200)
    message    = models.TextField()
    is_read    = models.BooleanField(default=False)
    data       = models.JSONField(null=True, blank=True, help_text='Extra payload e.g. case_id')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'[{self.type}] {self.title} → {self.user.name}'
