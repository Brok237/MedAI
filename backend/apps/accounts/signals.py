"""
apps/accounts/signals.py
─────────────────────────
Auto-create PatientProfile when a new patient User is created via social auth.
"""

from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth import get_user_model
from .models import PatientProfile

User = get_user_model()


@receiver(post_save, sender=User)
def create_patient_profile(sender, instance, created, **kwargs):
    """Auto-create a PatientProfile for new patient users."""
    if created and instance.role == User.Role.PATIENT:
        PatientProfile.objects.get_or_create(user=instance)
