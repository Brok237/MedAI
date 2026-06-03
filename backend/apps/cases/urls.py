"""apps/cases/urls.py"""

from django.urls import path
from .views import (
    SubmitCaseView,
    PatientCaseListView,
    PatientCaseDetailView,
    CaseAttachmentUploadView,
    PatientPrescriptionView,
    DoctorCaseQueueView,
    DoctorCaseDetailView,
    DoctorCaseDecisionView,
    AdminCaseListView,
    AdminDashboardStatsView,
)

urlpatterns = [
    # Patient
    path('submit/',                              SubmitCaseView.as_view(),              name='case-submit'),
    path('my/',                                  PatientCaseListView.as_view(),         name='patient-case-list'),
    path('my/<uuid:case_id>/',                   PatientCaseDetailView.as_view(),       name='patient-case-detail'),
    path('my/<uuid:case_id>/upload/',            CaseAttachmentUploadView.as_view(),    name='case-upload'),
    path('my/<uuid:case_id>/prescription/',      PatientPrescriptionView.as_view(),     name='patient-prescription'),

    # Doctor
    path('queue/',                               DoctorCaseQueueView.as_view(),         name='doctor-case-queue'),
    path('<uuid:case_id>/review/',               DoctorCaseDetailView.as_view(),        name='doctor-case-detail'),
    path('<uuid:case_id>/decision/',             DoctorCaseDecisionView.as_view(),      name='doctor-case-decision'),

    # Admin
    path('admin/all/',                           AdminCaseListView.as_view(),           name='admin-case-list'),
    path('admin/stats/',                         AdminDashboardStatsView.as_view(),     name='admin-stats'),
]
