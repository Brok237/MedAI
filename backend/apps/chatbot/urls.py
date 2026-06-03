"""apps/chatbot/urls.py"""
from django.urls import path
from .views import ChatView, ChatSessionListView, ChatSessionHistoryView

urlpatterns = [
    path('',                          ChatView.as_view(),              name='chat-send'),
    path('sessions/',                  ChatSessionListView.as_view(),   name='chat-sessions'),
    path('sessions/<uuid:session_id>/',ChatSessionHistoryView.as_view(),name='chat-history'),
]
