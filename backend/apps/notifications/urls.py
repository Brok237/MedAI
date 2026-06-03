"""apps/notifications/urls.py"""
from django.urls import path
from .views import NotificationListView, NotificationMarkReadView

urlpatterns = [
    path('',                             NotificationListView.as_view(),    name='notification-list'),
    path('read-all/',                    NotificationMarkReadView.as_view(), name='notification-read-all'),
    path('<uuid:notif_id>/read/',        NotificationMarkReadView.as_view(), name='notification-read'),
]
