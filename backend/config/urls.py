"""
config/urls.py
──────────────
Root URL configuration.
All API routes live under /api/v1/.
"""

from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    # Django admin
    path('admin/', admin.site.urls),

    # Auth (JWT + Google OAuth)
    path('api/v1/auth/', include('apps.accounts.urls.auth_urls')),

    # User & Doctor management
    path('api/v1/users/', include('apps.accounts.urls.user_urls')),

    # Cases: symptom submission, predictions, approvals
    path('api/v1/cases/', include('apps.cases.urls')),

    # AI Chatbot
    path('api/v1/chat/', include('apps.chatbot.urls')),

    # Notifications
    path('api/v1/notifications/', include('apps.notifications.urls')),

    # Social auth (Google Sign-In)
    path('social-auth/', include('social_django.urls', namespace='social')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
