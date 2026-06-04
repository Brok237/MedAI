from django.urls import path

from .views import (
    GeneralChatbotView,
    CaseChatbotView,
    ChatSessionListView,
    ChatSessionHistoryView,
)

urlpatterns = [

    path(
        'general/',
        GeneralChatbotView.as_view(),
        name='general-chat'
    ),

    path(
        'case/',
        CaseChatbotView.as_view(),
        name='case-chat'
    ),

    path(
        'sessions/',
        ChatSessionListView.as_view(),
        name='chat-sessions'
    ),

    path(
        'sessions/<uuid:session_id>/',
        ChatSessionHistoryView.as_view(),
        name='chat-history'
    ),
]