"""
apps/chatbot/engine.py
───────────────────────
Rule-based chatbot engine (Arabic + English).

Architecture is designed so you can later swap the _call_llm() method
to use OpenAI / Gemini without changing anything else.

Current implementation: rule-based keyword matching with templated responses.
"""

import re
import logging

logger = logging.getLogger(__name__)


# ── Response Templates ────────────────────────────────────────────────────────

RESPONSES_EN = {
    'greeting': [
        "Hello! I'm MedAI Assistant. I can explain your diagnosis, medications, and side effects. How can I help you?",
        "Hi there! I'm here to help you understand your medical recommendations. What would you like to know?",
    ],
    'disease_explain': (
        "Based on your symptoms, our system predicted **{disease}**.\n\n"
        "This condition {description}\n\n"
        "⚠️ Remember: this is an AI-assisted suggestion. Your doctor has the final say on your diagnosis and treatment."
    ),
    'drug_explain': (
        "**{drug}** (Egyptian brand: {brand}) is recommended for {disease}.\n\n"
        "📋 **Role:** {role}\n"
        "💊 **Dosage:** {dosage}\n"
        "⚠️ **Side effects:** {side_effects}\n"
        "🚫 **Avoid if:** {avoid_in}"
    ),
    'side_effects': (
        "Common side effects of **{drug}** include: {side_effects}.\n\n"
        "If you experience severe symptoms, contact your doctor immediately."
    ),
    'dosage': (
        "The suggested dosage for **{drug}** is: **{dosage}**.\n\n"
        "⚠️ Your doctor may adjust this based on your specific condition. "
        "Always follow your doctor's final prescription."
    ),
    'waiting': (
        "Your case is currently waiting for doctor review. "
        "Doctors typically review cases within 24 hours. "
        "You'll receive a notification once your prescription is ready."
    ),
    'approved': (
        "Great news! Your prescription has been approved by your doctor. "
        "You can view it in the 'My Prescriptions' section."
    ),
    'safety_warning': (
        "⚠️ **Important safety information:**\n\n"
        "Always inform your doctor about:\n"
        "• Any allergies you have\n"
        "• Other medications you're currently taking\n"
        "• Chronic conditions (diabetes, kidney disease, etc.)\n\n"
        "Never take medication without doctor approval."
    ),
    'default': (
        "I'm here to help you understand your medical recommendations. "
        "You can ask me about:\n"
        "• Your predicted disease\n"
        "• Recommended medications\n"
        "• Side effects and warnings\n"
        "• Dosage information\n"
        "• What to expect next"
    ),
}

RESPONSES_AR = {
    'greeting': [
        "مرحباً! أنا مساعد MedAI. أستطيع شرح تشخيصك والأدوية والآثار الجانبية. كيف يمكنني مساعدتك؟",
        "أهلاً! أنا هنا لمساعدتك في فهم توصياتك الطبية. ماذا تريد أن تعرف؟",
    ],
    'disease_explain': (
        "بناءً على أعراضك، توقّع نظامنا الإصابة بـ **{disease}**.\n\n"
        "⚠️ تذكّر: هذا اقتراح بمساعدة الذكاء الاصطناعي. كلمة الطبيب هي الفصل في التشخيص والعلاج."
    ),
    'drug_explain': (
        "يُوصى بدواء **{drug}** (الماركة المصرية: {brand}) لعلاج {disease}.\n\n"
        "📋 **الدور:** {role}\n"
        "💊 **الجرعة:** {dosage}\n"
        "⚠️ **الآثار الجانبية:** {side_effects}\n"
        "🚫 **تجنّب في:** {avoid_in}"
    ),
    'side_effects': (
        "الآثار الجانبية الشائعة لدواء **{drug}** تشمل: {side_effects}.\n\n"
        "إذا ظهرت أعراض حادة، اتصل بطبيبك فوراً."
    ),
    'dosage': (
        "الجرعة المقترحة لدواء **{drug}** هي: **{dosage}**.\n\n"
        "⚠️ قد يعدّل طبيبك الجرعة وفقاً لحالتك. اتبع دائماً وصفة طبيبك النهائية."
    ),
    'waiting': (
        "حالتك قيد المراجعة من قِبل الطبيب. "
        "يراجع الأطباء الحالات عادةً خلال 24 ساعة. "
        "ستتلقى إشعاراً فور الموافقة على وصفتك."
    ),
    'approved': (
        "أخبار رائعة! تمّت الموافقة على وصفتك من قِبل طبيبك. "
        "يمكنك الاطلاع عليها في قسم 'وصفاتي'."
    ),
    'safety_warning': (
        "⚠️ **معلومات السلامة المهمة:**\n\n"
        "أخبر طبيبك دائماً عن:\n"
        "• أي حساسية لديك\n"
        "• الأدوية الأخرى التي تتناولها حالياً\n"
        "• الأمراض المزمنة (السكري وأمراض الكلى وغيرها)\n\n"
        "لا تتناول أي دواء بدون موافقة طبيبك."
    ),
    'default': (
        "أنا هنا لمساعدتك في فهم توصياتك الطبية. يمكنك سؤالي عن:\n"
        "• مرضك المتوقع\n"
        "• الأدوية الموصى بها\n"
        "• الآثار الجانبية والتحذيرات\n"
        "• معلومات الجرعات\n"
        "• ما تتوقعه لاحقاً"
    ),
}

# Simple keyword → intent mapping
INTENT_KEYWORDS = {
    'en': {
        'greeting':       ['hello', 'hi', 'hey', 'good morning', 'good evening', 'start', 'help'],
        'disease_explain':['disease', 'diagnosis', 'condition', 'what do i have', 'predict', 'illness'],
        'drug_explain':   ['drug', 'medicine', 'medication', 'tablet', 'pill', 'brand'],
        'side_effects':   ['side effect', 'adverse', 'reaction', 'complication'],
        'dosage':         ['dose', 'dosage', 'how much', 'how many', 'frequency', 'when to take'],
        'waiting':        ['waiting', 'pending', 'when', 'how long', 'status'],
        'approved':       ['approved', 'prescription ready', 'result'],
        'safety_warning': ['safe', 'danger', 'warning', 'allergy', 'interaction', 'contraindication'],
    },
    'ar': {
        'greeting':       ['مرحبا', 'أهلا', 'السلام', 'صباح', 'مساء', 'مساعدة'],
        'disease_explain':['مرض', 'تشخيص', 'حالة', 'ما المرض', 'توقع'],
        'drug_explain':   ['دواء', 'دوا', 'علاج', 'حبة', 'ماركة', 'أقراص'],
        'side_effects':   ['أعراض جانبية', 'آثار جانبية', 'مضاعفات', 'تأثير'],
        'dosage':         ['جرعة', 'كمية', 'كم مرة', 'متى أاخذ', 'تكرار'],
        'waiting':        ['انتظار', 'متى', 'كم وقت', 'حالة', 'موعد'],
        'approved':       ['موافقة', 'وصفة', 'نتيجة', 'جاهزة'],
        'safety_warning': ['أمان', 'خطر', 'تحذير', 'حساسية', 'تفاعل'],
    },
}


class ChatbotEngine:
    """
    Rule-based chatbot with context injection.

    To upgrade to LLM later, replace _call_llm() below.
    Everything else stays the same.
    """

    def __init__(self, language: str = 'en'):
        self.language = language if language in ('en', 'ar') else 'en'
        self.responses = RESPONSES_AR if self.language == 'ar' else RESPONSES_EN
        self.keywords  = INTENT_KEYWORDS.get(self.language, INTENT_KEYWORDS['en'])

    def get_response(self, message: str, context: dict = None) -> str:
        """
        Generate a response to the user message.

        context dict may include:
          - predicted_disease: str
          - drug_recommendations: list of dicts
          - case_status: str
        """
        context = context or {}
        intent  = self._detect_intent(message.lower())
        return self._generate_response(intent, message, context)

    def _detect_intent(self, message: str) -> str:
        for intent, keywords in self.keywords.items():
            if any(kw in message for kw in keywords):
                return intent
        return 'default'

    def _generate_response(self, intent: str, message: str, context: dict) -> str:
        disease = context.get('predicted_disease', 'the predicted condition')
        drugs   = context.get('drug_recommendations', [])
        case_status = context.get('case_status', '')

        if intent == 'greeting':
            return self.responses['greeting'][0]

        elif intent == 'disease_explain':
            return self.responses['disease_explain'].format(
                disease=disease,
                description=self._get_disease_description(disease),
            )

        elif intent == 'drug_explain' and drugs:
            drug = drugs[0]
            return self.responses['drug_explain'].format(
                drug=drug.get('drug_name', 'N/A'),
                brand=drug.get('egyptian_brand', 'N/A'),
                disease=disease,
                role=drug.get('role', 'N/A'),
                dosage=drug.get('dosage', 'N/A'),
                side_effects=drug.get('key_side_effects', 'N/A'),
                avoid_in=drug.get('avoid_in', 'N/A'),
            )

        elif intent == 'side_effects' and drugs:
            drug = drugs[0]
            return self.responses['side_effects'].format(
                drug=drug.get('drug_name', 'N/A'),
                side_effects=drug.get('key_side_effects', 'N/A'),
            )

        elif intent == 'dosage' and drugs:
            drug = drugs[0]
            return self.responses['dosage'].format(
                drug=drug.get('drug_name', 'N/A'),
                dosage=drug.get('dosage', 'N/A'),
            )

        elif intent == 'waiting':
            if case_status == 'approved':
                return self.responses['approved']
            return self.responses['waiting']

        elif intent == 'approved':
            return self.responses['approved']

        elif intent == 'safety_warning':
            return self.responses['safety_warning']

        else:
            return self.responses['default']

    def _get_disease_description(self, disease: str) -> str:
        """Very brief disease descriptions for common conditions."""
        descriptions = {
            'Diabetes':               'is a metabolic disorder affecting how your body uses blood sugar.',
            'Hypertension':           'is high blood pressure, which can strain your heart and blood vessels.',
            'Pneumonia':              'is an infection that inflames the air sacs in one or both lungs.',
            'Tuberculosis':           'is a serious bacterial infection mainly affecting the lungs.',
            'Common Cold':            'is a viral infection of the upper respiratory tract.',
            'Dengue':                 'is a mosquito-borne viral infection causing fever and severe joint pain.',
            'Malaria':                'is a life-threatening disease caused by parasites transmitted by mosquitoes.',
            'Typhoid':                'is a bacterial infection spread through contaminated food or water.',
            'Migraine':               'causes intense, recurring headaches often with nausea and light sensitivity.',
            'Arthritis':              'causes inflammation and pain in the joints.',
        }
        for key, desc in descriptions.items():
            if key.lower() in disease.lower():
                return desc
        return 'is a medical condition identified by our AI system.'

    # ── LLM upgrade hook ─────────────────────────────────────────────────
    def _call_llm(self, prompt: str) -> str:
        """
        FUTURE: Replace this with OpenAI / Gemini API call.

        Example OpenAI integration:
          import openai
          response = openai.chat.completions.create(
              model='gpt-4',
              messages=[{'role': 'user', 'content': prompt}]
          )
          return response.choices[0].message.content
        """
        raise NotImplementedError('LLM backend not yet configured.')
