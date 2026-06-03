"""
apps/chatbot/views.py
──────────────────────
Chatbot API endpoints:
  POST /api/v1/chat/                  – start session or send message
  GET  /api/v1/chat/sessions/         – list user's chat sessions
  GET  /api/v1/chat/sessions/<id>/    – session message history
"""

from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import serializers as drf_serializers
from django.shortcuts import get_object_or_404

from .models import ChatSession, ChatMessage
from .engine import ChatbotEngine


# ── Serializers ───────────────────────────────────────────────────────────────

class ChatMessageSerializer(drf_serializers.ModelSerializer):
    class Meta:
        model = ChatMessage
        fields = ['id', 'role', 'content', 'created_at']


class ChatSessionSerializer(drf_serializers.ModelSerializer):
    last_message = drf_serializers.SerializerMethodField()
    message_count = drf_serializers.SerializerMethodField()

    class Meta:
        model = ChatSession
        fields = ['id', 'case', 'language', 'created_at', 'updated_at',
                  'last_message', 'message_count']

    def get_last_message(self, obj):
        msg = obj.messages.last()
        if msg:
            return {'role': msg.role, 'content': msg.content[:100]}
        return None

    def get_message_count(self, obj):
        return obj.messages.count()


class SendMessageSerializer(drf_serializers.Serializer):
    message    = drf_serializers.CharField(max_length=2000)
    session_id = drf_serializers.UUIDField(required=False, allow_null=True)
    case_id    = drf_serializers.UUIDField(required=False, allow_null=True)
    language   = drf_serializers.ChoiceField(choices=['en', 'ar'], default='en')


# ── Views ─────────────────────────────────────────────────────────────────────

class ChatView(APIView):
    """
    Send a message to the AI assistant.
    Creates a session if session_id not provided.
    Optionally links to a case for contextual responses.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = SendMessageSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data       = serializer.validated_data
        user_msg   = data['message']
        session_id = data.get('session_id')
        case_id    = data.get('case_id')
        language   = data.get('language', 'en')

        # Get or create session
        if session_id:
            session = get_object_or_404(ChatSession, id=session_id, user=request.user)
        else:
            session = ChatSession.objects.create(
                user=request.user,
                language=language,
            )
            if case_id:
                try:
                    from apps.cases.models import Case
                    case = Case.objects.get(id=case_id, patient=request.user)
                    session.case = case
                    session.save(update_fields=['case'])
                except Exception:
                    pass

        # Build context from linked case
        context = {}
        if session.case:
            case = session.case
            context['predicted_disease'] = case.predicted_disease or ''
            context['case_status'] = case.status
            context['drug_recommendations'] = [
                {
                    'drug_name':      d.drug_name,
                    'egyptian_brand': d.egyptian_brand,
                    'role':           d.role,
                    'dosage':         d.dosage,
                    'key_side_effects': d.key_side_effects,
                    'avoid_in':       d.avoid_in,
                }
                for d in case.drug_recommendations.all()[:5]
            ]

        # Save user message
        ChatMessage.objects.create(
            session=session,
            role=ChatMessage.Role.USER,
            content=user_msg,
        )

        # Generate AI response
        engine   = ChatbotEngine(language=session.language)
        ai_reply = engine.get_response(user_msg, context=context)

        # Save AI response
        ai_message = ChatMessage.objects.create(
            session=session,
            role=ChatMessage.Role.ASSISTANT,
            content=ai_reply,
        )

        return Response({
            'session_id': str(session.id),
            'response': ai_reply,
            'message_id': str(ai_message.id),
            'created_at': ai_message.created_at.isoformat(),
        })


class ChatSessionListView(APIView):
    """List the current user's chat sessions."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        sessions = ChatSession.objects.filter(user=request.user).order_by('-updated_at')
        return Response({
            'results': ChatSessionSerializer(sessions, many=True).data,
            'count': sessions.count(),
        })


class ChatSessionHistoryView(APIView):
    """Full message history for a session."""
    permission_classes = [IsAuthenticated]

    def get(self, request, session_id):
        session = get_object_or_404(ChatSession, id=session_id, user=request.user)
        messages = session.messages.order_by('created_at')
        return Response({
            'session': ChatSessionSerializer(session).data,
            'messages': ChatMessageSerializer(messages, many=True).data,
        })
