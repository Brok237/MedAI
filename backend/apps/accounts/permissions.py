"""
apps/accounts/permissions.py
──────────────────────────────
Custom DRF permission classes for role-based access.
"""

from rest_framework.permissions import BasePermission


class IsPatient(BasePermission):
    """Allow access only to users with the 'patient' role."""
    message = 'Access restricted to patients only.'

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.is_patient)


class IsDoctor(BasePermission):
    """Allow access only to approved doctors."""
    message = 'Access restricted to approved doctors only.'

    def has_permission(self, request, view):
        if not (request.user and request.user.is_authenticated and request.user.is_doctor):
            return False
        try:
            return request.user.doctor_profile.is_approved
        except Exception:
            return False


class IsDoctorOrAdmin(BasePermission):
    """Allow access to approved doctors or admins."""
    message = 'Access restricted to doctors or admins.'

    def has_permission(self, request, view):
        if not (request.user and request.user.is_authenticated):
            return False
        if request.user.is_admin_user:
            return True
        if request.user.is_doctor:
            try:
                return request.user.doctor_profile.is_approved
            except Exception:
                return False
        return False


class IsAdminUser(BasePermission):
    """Allow access only to admin-role users."""
    message = 'Access restricted to administrators.'

    def has_permission(self, request, view):
        return bool(
            request.user and
            request.user.is_authenticated and
            request.user.is_admin_user
        )


class IsOwnerOrAdmin(BasePermission):
    """Allow object-level access to the owner or admin."""
    message = 'You do not have permission to access this resource.'

    def has_object_permission(self, request, view, obj):
        if request.user.is_admin_user:
            return True
        # obj could be a Case, Profile etc. — check user field
        owner = getattr(obj, 'patient', None) or getattr(obj, 'user', None)
        return owner == request.user
