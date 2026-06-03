"""apps/chatbot/admin.py"""
from django.contrib import admin
from .models import ChatSession, ChatMessage


class ChatMessageInline(admin.TabularInline):
    model = ChatMessage
    extra = 0
    readonly_fields = ['role', 'content', 'created_at']
    can_delete = False


@admin.register(ChatSession)
class ChatSessionAdmin(admin.ModelAdmin):
    list_display  = ['id', 'user', 'language', 'message_count', 'created_at']
    list_filter   = ['language']
    search_fields = ['user__name', 'user__email']
    readonly_fields = ['created_at', 'updated_at']
    inlines = [ChatMessageInline]

    def message_count(self, obj):
        return obj.messages.count()
    message_count.short_description = 'Messages'


@admin.register(ChatMessage)
class ChatMessageAdmin(admin.ModelAdmin):
    list_display  = ['session', 'role', 'content_preview', 'created_at']
    list_filter   = ['role']
    search_fields = ['content', 'session__user__name']

    def content_preview(self, obj):
        return obj.content[:80]
    content_preview.short_description = 'Content'
