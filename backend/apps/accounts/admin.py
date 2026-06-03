"""apps/accounts/admin.py"""

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User, PatientProfile, DoctorProfile


class PatientProfileInline(admin.StackedInline):
    model = PatientProfile
    can_delete = False
    verbose_name_plural = 'Patient Profile'


class DoctorProfileInline(admin.StackedInline):
    model = DoctorProfile
    can_delete = False
    verbose_name_plural = 'Doctor Profile'


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    ordering = ['-date_joined']
    list_display = ['email', 'name', 'role', 'is_active', 'date_joined']
    list_filter = ['role', 'is_active', 'is_staff']
    search_fields = ['email', 'name']

    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        ('Personal Info', {'fields': ('name', 'role', 'avatar', 'google_id')}),
        ('Permissions', {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
        ('Dates', {'fields': ('date_joined', 'last_login')}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'name', 'role', 'password1', 'password2', 'is_active'),
        }),
    )
    readonly_fields = ['date_joined', 'last_login']

    def get_inlines(self, request, obj=None):
        if obj:
            if obj.role == User.Role.PATIENT:
                return [PatientProfileInline]
            elif obj.role == User.Role.DOCTOR:
                return [DoctorProfileInline]
        return []


@admin.register(DoctorProfile)
class DoctorProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'specialization', 'license_number', 'status', 'created_at']
    list_filter = ['status', 'specialization']
    search_fields = ['user__name', 'user__email', 'license_number']
    readonly_fields = ['created_at', 'updated_at']
    actions = ['approve_doctors', 'reject_doctors']

    def approve_doctors(self, request, queryset):
        from django.utils import timezone
        updated = queryset.filter(status=DoctorProfile.Status.PENDING).update(
            status=DoctorProfile.Status.APPROVED,
            reviewed_by=request.user,
            reviewed_at=timezone.now(),
        )
        # Activate user accounts
        for profile in queryset:
            profile.user.is_active = True
            profile.user.save(update_fields=['is_active'])
        self.message_user(request, f'{updated} doctor(s) approved.')
    approve_doctors.short_description = 'Approve selected doctors'

    def reject_doctors(self, request, queryset):
        updated = queryset.filter(status=DoctorProfile.Status.PENDING).update(
            status=DoctorProfile.Status.REJECTED
        )
        self.message_user(request, f'{updated} doctor(s) rejected.')
    reject_doctors.short_description = 'Reject selected doctors'
