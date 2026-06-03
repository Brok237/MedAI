"""
apps/accounts/models.py
────────────────────────
Custom User model with role-based access.

Roles:
  patient  – regular user submitting symptoms
  doctor   – medical professional reviewing cases
  admin    – platform administrator

Doctor accounts require admin approval (status: pending → approved/rejected).
"""

from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models
from django.utils import timezone
import uuid


class UserManager(BaseUserManager):
    """Custom manager for the User model."""

    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('Email is required.')
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('role', User.Role.ADMIN)
        extra_fields.setdefault('is_active', True)
        return self.create_user(email, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    """
    Central user model.
    Uses email as username.
    Role determines which dashboard the user sees.
    """

    class Role(models.TextChoices):
        PATIENT = 'patient', 'Patient'
        DOCTOR  = 'doctor',  'Doctor'
        ADMIN   = 'admin',   'Admin'

    # ── Core fields ───────────────────────────────────────────────────────
    id         = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email      = models.EmailField(unique=True)
    name       = models.CharField(max_length=150)
    role       = models.CharField(max_length=10, choices=Role.choices, default=Role.PATIENT)
    avatar     = models.ImageField(upload_to='avatars/', null=True, blank=True)

    # ── Status flags ──────────────────────────────────────────────────────
    is_active  = models.BooleanField(default=True)
    is_staff   = models.BooleanField(default=False)  # Django admin access

    # ── Timestamps ────────────────────────────────────────────────────────
    date_joined   = models.DateTimeField(default=timezone.now)
    last_login    = models.DateTimeField(null=True, blank=True)

    # ── Google OAuth ──────────────────────────────────────────────────────
    google_id  = models.CharField(max_length=255, null=True, blank=True, unique=True)

    objects = UserManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['name']

    class Meta:
        verbose_name = 'User'
        verbose_name_plural = 'Users'
        ordering = ['-date_joined']

    def __str__(self):
        return f'{self.name} <{self.email}> [{self.role}]'

    @property
    def is_patient(self):
        return self.role == self.Role.PATIENT

    @property
    def is_doctor(self):
        return self.role == self.Role.DOCTOR

    @property
    def is_admin_user(self):
        return self.role == self.Role.ADMIN


class PatientProfile(models.Model):
    """Extended profile data for patients."""

    class BloodType(models.TextChoices):
        A_POS  = 'A+',  'A+'
        A_NEG  = 'A-',  'A-'
        B_POS  = 'B+',  'B+'
        B_NEG  = 'B-',  'B-'
        O_POS  = 'O+',  'O+'
        O_NEG  = 'O-',  'O-'
        AB_POS = 'AB+', 'AB+'
        AB_NEG = 'AB-', 'AB-'

    class Gender(models.TextChoices):
        MALE   = 'male',   'Male'
        FEMALE = 'female', 'Female'
        OTHER  = 'other',  'Other'

    user         = models.OneToOneField(User, on_delete=models.CASCADE, related_name='patient_profile')
    age          = models.PositiveIntegerField(null=True, blank=True)
    gender       = models.CharField(max_length=10, choices=Gender.choices, null=True, blank=True)
    weight_kg    = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    height_cm    = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    blood_type   = models.CharField(max_length=3, choices=BloodType.choices, null=True, blank=True)
    phone        = models.CharField(max_length=20, null=True, blank=True)
    address      = models.TextField(null=True, blank=True)

    # ── Medical history ───────────────────────────────────────────────────
    chronic_diseases = models.TextField(null=True, blank=True, help_text='Comma-separated list')
    allergies        = models.TextField(null=True, blank=True, help_text='Comma-separated list')
    current_meds     = models.TextField(null=True, blank=True, help_text='Comma-separated list')

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Patient Profile'

    def __str__(self):
        return f'Patient: {self.user.name}'

    @property
    def chronic_diseases_list(self):
        if self.chronic_diseases:
            return [d.strip() for d in self.chronic_diseases.split(',')]
        return []

    @property
    def allergies_list(self):
        if self.allergies:
            return [a.strip() for a in self.allergies.split(',')]
        return []


class DoctorProfile(models.Model):
    """Extended profile + verification data for doctors."""

    class Status(models.TextChoices):
        PENDING  = 'pending',  'Pending Approval'
        APPROVED = 'approved', 'Approved'
        REJECTED = 'rejected', 'Rejected'

    class Specialization(models.TextChoices):
        GENERAL        = 'general',        'General Medicine'
        CARDIOLOGY     = 'cardiology',      'Cardiology'
        NEUROLOGY      = 'neurology',       'Neurology'
        DERMATOLOGY    = 'dermatology',     'Dermatology'
        PEDIATRICS     = 'pediatrics',      'Pediatrics'
        ORTHOPEDICS    = 'orthopedics',     'Orthopedics'
        GASTRO         = 'gastroenterology','Gastroenterology'
        PSYCHIATRY     = 'psychiatry',      'Psychiatry'
        ENDOCRINOLOGY  = 'endocrinology',   'Endocrinology'
        PULMONOLOGY    = 'pulmonology',     'Pulmonology'
        OTHER          = 'other',           'Other'

    user             = models.OneToOneField(User, on_delete=models.CASCADE, related_name='doctor_profile')
    specialization   = models.CharField(max_length=50, choices=Specialization.choices, default=Specialization.GENERAL)
    license_number   = models.CharField(max_length=100)
    license_file     = models.FileField(upload_to='doctor_licenses/', null=True, blank=True)
    years_experience = models.PositiveIntegerField(default=0)
    hospital         = models.CharField(max_length=200, null=True, blank=True)
    phone            = models.CharField(max_length=20, null=True, blank=True)
    bio              = models.TextField(null=True, blank=True)

    # ── Admin approval ────────────────────────────────────────────────────
    status           = models.CharField(max_length=10, choices=Status.choices, default=Status.PENDING)
    rejection_reason = models.TextField(null=True, blank=True)
    reviewed_by      = models.ForeignKey(
        User, null=True, blank=True,
        on_delete=models.SET_NULL,
        related_name='reviewed_doctors'
    )
    reviewed_at      = models.DateTimeField(null=True, blank=True)

    # ── Stats ─────────────────────────────────────────────────────────────
    total_cases_reviewed = models.PositiveIntegerField(default=0)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Doctor Profile'

    def __str__(self):
        return f'Dr. {self.user.name} [{self.status}]'

    @property
    def is_approved(self):
        return self.status == self.Status.APPROVED
