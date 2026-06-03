"""
apps/accounts/views/user_views.py
──────────────────────────────────
Views for:
  - Patient profile management
  - Doctor profile management
  - Admin: list/approve/reject doctors
  - Admin: user management
"""

from rest_framework import status, generics
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.shortcuts import get_object_or_404

from apps.accounts.models import PatientProfile, DoctorProfile
from apps.accounts.serializers import (
    UserSerializer,
    PatientProfileSerializer,
    DoctorProfileSerializer,
    DoctorApprovalSerializer,
    DoctorPublicSerializer,
)
from apps.accounts.permissions import IsPatient, IsDoctor, IsAdminUser
from apps.notifications.tasks import (
    send_doctor_approval_email,
    send_doctor_rejection_email,
)

User = get_user_model()


# ── Patient Profile ───────────────────────────────────────────────────────────

class PatientProfileView(APIView):
    """GET/PUT own patient profile."""
    permission_classes = [IsAuthenticated, IsPatient]

    def get(self, request):
        profile, _ = PatientProfile.objects.get_or_create(user=request.user)
        return Response(PatientProfileSerializer(profile).data)

    def put(self, request):
        profile, _ = PatientProfile.objects.get_or_create(user=request.user)
        serializer = PatientProfileSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ── Doctor Profile ────────────────────────────────────────────────────────────

class DoctorProfileView(APIView):
    """GET/PUT own doctor profile."""
    permission_classes = [IsAuthenticated, IsDoctor]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get(self, request):
        profile = get_object_or_404(DoctorProfile, user=request.user)
        return Response(DoctorProfileSerializer(profile).data)

    def put(self, request):
        profile = get_object_or_404(DoctorProfile, user=request.user)
        serializer = DoctorProfileSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class DoctorListView(APIView):
    """List all approved doctors (for patients to see)."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        doctors = DoctorProfile.objects.filter(
            status=DoctorProfile.Status.APPROVED
        ).select_related('user')
        serializer = DoctorPublicSerializer(doctors, many=True)
        return Response({'results': serializer.data, 'count': doctors.count()})


# ── Admin: Doctor Approval ────────────────────────────────────────────────────

class AdminDoctorListView(APIView):
    """Admin: list all doctors filtered by status."""
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get(self, request):
        status_filter = request.query_params.get('status', None)
        qs = DoctorProfile.objects.select_related('user').order_by('-created_at')
        if status_filter:
            qs = qs.filter(status=status_filter)

        data = []
        for profile in qs:
            data.append({
                'id': str(profile.user.id),
                'name': profile.user.name,
                'email': profile.user.email,
                'specialization': profile.specialization,
                'license_number': profile.license_number,
                'license_file': request.build_absolute_uri(profile.license_file.url) if profile.license_file else None,
                'hospital': profile.hospital,
                'years_experience': profile.years_experience,
                'status': profile.status,
                'rejection_reason': profile.rejection_reason,
                'registered_at': profile.created_at.isoformat(),
            })
        return Response({'results': data, 'count': len(data)})


class AdminDoctorApprovalView(APIView):
    """Admin: approve or reject a doctor account."""
    permission_classes = [IsAuthenticated, IsAdminUser]

    def post(self, request, doctor_id):
        serializer = DoctorApprovalSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        doctor_user = get_object_or_404(User, id=doctor_id, role=User.Role.DOCTOR)
        profile = get_object_or_404(DoctorProfile, user=doctor_user)
        action = serializer.validated_data['action']

        if action == 'approve':
            profile.status = DoctorProfile.Status.APPROVED
            profile.rejection_reason = None
            profile.reviewed_by = request.user
            profile.reviewed_at = timezone.now()
            profile.save()

            # Activate the user account so they can login
            doctor_user.is_active = True
            doctor_user.save(update_fields=['is_active'])

            try:
                send_doctor_approval_email.delay(str(doctor_user.id))
            except Exception:
                pass

            return Response({'message': f'Dr. {doctor_user.name} has been approved.'})

        elif action == 'reject':
            rejection_reason = serializer.validated_data.get('rejection_reason', '')
            profile.status = DoctorProfile.Status.REJECTED
            profile.rejection_reason = rejection_reason
            profile.reviewed_by = request.user
            profile.reviewed_at = timezone.now()
            profile.save()

            try:
                send_doctor_rejection_email.delay(str(doctor_user.id), rejection_reason)
            except Exception:
                pass

            return Response({'message': f'Dr. {doctor_user.name} has been rejected.'})


# ── Admin: User Management ────────────────────────────────────────────────────

class AdminUserListView(APIView):
    """Admin: list all users with optional role filter."""
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get(self, request):
        role_filter = request.query_params.get('role', None)
        qs = User.objects.order_by('-date_joined')
        if role_filter:
            qs = qs.filter(role=role_filter)

        serializer = UserSerializer(qs, many=True)
        return Response({'results': serializer.data, 'count': qs.count()})


class AdminUserDetailView(APIView):
    """Admin: view or toggle a specific user."""
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get(self, request, user_id):
        user = get_object_or_404(User, id=user_id)
        return Response(UserSerializer(user).data)

    def patch(self, request, user_id):
        """Toggle is_active or update role."""
        user = get_object_or_404(User, id=user_id)
        allowed = {k: v for k, v in request.data.items() if k in ['is_active', 'role']}
        for field, value in allowed.items():
            setattr(user, field, value)
        user.save()
        return Response(UserSerializer(user).data)
