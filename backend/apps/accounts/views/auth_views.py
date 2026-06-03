"""
apps/accounts/views/auth_views.py
──────────────────────────────────
Authentication endpoints:
  POST /api/v1/auth/register/patient/
  POST /api/v1/auth/register/doctor/
  POST /api/v1/auth/login/
  POST /api/v1/auth/logout/
  POST /api/v1/auth/token/refresh/
  POST /api/v1/auth/google/
  POST /api/v1/auth/change-password/
"""

from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenRefreshView
from django.utils import timezone

import requests as http_requests
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests

from django.contrib.auth import get_user_model
from django.conf import settings

from apps.accounts.serializers import (
    PatientRegisterSerializer,
    DoctorRegisterSerializer,
    LoginSerializer,
    GoogleAuthSerializer,
    ChangePasswordSerializer,
    UserSerializer,
    get_tokens_for_user,
)
from apps.accounts.models import PatientProfile, DoctorProfile
from apps.notifications.tasks import send_admin_new_doctor_notification

User = get_user_model()


class PatientRegisterView(APIView):
    """Register a new patient account."""
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = PatientRegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            tokens = get_tokens_for_user(user)
            return Response({
                'message': 'Account created successfully.',
                'user': UserSerializer(user).data,
                'tokens': tokens,
            }, status=status.HTTP_201_CREATED)
        print("REQUEST DATA:", request.data)
        print("SERIALIZER ERRORS:", serializer.errors)

        return Response({
            "request_data": request.data,
            "errors": serializer.errors
        }, status=400)


class DoctorRegisterView(APIView):
    """
    Register a new doctor account.
    Account is inactive until an admin approves it.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = DoctorRegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            # Notify all admins that a new doctor is waiting for review
            try:
                send_admin_new_doctor_notification.delay(str(user.id))
            except Exception:
                pass  # Celery may not be running in dev
            return Response({
                'message': (
                    'Registration submitted successfully. '
                    'Your account will be reviewed by an admin. '
                    'You will receive an email once approved.'
                ),
            }, status=status.HTTP_201_CREATED)
        return Response({
            "request_data": request.data,
            "errors": serializer.errors
        }, status=400)


class LoginView(APIView):
    """Login with email + password. Returns JWT tokens."""
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data['user']
            user.last_login = timezone.now()
            user.save(update_fields=['last_login'])
            tokens = get_tokens_for_user(user)
            return Response({
                'message': 'Login successful.',
                'user': UserSerializer(user).data,
                'tokens': tokens,
            })
        return Response({
            "request_data": request.data,
            "errors": serializer.errors
        }, status=400)


class LogoutView(APIView):
    """Blacklist the refresh token on logout."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            refresh_token = request.data.get('refresh')
            if refresh_token:
                token = RefreshToken(refresh_token)
                token.blacklist()
            return Response({'message': 'Logged out successfully.'})
        except Exception:
            return Response({'message': 'Logged out.'})


class GoogleAuthView(APIView):
    """
    Authenticate using a Google ID token (from Flutter google_sign_in).
    Creates account on first login.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = GoogleAuthSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        id_token_str = serializer.validated_data['id_token']
        role = serializer.validated_data.get('role', 'patient')

        try:
            # Verify Google token
            idinfo = id_token.verify_oauth2_token(
                id_token_str,
                google_requests.Request(),
                settings.SOCIAL_AUTH_GOOGLE_OAUTH2_KEY
            )
        except ValueError as e:
            return Response({'error': f'Invalid Google token: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)

        google_id = idinfo['sub']
        email     = idinfo.get('email', '')
        name      = idinfo.get('name', '')

        # Find or create user
        user = User.objects.filter(google_id=google_id).first()
        if not user:
            user = User.objects.filter(email=email).first()
            if user:
                user.google_id = google_id
                user.save(update_fields=['google_id'])
            else:
                user = User.objects.create_user(
                    email=email,
                    name=name,
                    role=role,
                    google_id=google_id,
                    password=None,
                    is_active=True,
                )
                if role == User.Role.PATIENT:
                    PatientProfile.objects.create(user=user)

        if not user.is_active:
            return Response({'error': 'Account is not active.'}, status=status.HTTP_403_FORBIDDEN)

        user.last_login = timezone.now()
        user.save(update_fields=['last_login'])

        tokens = get_tokens_for_user(user)
        return Response({
            'message': 'Google sign-in successful.',
            'user': UserSerializer(user).data,
            'tokens': tokens,
        })


class ChangePasswordView(APIView):
    """Change password for authenticated user."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        if serializer.is_valid():
            user = request.user
            if not user.check_password(serializer.validated_data['old_password']):
                return Response(
                    {'old_password': 'Incorrect current password.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            user.set_password(serializer.validated_data['new_password'])
            user.save()
            return Response({'message': 'Password changed successfully.'})
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class MeView(APIView):
    """Return the currently authenticated user's full profile."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data)

    def patch(self, request):
        """Update name and avatar."""
        user = request.user
        allowed = {k: v for k, v in request.data.items() if k in ['name', 'avatar']}
        for field, value in allowed.items():
            setattr(user, field, value)
        user.save()
        return Response(UserSerializer(user).data)
