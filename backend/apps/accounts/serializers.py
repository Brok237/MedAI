"""
apps/accounts/serializers.py
─────────────────────────────
Serializers for auth, user profiles, and doctor management.
"""

from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from rest_framework_simplejwt.tokens import RefreshToken

from .models import PatientProfile, DoctorProfile

User = get_user_model()


# ── Token helpers ─────────────────────────────────────────────────────────────

def get_tokens_for_user(user):
    """Return a dict with access and refresh JWT tokens."""
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }


# ── Patient Profile ───────────────────────────────────────────────────────────

class PatientProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = PatientProfile
        exclude = ['user']


# ── Doctor Profile ────────────────────────────────────────────────────────────

class DoctorProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = DoctorProfile
        exclude = ['user', 'reviewed_by']
        read_only_fields = ['status', 'rejection_reason', 'reviewed_at', 'total_cases_reviewed']


class DoctorPublicSerializer(serializers.ModelSerializer):
    """Minimal doctor info for patient-facing views."""
    name = serializers.CharField(source='user.name', read_only=True)
    email = serializers.EmailField(source='user.email', read_only=True)

    class Meta:
        model = DoctorProfile
        fields = ['name', 'email', 'specialization', 'hospital', 'years_experience', 'bio']


# ── User ──────────────────────────────────────────────────────────────────────

class UserSerializer(serializers.ModelSerializer):
    patient_profile = PatientProfileSerializer(read_only=True)
    doctor_profile = DoctorProfileSerializer(read_only=True)

    class Meta:
        model = User
        fields = [
            'id', 'email', 'name', 'role', 'avatar',
            'is_active', 'date_joined',
            'patient_profile', 'doctor_profile',
        ]
        read_only_fields = ['id', 'email', 'role', 'date_joined']


# ── Registration ──────────────────────────────────────────────────────────────
class PatientRegisterSerializer(serializers.Serializer):
    """Register a new patient account."""
    name = serializers.CharField(max_length=150)
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, validators=[validate_password])
    confirm_password = serializers.CharField(write_only=True)

    # Existing PatientProfile fields
    age = serializers.IntegerField(required=False, allow_null=True)
    gender = serializers.ChoiceField(
        choices=['male', 'female', 'other'],
        required=False,
        allow_null=True
    )
    weight_kg = serializers.DecimalField(
        max_digits=5,
        decimal_places=2,
        required=False,
        allow_null=True
    )
    height_cm = serializers.DecimalField(
        max_digits=5,
        decimal_places=2,
        required=False,
        allow_null=True
    )
    blood_type = serializers.ChoiceField(
        choices=['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'],
        required=False,
        allow_null=True
    )
    phone = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    address = serializers.CharField(required=False, allow_blank=True, allow_null=True)

    chronic_diseases = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    allergies = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    current_meds = serializers.CharField(required=False, allow_blank=True, allow_null=True)

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError('This email is already registered.')
        return value

    def validate(self, data):
        if data['password'] != data.pop('confirm_password'):
            raise serializers.ValidationError({'confirm_password': 'Passwords do not match.'})
        return data

    def create(self, validated_data):
        profile_data = {
            'age': validated_data.pop('age', None),
            'gender': validated_data.pop('gender', None),
            'weight_kg': validated_data.pop('weight_kg', None),
            'height_cm': validated_data.pop('height_cm', None),
            'blood_type': validated_data.pop('blood_type', None),
            'phone': validated_data.pop('phone', None),
            'address': validated_data.pop('address', None),
            'chronic_diseases': validated_data.pop('chronic_diseases', None),
            'allergies': validated_data.pop('allergies', None),
            'current_meds': validated_data.pop('current_meds', None),
        }

        user = User.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password'],
            name=validated_data['name'],
            role=User.Role.PATIENT,
        )

        profile, created = PatientProfile.objects.get_or_create(user=user)

        for field, value in profile_data.items():
            if value is not None:
                setattr(profile, field, value)

        profile.save()
        return user


class DoctorRegisterSerializer(serializers.Serializer):
    """Register a new doctor account (pending admin approval)."""
    name             = serializers.CharField(max_length=150)
    email            = serializers.EmailField()
    password         = serializers.CharField(write_only=True, validators=[validate_password])
    confirm_password = serializers.CharField(write_only=True)

    # Doctor-specific fields
    specialization   = serializers.ChoiceField(choices=DoctorProfile.Specialization.choices)
    license_number   = serializers.CharField(max_length=100)
    license_file     = serializers.FileField(required=False, allow_null=True)
    years_experience = serializers.IntegerField(default=0)
    hospital         = serializers.CharField(max_length=200, required=False, allow_blank=True)

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError('This email is already registered.')
        return value

    def validate(self, data):
        if data['password'] != data.pop('confirm_password'):
            raise serializers.ValidationError({'confirm_password': 'Passwords do not match.'})
        return data

    def create(self, validated_data):
        # Extract doctor profile fields
        specialization   = validated_data.pop('specialization')
        license_number   = validated_data.pop('license_number')
        license_file     = validated_data.pop('license_file', None)
        years_experience = validated_data.pop('years_experience', 0)
        hospital         = validated_data.pop('hospital', '')

        # Deactivate until admin approves
        user = User.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password'],
            name=validated_data['name'],
            role=User.Role.DOCTOR,
            is_active=False,   # Doctor cannot login until approved
        )

        DoctorProfile.objects.create(
            user=user,
            specialization=specialization,
            license_number=license_number,
            license_file=license_file,
            years_experience=years_experience,
            hospital=hospital,
            status=DoctorProfile.Status.PENDING,
        )
        return user


# ── Login ─────────────────────────────────────────────────────────────────────

class LoginSerializer(serializers.Serializer):
    email    = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, data):
        from django.contrib.auth import authenticate
        user = authenticate(email=data['email'], password=data['password'])

        if not user:
            raise serializers.ValidationError('Invalid email or password.')

        if not user.is_active:
            if user.is_doctor:
                raise serializers.ValidationError(
                    'Your doctor account is pending admin approval. '
                    'You will be notified by email once approved.'
                )
            raise serializers.ValidationError('This account is disabled.')

        # Check doctor approval status
        if user.is_doctor:
            try:
                profile = user.doctor_profile
                if profile.status == DoctorProfile.Status.PENDING:
                    raise serializers.ValidationError('Your account is pending approval.')
                if profile.status == DoctorProfile.Status.REJECTED:
                    raise serializers.ValidationError(
                        f'Your account was rejected. Reason: {profile.rejection_reason or "Not specified."}'
                    )
            except DoctorProfile.DoesNotExist:
                pass

        data['user'] = user
        return data


# ── Google OAuth ──────────────────────────────────────────────────────────────

class GoogleAuthSerializer(serializers.Serializer):
    """Validate Google ID token and return JWT tokens."""
    id_token = serializers.CharField()
    role     = serializers.ChoiceField(choices=['patient', 'doctor'], default='patient')


# ── Admin: Doctor Approval ────────────────────────────────────────────────────

class DoctorApprovalSerializer(serializers.Serializer):
    action           = serializers.ChoiceField(choices=['approve', 'reject'])
    rejection_reason = serializers.CharField(required=False, allow_blank=True)

    def validate(self, data):
        if data['action'] == 'reject' and not data.get('rejection_reason'):
            raise serializers.ValidationError(
                {'rejection_reason': 'A rejection reason is required.'}
            )
        return data


# ── Password Change ───────────────────────────────────────────────────────────

class ChangePasswordSerializer(serializers.Serializer):
    old_password     = serializers.CharField(write_only=True)
    new_password     = serializers.CharField(write_only=True, validators=[validate_password])
    confirm_password = serializers.CharField(write_only=True)

    def validate(self, data):
        if data['new_password'] != data['confirm_password']:
            raise serializers.ValidationError({'confirm_password': 'Passwords do not match.'})
        return data
