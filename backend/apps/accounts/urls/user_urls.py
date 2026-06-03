"""apps/accounts/urls/user_urls.py"""

from django.urls import path
from apps.accounts.views.user_views import (
    PatientProfileView,
    DoctorProfileView,
    DoctorListView,
    AdminDoctorListView,
    AdminDoctorApprovalView,
    AdminUserListView,
    AdminUserDetailView,
)

urlpatterns = [
    # Patient profile
    path('patient/profile/',               PatientProfileView.as_view(),       name='patient-profile'),

    # Doctor profile (own)
    path('doctor/profile/',                DoctorProfileView.as_view(),         name='doctor-profile'),

    # Public doctor list for patients
    path('doctors/',                       DoctorListView.as_view(),             name='doctor-list'),

    # Admin: doctor management
    path('admin/doctors/',                 AdminDoctorListView.as_view(),        name='admin-doctor-list'),
    path('admin/doctors/<uuid:doctor_id>/approval/', AdminDoctorApprovalView.as_view(), name='admin-doctor-approval'),

    # Admin: user management
    path('admin/users/',                   AdminUserListView.as_view(),          name='admin-user-list'),
    path('admin/users/<uuid:user_id>/',    AdminUserDetailView.as_view(),        name='admin-user-detail'),
]
