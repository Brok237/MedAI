// lib/screens/add_symptoms_screen.dart
// Patient selects symptoms and submits to backend.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/case_provider.dart';
import '../app_theme.dart';
import 'ai_diagnosis_results_screen.dart';

class AddSymptomsScreen extends StatefulWidget {
  const AddSymptomsScreen({super.key});
  @override
  State<AddSymptomsScreen> createState() => _AddSymptomsScreenState();
}

class _AddSymptomsScreenState extends State<AddSymptomsScreen> {
  final Set<String> _selected = {};
  final _complaintCtrl = TextEditingController();
  bool _submitting = false;
  static const Map<String, String> categoryLabels = {
    'General Symptoms': 'الأعراض العامة (General Symptoms)',
    'Skin & Dermatology': 'الأمراض الجلدية (Skin & Dermatology)',
    'Respiratory & ENT': 'الجهاز التنفسي والأنف والأذن (Respiratory & ENT)',
    'Digestive System': 'الجهاز الهضمي (Digestive System)',
    'Liver & Jaundice': 'الكبد واليرقان (Liver & Jaundice)',
    'Muscles, Bones & Joints':
        'العضلات والعظام والمفاصل (Muscles, Bones & Joints)',
    'Neurological': 'الأعصاب (Neurological)',
    'Eyes & Vision': 'العين والرؤية (Eyes & Vision)',
    'Urinary System': 'الجهاز البولي (Urinary System)',
    'Mental & Psychological': 'النفسية والعقلية (Mental & Psychological)',
    'Endocrine & Metabolic': 'الغدد والتمثيل الغذائي (Endocrine & Metabolic)',
    'Heart & Circulation': 'القلب والدورة الدموية (Heart & Circulation)',
    'Anal & Rectal': 'الشرج والمستقيم (Anal & Rectal)',
    'Reproductive & Sexual Health': 'الصحة الإنجابية (Reproductive Health)',
    'Infections & Risk Factors':
        'العدوى وعوامل الخطر (Infections & Risk Factors)',
  };
  String symptomLabel(String symptom) {
    return '${symptom.replaceAll('_', ' ')}\n(${_translateSymptom(symptom)})';
  }

  String _translateSymptom(String symptom) {
    const translations = {
      // General Symptoms
      'fatigue': 'إرهاق',
      'high_fever': 'حمى شديدة',
      'mild_fever': 'حمى خفيفة',
      'chills': 'قشعريرة',
      'shivering': 'رعشة',
      'sweating': 'تعرق',
      'dehydration': 'جفاف',
      'malaise': 'شعور عام بالتعب',
      'lethargy': 'خمول',
      'weakness_in_limbs': 'ضعف في الأطراف',
      'weakness_of_one_body_side': 'ضعف في أحد جانبي الجسم',

      // Skin & Dermatology
      'itching': 'حكة',
      'skin_rash': 'طفح جلدي',
      'nodal_skin_eruptions': 'نتوءات جلدية',
      'pus_filled_pimples': 'بثور مليئة بالصديد',
      'blackheads': 'رؤوس سوداء',
      'scarring': 'ندوب',
      'skin_peeling': 'تقشر الجلد',
      'silver_like_dusting': 'قشور فضية على الجلد',
      'small_dents_in_nails': 'حفر صغيرة في الأظافر',
      'inflammatory_nails': 'التهاب الأظافر',
      'blister': 'بثور جلدية',
      'red_sore_around_nose': 'تقرحات حمراء حول الأنف',
      'yellow_crust_ooze': 'إفرازات وقشور صفراء',
      'bruising': 'كدمات',

      // Respiratory & ENT
      'continuous_sneezing': 'عطس مستمر',
      'cough': 'سعال',
      'breathlessness': 'ضيق التنفس',
      'phlegm': 'بلغم',
      'throat_irritation': 'تهيج الحلق',
      'patches_in_throat': 'بقع في الحلق',
      'runny_nose': 'سيلان الأنف',
      'congestion': 'احتقان',
      'sinus_pressure': 'ضغط الجيوب الأنفية',
      'mucoid_sputum': 'بلغم مخاطي',
      'rusty_sputum': 'بلغم بلون الصدأ',
      'blood_in_sputum': 'دم في البلغم',
      'loss_of_smell': 'فقدان حاسة الشم',

      // Digestive System
      'stomach_pain': 'ألم المعدة',
      'acidity': 'حموضة',
      'vomiting': 'قيء',
      'indigestion': 'عسر هضم',
      'nausea': 'غثيان',
      'loss_of_appetite': 'فقدان الشهية',
      'abdominal_pain': 'ألم البطن',
      'diarrhoea': 'إسهال',
      'constipation': 'إمساك',
      'belly_pain': 'ألم البطن',
      'passage_of_gases': 'غازات متكررة',
      'internal_itching': 'حكة داخلية',
      'stomach_bleeding': 'نزيف بالمعدة',
      'distention_of_abdomen': 'انتفاخ البطن',
      'swelling_of_stomach': 'تورم البطن',

      // Liver & Jaundice
      'yellowish_skin': 'اصفرار الجلد',
      'yellow_urine': 'بول أصفر داكن',
      'yellowing_of_eyes': 'اصفرار العينين',
      'dark_urine': 'بول داكن',
      'acute_liver_failure': 'فشل كبدي حاد',
      'fluid_overload': 'احتباس السوائل',
      'history_of_alcohol_consumption': 'تاريخ من تناول الكحول',

      // Muscles, Bones & Joints
      'joint_pain': 'ألم المفاصل',
      'back_pain': 'ألم الظهر',
      'neck_pain': 'ألم الرقبة',
      'knee_pain': 'ألم الركبة',
      'hip_joint_pain': 'ألم مفصل الورك',
      'muscle_pain': 'ألم العضلات',
      'muscle_weakness': 'ضعف العضلات',
      'swelling_joints': 'تورم المفاصل',
      'movement_stiffness': 'تيبس الحركة',
      'stiff_neck': 'تيبس الرقبة',
      'cramps': 'تشنجات',
      'painful_walking': 'ألم أثناء المشي',

      // Neurological
      'headache': 'صداع',
      'dizziness': 'دوخة',
      'spinning_movements': 'إحساس بالدوران',
      'loss_of_balance': 'فقدان التوازن',
      'unsteadiness': 'عدم الثبات',
      'slurred_speech': 'تلعثم في الكلام',
      'altered_sensorium': 'اضطراب الوعي',
      'coma': 'غيبوبة',
      'lack_of_concentration': 'ضعف التركيز',

      // Eyes & Vision
      'sunken_eyes': 'غؤور العينين',
      'pain_behind_the_eyes': 'ألم خلف العينين',
      'redness_of_eyes': 'احمرار العينين',
      'watering_from_eyes': 'دموع بالعين',
      'blurred_and_distorted_vision': 'تشوش وتشوه الرؤية',
      'visual_disturbances': 'اضطرابات الرؤية',

      // Urinary System
      'bladder_discomfort': 'انزعاج بالمثانة',
      'continuous_feel_of_urine': 'إحساس دائم بالحاجة للتبول',
      'polyuria': 'كثرة التبول',

      // Mental & Psychological
      'anxiety': 'قلق',
      'mood_swings': 'تقلبات مزاجية',
      'restlessness': 'توتر وعدم ارتياح',
      'depression': 'اكتئاب',
      'irritability': 'عصبية',

      // Endocrine & Metabolic
      'weight_gain': 'زيادة الوزن',
      'weight_loss': 'فقدان الوزن',
      'irregular_sugar_level': 'اضطراب مستوى السكر',
      'cold_hands_and_feets': 'برودة اليدين والقدمين',
      'obesity': 'سمنة',
      'enlarged_thyroid': 'تضخم الغدة الدرقية',
      'brittle_nails': 'هشاشة الأظافر',
      'swollen_extremeties': 'تورم الأطراف',
      'excessive_hunger': 'جوع مفرط',
      'increased_appetite': 'زيادة الشهية',

      // Heart & Circulation
      'chest_pain': 'ألم الصدر',
      'fast_heart_rate': 'تسارع ضربات القلب',
      'palpitations': 'خفقان القلب',
      'prominent_veins_on_calf': 'بروز أوردة الساق',
      'swollen_blood_vessels': 'تورم الأوعية الدموية',
      'swollen_legs': 'تورم الساقين',
      'puffy_face_and_eyes': 'انتفاخ الوجه والعينين',

      // Anal & Rectal
      'pain_during_bowel_movements': 'ألم أثناء التبرز',
      'pain_in_anal_region': 'ألم بمنطقة الشرج',
      'bloody_stool': 'براز دموي',
      'irritation_in_anus': 'تهيج في الشرج',

      // Reproductive & Sexual Health
      'abnormal_menstruation': 'عدم انتظام الدورة الشهرية',
      'extra_marital_contacts': 'علاقات جنسية متعددة',

      // Infections & Risk Factors
      'swelled_lymph_nodes': 'تورم الغدد الليمفاوية',
      'toxic_look_(typhos)': 'مظهر مرضي شديد',
      'family_history': 'تاريخ مرضي عائلي',
      'receiving_blood_transfusion': 'نقل دم سابق',
      'receiving_unsterile_injections': 'حقن غير معقمة',
    };

    return translations[symptom] ?? symptom.replaceAll('_', ' ');
  }

  // The 41-disease symptom list (subset of common ones displayed in UI)
  static const Map<String, List<String>> _symptomCategories = {
    'General Symptoms': [
      'fatigue',
      'high_fever',
      'mild_fever',
      'chills',
      'shivering',
      'sweating',
      'dehydration',
      'malaise',
      'lethargy',
      'weakness_in_limbs',
      'weakness_of_one_body_side',
    ],
    'Skin & Dermatology': [
      'itching',
      'skin_rash',
      'nodal_skin_eruptions',
      'pus_filled_pimples',
      'blackheads',
      'scarring',
      'skin_peeling',
      'silver_like_dusting',
      'small_dents_in_nails',
      'inflammatory_nails',
      'blister',
      'red_sore_around_nose',
      'yellow_crust_ooze',
      'bruising',
    ],
    'Respiratory & ENT': [
      'continuous_sneezing',
      'cough',
      'breathlessness',
      'phlegm',
      'throat_irritation',
      'patches_in_throat',
      'runny_nose',
      'congestion',
      'sinus_pressure',
      'mucoid_sputum',
      'rusty_sputum',
      'blood_in_sputum',
      'loss_of_smell',
    ],
    'Digestive System': [
      'stomach_pain',
      'acidity',
      'vomiting',
      'indigestion',
      'nausea',
      'loss_of_appetite',
      'abdominal_pain',
      'diarrhoea',
      'constipation',
      'belly_pain',
      'passage_of_gases',
      'internal_itching',
      'stomach_bleeding',
      'distention_of_abdomen',
      'swelling_of_stomach',
    ],
    'Liver & Jaundice': [
      'yellowish_skin',
      'yellow_urine',
      'yellowing_of_eyes',
      'dark_urine',
      'acute_liver_failure',
      'fluid_overload',
      'history_of_alcohol_consumption',
    ],
    'Muscles, Bones & Joints': [
      'joint_pain',
      'back_pain',
      'neck_pain',
      'knee_pain',
      'hip_joint_pain',
      'muscle_pain',
      'muscle_weakness',
      'swelling_joints',
      'movement_stiffness',
      'stiff_neck',
      'cramps',
      'painful_walking',
    ],
    'Neurological': [
      'headache',
      'dizziness',
      'spinning_movements',
      'loss_of_balance',
      'unsteadiness',
      'slurred_speech',
      'altered_sensorium',
      'coma',
      'lack_of_concentration',
    ],
    'Eyes & Vision': [
      'sunken_eyes',
      'pain_behind_the_eyes',
      'redness_of_eyes',
      'watering_from_eyes',
      'blurred_and_distorted_vision',
      'visual_disturbances',
    ],
    'Urinary System': [
      'bladder_discomfort',
      'continuous_feel_of_urine',
      'polyuria',
    ],
    'Mental & Psychological': [
      'anxiety',
      'mood_swings',
      'restlessness',
      'depression',
      'irritability',
    ],
    'Endocrine & Metabolic': [
      'weight_gain',
      'weight_loss',
      'irregular_sugar_level',
      'cold_hands_and_feets',
      'obesity',
      'enlarged_thyroid',
      'brittle_nails',
      'swollen_extremeties',
      'excessive_hunger',
      'increased_appetite',
    ],
    'Heart & Circulation': [
      'chest_pain',
      'fast_heart_rate',
      'palpitations',
      'prominent_veins_on_calf',
      'swollen_blood_vessels',
      'swollen_legs',
      'puffy_face_and_eyes',
    ],
    'Anal & Rectal': [
      'pain_during_bowel_movements',
      'pain_in_anal_region',
      'bloody_stool',
      'irritation_in_anus',
    ],
    'Reproductive & Sexual Health': [
      'abnormal_menstruation',
      'extra_marital_contacts',
    ],
    'Infections & Risk Factors': [
      'swelled_lymph_nodes',
      'toxic_look_(typhos)',
      'family_history',
      'receiving_blood_transfusion',
      'receiving_unsterile_injections',
    ],
  };

  Future<void> _submit() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one symptom.')));
      return;
    }
    setState(() => _submitting = true);
    final result = await context.read<CaseProvider>().submitCase(
          symptoms: _selected.toList(),
          chiefComplaint: _complaintCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result != null) {
      final caseId = result['case_id'];
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => AIDiagnosisResultsScreen(caseId: caseId)));
    } else {
      final err = context.read<CaseProvider>().error ?? 'Submission failed';
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
          title: const Text('Submit Symptoms'),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
                controller: _complaintCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                    hintText:
                        'Describe your complaint in your own words (optional)...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white))),
        if (_selected.isNotEmpty)
          Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3))),
              child: Text('${_selected.length} symptom(s) selected',
                  style: TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.w600))),
        const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Select all symptoms you are experiencing:',
                style: TextStyle(fontWeight: FontWeight.w500))),
        Expanded(
            child: ListView(
          children: _symptomCategories.entries.map((category) {
            return ExpansionTile(
              title: Text(
                categoryLabels[category.key] ?? category.key,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: category.value.map((symptom) {
                    final selected = _selected.contains(symptom);

                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _selected.remove(symptom);
                          } else {
                            _selected.add(symptom);
                          }
                        });
                      },
                      child: Container(
                        width: 150,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.primary : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppTheme.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          symptomLabel(symptom),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: selected ? Colors.white : Colors.black87,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
              ],
            );
          }).toList(),
        )),
        Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send, color: Colors.white),
                    label: Text(
                        _submitting ? 'Analyzing...' : 'Submit for Analysis',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)))))),
      ]),
    );
  }
}
