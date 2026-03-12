import 'package:flutter/material.dart';
import '../models/language.dart';
import '../models/quiz_type.dart';
import '../models/question.dart';
import '../theme/app_theme.dart';
import '../services/mms_tts_service.dart';

class AppState extends ChangeNotifier {
  Language? nativeLanguage;
  Language? targetLanguage;
  int currentLevel = 10;
  int totalXP = 2840;
  int streakDays = 12;
  double dailyProgress = 0.65;
  
  final List<Language> availableLanguages = [
    Language('om', 'Afaan Oromo', '🌐', 'Afaan Oromo'),
    Language('af', 'Afrikaans', '🌐', 'Afrikaans'),
    Language('ak', 'Akan / Twi', '🌐', 'Akan / Twi'),
    Language('sq', 'Albanian', '🌐', 'Albanian'),
    Language('am', 'Amharic', '🌐', 'Amharic'),
    Language('ar-DZ', 'Arabic (Algerian)', '🌐', 'Arabic (Algerian)'),
    Language('ar-EG', 'Arabic (Egyptian)', '🌐', 'Arabic (Egyptian)'),
    Language('ar-AE', 'Arabic (Gulf)', '🌐', 'Arabic (Gulf)'),
    Language('ar-IQ', 'Arabic (Iraqi)', '🌐', 'Arabic (Iraqi)'),
    Language('ar-LB', 'Arabic (Levantine)', '🌐', 'Arabic (Levantine)'),
    Language('ar-MA', 'Arabic (Maghrebi)', '🌐', 'Arabic (Maghrebi)'),
    Language('ar', 'Arabic (Modern Standard)', '🌐', 'Arabic (Modern Standard)'),
    Language('ar-SD', 'Arabic (Sudanese)', '🌐', 'Arabic (Sudanese)'),
    Language('ar-YE', 'Arabic (Yemeni)', '🌐', 'Arabic (Yemeni)'),
    Language('hy', 'Armenian', '🌐', 'Armenian'),
    Language('as', 'Assamese', '🌐', 'Assamese'),
    Language('ast', 'Asturian', '🌐', 'Asturian'),
    Language('ay', 'Aymara', '🌐', 'Aymara'),
    Language('awa', 'Awadhi', '🌐', 'Awadhi'),
    Language('az', 'Azerbaijani', '🌐', 'Azerbaijani'),
    Language('bm', 'Bambara', '🌐', 'Bambara'),
    Language('eu', 'Basque', '🌐', 'Basque'),
    Language('be', 'Belarusian', '🌐', 'Belarusian'),
    Language('bn', 'Bengali', '🌐', 'Bengali'),
    Language('bho', 'Bhojpuri', '🌐', 'Bhojpuri'),
    Language('brx', 'Bodo', '🌐', 'Bodo'),
    Language('bs', 'Bosnian', '🌐', 'Bosnian'),
    Language('brh', 'Brahui', '🌐', 'Brahui'),
    Language('br', 'Breton', '🌐', 'Breton'),
    Language('bg', 'Bulgarian', '🌐', 'Bulgarian'),
    Language('my', 'Burmese (Myanmar)', '🌐', 'Burmese (Myanmar)'),
    Language('yue', 'Cantonese', '🌐', 'Cantonese'),
    Language('ca', 'Catalan', '🌐', 'Catalan'),
    Language('ceb', 'Cebuano', '🌐', 'Cebuano'),
    Language('shu', 'Chadian Arabic', '🌐', 'Chadian Arabic'),
    Language('hne', 'Chhattisgarhi', '🌐', 'Chhattisgarhi'),
    Language('ny', 'Chichewa / Chewa', '🌐', 'Chichewa / Chewa'),
    Language('zh-CN', 'Chinese (Simplified)', '🌐', 'Chinese (Simplified)'),
    Language('zh-TW', 'Chinese (Traditional)', '🌐', 'Chinese (Traditional)'),
    Language('co', 'Corsican', '🌐', 'Corsican'),
    Language('hr', 'Croatian', '🌐', 'Croatian'),
    Language('cs', 'Czech', '🌐', 'Czech'),
    Language('da', 'Danish', '🌐', 'Danish'),
    Language('doi', 'Dogri', '🌐', 'Dogri'),
    Language('nl', 'Dutch', '🌐', 'Dutch'),
    Language('en-GB', 'English (UK)', '🌐', 'English (UK)'),
    Language('en-US', 'English (US)', '🌐', 'English (US)'),
    Language('eo', 'Esperanto', '🌐', 'Esperanto'),
    Language('et', 'Estonian', '🌐', 'Estonian'),
    Language('ee', 'Ewe', '🌐', 'Ewe'),
    Language('fan', 'Fang', '🌐', 'Fang'),
    Language('fo', 'Faroese', '🌐', 'Faroese'),
    Language('fil', 'Filipino / Tagalog', '🌐', 'Filipino / Tagalog'),
    Language('fi', 'Finnish', '🌐', 'Finnish'),
    Language('fr', 'French', '🌐', 'French'),
    Language('fr-CA', 'French (Canada)', '🌐', 'French (Canada)'),
    Language('fy', 'Frisian', '🌐', 'Frisian'),
    Language('ff', 'Fulani / Fula', '🌐', 'Fulani / Fula'),
    Language('gan', 'Gan Chinese', '🌐', 'Gan Chinese'),
    Language('gl', 'Galician', '🌐', 'Galician'),
    Language('ka', 'Georgian', '🌐', 'Georgian'),
    Language('de', 'German', '🌐', 'German'),
    Language('el', 'Greek', '🌐', 'Greek'),
    Language('gn', 'Guarani', '🌐', 'Guarani'),
    Language('gu', 'Gujarati', '🌐', 'Gujarati'),
    Language('hak', 'Hakka', '🌐', 'Hakka'),
    Language('ht', 'Haitian Creole', '🌐', 'Haitian Creole'),
    Language('bgc', 'Haryanvi', '🌐', 'Haryanvi'),
    Language('ha', 'Hausa', '🌐', 'Hausa'),
    Language('he', 'Hebrew', '🌐', 'Hebrew'),
    Language('hi', 'Hindi', '🌐', 'Hindi'),
    Language('hil', 'Hiligaynon', '🌐', 'Hiligaynon'),
    Language('hmn', 'Hmong', '🌐', 'Hmong'),
    Language('hu', 'Hungarian', '🌐', 'Hungarian'),
    Language('is', 'Icelandic', '🌐', 'Icelandic'),
    Language('ig', 'Igbo', '🌐', 'Igbo'),
    Language('ilo', 'Ilocano', '🌐', 'Ilocano'),
    Language('id', 'Indonesian', '🌐', 'Indonesian'),
    Language('ga', 'Irish (Gaeilge)', '🌐', 'Irish (Gaeilge)'),
    Language('xh', 'isiXhosa', '🌐', 'isiXhosa'),
    Language('it', 'Italian', '🌐', 'Italian'),
    Language('ja', 'Japanese', '🌐', 'Japanese'),
    Language('jv', 'Javanese', '🌐', 'Javanese'),
    Language('kab', 'Kabyle (Algerian Berber)', '🌐', 'Kabyle (Algerian Berber)'),
    Language('kn', 'Kannada', '🌐', 'Kannada'),
    Language('kr', 'Kanuri', '🌐', 'Kanuri'),
    Language('ks', 'Kashmiri', '🌐', 'Kashmiri'),
    Language('kk', 'Kazakh', '🌐', 'Kazakh'),
    Language('km', 'Khmer', '🌐', 'Khmer'),
    Language('kha', 'Khasi', '🌐', 'Khasi'),
    Language('ki', 'Kikuyu', '🌐', 'Kikuyu'),
    Language('rw', 'Kinyarwanda', '🌐', 'Kinyarwanda'),
    Language('rn', 'Kirundi', '🌐', 'Kirundi'),
    Language('kg', 'Kongo', '🌐', 'Kongo'),
    Language('kok', 'Konkani', '🌐', 'Konkani'),
    Language('ko', 'Korean', '🌐', 'Korean'),
    Language('kri', 'Krio (Sierra Leone)', '🌐', 'Krio (Sierra Leone)'),
    Language('ku', 'Kurdish', '🌐', 'Kurdish'),
    Language('kmr', 'Kurmanji (Northern Kurdish)', '🌐', 'Kurmanji (Northern Kurdish)'),
    Language('ky', 'Kyrgyz', '🌐', 'Kyrgyz'),
    Language('lo', 'Lao', '🌐', 'Lao'),
    Language('la', 'Latin', '🌐', 'Latin'),
    Language('lv', 'Latvian', '🌐', 'Latvian'),
    Language('ln', 'Lingala', '🌐', 'Lingala'),
    Language('lt', 'Lithuanian', '🌐', 'Lithuanian'),
    Language('lu', 'Luba-Katanga', '🌐', 'Luba-Katanga'),
    Language('lg', 'Luganda (Ganda)', '🌐', 'Luganda (Ganda)'),
    Language('lb', 'Luxembourgish', '🌐', 'Luxembourgish'),
    Language('mk', 'Macedonian', '🌐', 'Macedonian'),
    Language('mag', 'Magahi', '🌐', 'Magahi'),
    Language('mg', 'Malagasy', '🌐', 'Malagasy'),
    Language('mai', 'Maithili', '🌐', 'Maithili'),
    Language('ms', 'Malay', '🌐', 'Malay'),
    Language('ml', 'Malayalam', '🌐', 'Malayalam'),
    Language('mt', 'Maltese', '🌐', 'Maltese'),
    Language('mni', 'Manipuri (Meitei)', '🌐', 'Manipuri (Meitei)'),
    Language('mr', 'Marathi', '🌐', 'Marathi'),
    Language('mwr', 'Marwari', '🌐', 'Marwari'),
    Language('mi', 'Māori', '🌐', 'Māori'),
    Language('nan', 'Min Nan / Hokkien', '🌐', 'Min Nan / Hokkien'),
    Language('mn', 'Mongolian', '🌐', 'Mongolian'),
    Language('sr-ME', 'Montenegrin', '🌐', 'Montenegrin'),
    Language('lus', 'Mizo', '🌐', 'Mizo'),
    Language('ne', 'Nepali', '🌐', 'Nepali'),
    Language('nb-NO', 'Norwegian Bokmål', '🌐', 'Norwegian Bokmål'),
    Language('nn-NO', 'Norwegian Nynorsk', '🌐', 'Norwegian Nynorsk'),
    Language('oc', 'Occitan', '🌐', 'Occitan'),
    Language('or', 'Odia (Oriya)', '🌐', 'Odia (Oriya)'),
    Language('ps', 'Pashto', '🌐', 'Pashto'),
    Language('fa', 'Persian / Farsi', '🌐', 'Persian / Farsi'),
    Language('pl', 'Polish', '🌐', 'Polish'),
    Language('pt-BR', 'Portuguese (Brazil)', '🌐', 'Portuguese (Brazil)'),
    Language('pt-PT', 'Portuguese (Portugal)', '🌐', 'Portuguese (Portugal)'),
    Language('pa', 'Punjabi', '🌐', 'Punjabi'),
    Language('qu', 'Quechua (Standard)', '🌐', 'Quechua (Standard)'),
    Language('raj', 'Rajasthani', '🌐', 'Rajasthani'),
    Language('ro', 'Romanian', '🌐', 'Romanian'),
    Language('rm', 'Romansh', '🌐', 'Romansh'),
    Language('ru', 'Russian', '🌐', 'Russian'),
    Language('sm', 'Samoan', '🌐', 'Samoan'),
    Language('sa', 'Sanskrit', '🌐', 'Sanskrit'),
    Language('sat', 'Santali', '🌐', 'Santali'),
    Language('skr', 'Saraiki', '🌐', 'Saraiki'),
    Language('gd', 'Scottish Gaelic', '🌐', 'Scottish Gaelic'),
    Language('sr', 'Serbian', '🌐', 'Serbian'),
    Language('st', 'Sesotho', '🌐', 'Sesotho'),
    Language('tn', 'Setswana', '🌐', 'Setswana'),
    Language('sn', 'Shona', '🌐', 'Shona'),
    Language('scn', 'Sicilian', '🌐', 'Sicilian'),
    Language('sd', 'Sindhi', '🌐', 'Sindhi'),
    Language('si', 'Sinhala', '🌐', 'Sinhala'),
    Language('sk', 'Slovak', '🌐', 'Slovak'),
    Language('sl', 'Slovenian', '🌐', 'Slovenian'),
    Language('so', 'Somali', '🌐', 'Somali'),
    Language('es-MX', 'Spanish (Latin America / Mexico)', '🌐', 'Spanish (Latin America / Mexico)'),
    Language('es-ES', 'Spanish (Spain)', '🌐', 'Spanish (Spain)'),
    Language('su', 'Sundanese', '🌐', 'Sundanese'),
    Language('sw', 'Swahili', '🌐', 'Swahili'),
    Language('sv', 'Swedish', '🌐', 'Swedish'),
    Language('tg', 'Tajik', '🌐', 'Tajik'),
    Language('zgh', 'Tamazight (Standard Moroccan Berber)', '🌐', 'Tamazight (Standard Moroccan Berber)'),
    Language('ta', 'Tamil', '🌐', 'Tamil'),
    Language('tt', 'Tatar', '🌐', 'Tatar'),
    Language('te', 'Telugu', '🌐', 'Telugu'),
    Language('th', 'Thai', '🌐', 'Thai'),
    Language('ti', 'Tigrinya', '🌐', 'Tigrinya'),
    Language('tpi', 'Tok Pisin', '🌐', 'Tok Pisin'),
    Language('to', 'Tongan', '🌐', 'Tongan'),
    Language('tcy', 'Tulu', '🌐', 'Tulu'),
    Language('tr', 'Turkish', '🌐', 'Turkish'),
    Language('uk', 'Ukrainian', '🌐', 'Ukrainian'),
    Language('ur', 'Urdu', '🌐', 'Urdu'),
    Language('ug', 'Uyghur', '🌐', 'Uyghur'),
    Language('uz', 'Uzbek', '🌐', 'Uzbek'),
    Language('vec', 'Venetian', '🌐', 'Venetian'),
    Language('vi', 'Vietnamese', '🌐', 'Vietnamese'),
    Language('war', 'Waray', '🌐', 'Waray'),
    Language('cy', 'Welsh', '🌐', 'Welsh'),
    Language('wo', 'Wolof', '🌐', 'Wolof'),
    Language('wuu', 'Wu Chinese (Shanghainese)', '🌐', 'Wu Chinese (Shanghainese)'),
    Language('hsn', 'Xiang Chinese', '🌐', 'Xiang Chinese'),
    Language('ts', 'Xitsonga', '🌐', 'Xitsonga'),
    Language('yi', 'Yiddish', '🌐', 'Yiddish'),
    Language('yo', 'Yoruba', '🌐', 'Yoruba'),
    Language('zu', 'Zulu', '🌐', 'Zulu'),
  ];
  
  final List<QuizType> quizTypes = [
    QuizType('vocab', 'Vocabulary', 'Master words with flashcards', 
        Icons.style, AppColors.primaryTeal, questionCount: 15),
    QuizType('sentence', 'Sentences', 'Build grammar skills', 
        Icons.text_fields, AppColors.accentCoral, questionCount: 10),
    QuizType('pronunciation', 'Pronunciation', 'Perfect your accent', 
        Icons.mic, AppColors.accentOrange, questionCount: 8),
    QuizType('listening', 'Listening', 'Train your ears', 
        Icons.hearing, Colors.purple, questionCount: 12),
  ];
  
  List<Question> getQuestions(String type) {
    if (type == 'vocab') {
      return [
        Question(
          id: '1',
          type: 'vocabulary',
          question: 'What is "Apple" in Spanish?',
          correctAnswer: 'Manzana',
          options: ['Manzana', 'Banana', 'Naranja', 'Uva'],
          hint: 'Red fruit',
        ),
        Question(
          id: '2',
          type: 'vocabulary',
          question: 'Select the translation for "House"',
          correctAnswer: 'Casa',
          options: ['Casa', 'Coche', 'Perro', 'Gato'],
          hint: 'Where you live',
        ),
        Question(
          id: '3',
          type: 'vocabulary',
          question: 'What does "Biblioteca" mean?',
          correctAnswer: 'Library',
          options: ['Bookstore', 'Library', 'School', 'Office'],
          hint: 'Place with many books',
        ),
      ];
    } else if (type == 'sentence') {
      return [
        Question(
          id: '1',
          type: 'sentence',
          question: 'Complete: Yo ___ estudiante.',
          correctAnswer: 'soy',
          options: ['soy', 'eres', 'es', 'somos'],
          hint: 'I am a student',
        ),
        Question(
          id: '2',
          type: 'sentence',
          question: 'Translate: The cat eats fish',
          correctAnswer: 'El gato come pescado',
          options: ['El gato come pescado', 'El perro come carne', 
                   'El gato bebe agua', 'El pájaro vuela alto'],
          hint: 'Gato = Cat',
        ),
      ];
    }
    return [];
  }
  
  bool isTtsDownloading = false;
  double ttsDownloadProgress = 0.0;
  final MmsTtsService _ttsService = MmsTtsService();

  void selectLanguages(Language native, Language target) {
    nativeLanguage = native;
    targetLanguage = target;
    notifyListeners();
    
    // Trigger TTS download for the selected target language
    _downloadTtsModelForLanguage(target.code);
  }
  
  Future<void> _downloadTtsModelForLanguage(String langCode) async {
    // Only download if missing
    final hasModel = await _ttsService.isModelDownloaded(langCode);
    if (!hasModel) {
      isTtsDownloading = true;
      ttsDownloadProgress = 0.0;
      notifyListeners();

      try {
        await _ttsService.downloadModel(
          langCode,
          onProgress: (progress) {
            ttsDownloadProgress = progress;
            notifyListeners();
          },
        );
      } catch (e) {
        debugPrint('Failed to download TTS for \$langCode: \$e');
      } finally {
        isTtsDownloading = false;
        notifyListeners();
      }
    }
  }
  
  void addXP(int points) {
    totalXP += points;
    notifyListeners();
  }
  
  void incrementStreak() {
    streakDays++;
    notifyListeners();
  }
}
