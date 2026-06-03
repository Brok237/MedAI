"""apps/cases/admin.py"""

from django.contrib import admin
from .models import Case, CaseAttachment, DrugRecommendation, Prescription


class CaseAttachmentInline(admin.TabularInline):
    model = CaseAttachment
    extra = 0
    readonly_fields = ['uploaded_at']


class DrugRecommendationInline(admin.TabularInline):
    model = DrugRecommendation
    extra = 0
    readonly_fields = ['created_at']


@admin.register(Case)
class CaseAdmin(admin.ModelAdmin):
    list_display = ['case_number', 'patient', 'assigned_doctor', 'status',
                    'predicted_disease', 'created_at']
    list_filter  = ['status']
    search_fields = ['case_number', 'patient__name', 'patient__email', 'predicted_disease']
    readonly_fields = ['case_number', 'created_at', 'updated_at', 'ml_raw_response']
    inlines = [CaseAttachmentInline, DrugRecommendationInline]
    ordering = ['-created_at']


@admin.register(DrugRecommendation)
class DrugRecommendationAdmin(admin.ModelAdmin):
    list_display = ['drug_name', 'egyptian_brand', 'disease', 'role', 'approval_status']
    list_filter  = ['approval_status', 'role']
    search_fields = ['drug_name', 'disease']


@admin.register(Prescription)
class PrescriptionAdmin(admin.ModelAdmin):
    list_display = ['case', 'issued_by', 'issued_at', 'is_active']
    list_filter  = ['is_active']
    readonly_fields = ['issued_at']
