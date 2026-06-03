"""
apps/chatbot/models.py
───────────────────────
Stores chat sessions and message history.
Each session is tied to a user and optionally a case.
"""

import uuid
from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()


class ChatSession(models.Model):
    """A conversation thread between a user and the AI assistant."""

    id         = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user       = models.ForeignKey(User, on_delete=models.CASCADE, related_name='chat_sessions')
    case       = models.ForeignKey(
        'cases.Case', on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='chat_sessions',
        help_text='Optional: session linked to a specific case'
    )
    language   = models.CharField(max_length=5, default='en',
                                   help_text="'en' or 'ar'")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-updated_at']

    def __str__(self):
        return f'Chat {self.id} – {self.user.name}'


class ChatMessage(models.Model):
    """A single message within a chat session."""

    class Role(models.TextChoices):
        USER      = 'user',      'User'
        ASSISTANT = 'assistant', 'Assistant'

    id         = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    session    = models.ForeignKey(ChatSession, on_delete=models.CASCADE, related_name='messages')
    role       = models.CharField(max_length=10, choices=Role.choices)
    content    = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        preview = self.content[:60]
        return f'[{self.role}] {preview}'
