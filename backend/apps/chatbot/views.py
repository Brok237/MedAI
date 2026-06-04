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
from .medical_chatbot import MedicalChatbot
from .models import ChatSession, ChatMessage
from .engine import ChatbotEngine
from apps.cases.models import Case
from apps.cases.serializers import DrugRecommendationSerializer

chatbot = MedicalChatbot()
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
class GeneralChatbotView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = SendMessageSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        message = serializer.validated_data['message']
        session_id = serializer.validated_data.get('session_id')
        case_id = serializer.validated_data.get('case_id')
        language = serializer.validated_data.get('language', 'en')

        # Get old session or create new one
        if session_id:
            session = get_object_or_404(
                ChatSession,
                id=session_id,
                user=request.user
            )
        else:
            session = ChatSession.objects.create(
                user=request.user,
                case_id=case_id,
                language=language,
            )

        # Save user message
        ChatMessage.objects.create(
            session=session,
            role=ChatMessage.Role.USER,
            content=message,
        )

        # Build history from DB
        db_messages = session.messages.order_by('created_at')
        history = []
        for msg in db_messages:
            if msg.role == ChatMessage.Role.USER:
                history.append({
                    "role": "user",
                    "content": msg.content,
                })
            elif msg.role == ChatMessage.Role.ASSISTANT:
                history.append({
                    "role": "assistant",
                    "content": msg.content,
                })

        # Ask new chatbot
        result = chatbot.chat(
            message=message,
            history=history[:-1],
            language=language,
        )

        bot_response = result.get('response', '')

        # Save bot message
        ChatMessage.objects.create(
        session=session,
        role=ChatMessage.Role.ASSISTANT,
        content=bot_response,
    )

        session.language = language
        session.save()

        return Response({
            "session_id": session.id,
            "response": bot_response,
            "extracted_symptoms": result.get("extracted_symptoms", []),
            "is_emergency": result.get("is_emergency", False),
            "intent": result.get("intent", "general"),
        })
class CaseChatbotView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):

        serializer = SendMessageSerializer(data=request.data)

        if not serializer.is_valid():
            return Response(
                serializer.errors,
                status=status.HTTP_400_BAD_REQUEST
            )

        message = serializer.validated_data['message']
        case_id = serializer.validated_data.get('case_id')
        language = serializer.validated_data.get('language', 'en')

        if not case_id:
            return Response(
                {"error": "case_id is required"},
                status=400
            )

        case = get_object_or_404(
            Case,
            id=case_id,
            patient=request.user
        )

        engine = ChatbotEngine(language)

        context = {
            "predicted_disease": case.predicted_disease,
            "case_status": case.status,
            "drug_recommendations":
                DrugRecommendationSerializer(
                    case.drug_recommendations.all(),
                    many=True
                ).data
        }

        response_text = engine.get_response(
            message,
            context
        )

        return Response({
            "response": response_text,
            "case_id": str(case.id)
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
