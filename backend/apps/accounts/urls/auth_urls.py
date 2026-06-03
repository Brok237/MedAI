"""apps/accounts/urls/auth_urls.py"""

from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from apps.accounts.views.auth_views import (
    PatientRegisterView,
    DoctorRegisterView,
    LoginView,
    LogoutView,
    GoogleAuthView,
    ChangePasswordView,
    MeView,
)

urlpatterns = [
    path('register/patient/',  PatientRegisterView.as_view(),  name='patient-register'),
    path('register/doctor/',   DoctorRegisterView.as_view(),   name='doctor-register'),
    path('login/',             LoginView.as_view(),             name='login'),
    path('logout/',            LogoutView.as_view(),            name='logout'),
    path('token/refresh/',     TokenRefreshView.as_view(),      name='token-refresh'),
    path('google/',            GoogleAuthView.as_view(),         name='google-auth'),
    path('change-password/',   ChangePasswordView.as_view(),    name='change-password'),
    path('me/',                MeView.as_view(),                name='me'),
]
