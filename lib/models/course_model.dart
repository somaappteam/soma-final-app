class CourseModel {
  final String id;
  final String courseId;
  final String userId;
  final String nativeLanguage;
  final String nativeLanguageName;
  final String nativeLanguageFlag;
  final String targetLanguage;
  final String targetLanguageName;
  final String targetLanguageFlag;
  final int currentLevel;
  final int totalXP;
  final double progress;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastAccessedAt;

  CourseModel({
    required this.id,
    required this.courseId,
    required this.userId,
    required this.nativeLanguage,
    required this.nativeLanguageName,
    required this.nativeLanguageFlag,
    required this.targetLanguage,
    required this.targetLanguageName,
    required this.targetLanguageFlag,
    this.currentLevel = 1,
    this.totalXP = 0,
    this.progress = 0.0,
    this.isActive = true,
    required this.createdAt,
    required this.lastAccessedAt,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'],
      courseId: json['course_id'] ?? '',
      userId: json['user_id'],
      nativeLanguage: json['native_language'],
      nativeLanguageName: json['native_language_name'],
      nativeLanguageFlag: json['native_language_flag'],
      targetLanguage: json['target_language'],
      targetLanguageName: json['target_language_name'],
      targetLanguageFlag: json['target_language_flag'],
      currentLevel: json['current_level'] ?? 1,
      totalXP: json['total_xp'] ?? 0,
      progress: (json['progress'] ?? 0.0).toDouble(),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      lastAccessedAt: DateTime.parse(json['last_accessed_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'user_id': userId,
      'native_language': nativeLanguage,
      'native_language_name': nativeLanguageName,
      'native_language_flag': nativeLanguageFlag,
      'target_language': targetLanguage,
      'target_language_name': targetLanguageName,
      'target_language_flag': targetLanguageFlag,
      'current_level': currentLevel,
      'total_xp': totalXP,
      'progress': progress,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'last_accessed_at': lastAccessedAt.toIso8601String(),
    };
  }

  CourseModel copyWith({
    String? id,
    String? courseId,
    String? userId,
    String? nativeLanguage,
    String? nativeLanguageName,
    String? nativeLanguageFlag,
    String? targetLanguage,
    String? targetLanguageName,
    String? targetLanguageFlag,
    int? currentLevel,
    int? totalXP,
    double? progress,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastAccessedAt,
  }) {
    return CourseModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      userId: userId ?? this.userId,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      nativeLanguageName: nativeLanguageName ?? this.nativeLanguageName,
      nativeLanguageFlag: nativeLanguageFlag ?? this.nativeLanguageFlag,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      targetLanguageName: targetLanguageName ?? this.targetLanguageName,
      targetLanguageFlag: targetLanguageFlag ?? this.targetLanguageFlag,
      currentLevel: currentLevel ?? this.currentLevel,
      totalXP: totalXP ?? this.totalXP,
      progress: progress ?? this.progress,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    );
  }
}

class LanguageModel {
  final String code;
  final String name;
  final String flag;
  final String nativeName;

  LanguageModel({
    required this.code,
    required this.name,
    required this.flag,
    required this.nativeName,
  });

  static final List<LanguageModel> availableLanguages = [
    // A
    LanguageModel(code: 'om', name: 'Afaan Oromo', flag: '🇪🇹', nativeName: 'Afaan Oromo'),
    LanguageModel(code: 'af', name: 'Afrikaans', flag: '🇿🇦', nativeName: 'Afrikaans'),
    LanguageModel(code: 'ak', name: 'Akan / Twi', flag: '🇬🇭', nativeName: 'Akan'),
    LanguageModel(code: 'sq', name: 'Albanian', flag: '🇦🇱', nativeName: 'Shqip'),
    LanguageModel(code: 'am', name: 'Amharic', flag: '🇪🇹', nativeName: 'አማርኛ'),
    LanguageModel(code: 'ar', name: 'Arabic (Modern Standard)', flag: '🇸🇦', nativeName: 'العربية'),
    LanguageModel(code: 'ar-DZ', name: 'Arabic (Algerian)', flag: '🇩🇿', nativeName: 'الدارجة الجزائرية'),
    LanguageModel(code: 'ar-EG', name: 'Arabic (Egyptian)', flag: '🇪🇬', nativeName: 'اللهجة المصرية'),
    LanguageModel(code: 'ar-AE', name: 'Arabic (Gulf)', flag: '🇦🇪', nativeName: 'اللهجة الخليجية'),
    LanguageModel(code: 'ar-IQ', name: 'Arabic (Iraqi)', flag: '🇮🇶', nativeName: 'اللهجة العراقية'),
    LanguageModel(code: 'ar-LB', name: 'Arabic (Levantine)', flag: '🇱🇧', nativeName: 'اللهجة الشامية'),
    LanguageModel(code: 'ar-MA', name: 'Arabic (Maghrebi)', flag: '🇲🇦', nativeName: 'اللهجة المغربية'),
    LanguageModel(code: 'ar-SD', name: 'Arabic (Sudanese)', flag: '🇸🇩', nativeName: 'اللهجة السودانية'),
    LanguageModel(code: 'ar-YE', name: 'Arabic (Yemeni)', flag: '🇾🇪', nativeName: 'اللهجة اليمنية'),
    LanguageModel(code: 'hy', name: 'Armenian', flag: '🇦🇲', nativeName: 'Հայերեն'),
    LanguageModel(code: 'as', name: 'Assamese', flag: '🇮🇳', nativeName: 'অসমীয়া'),
    LanguageModel(code: 'ast', name: 'Asturian', flag: '🇪🇸', nativeName: 'Asturianu'),
    LanguageModel(code: 'ay', name: 'Aymara', flag: '🇧🇴', nativeName: 'Aymar aru'),
    LanguageModel(code: 'awa', name: 'Awadhi', flag: '🇮🇳', nativeName: 'अवधी'),
    LanguageModel(code: 'az', name: 'Azerbaijani', flag: '🇦🇿', nativeName: 'Azərbaycan dili'),
    // B
    LanguageModel(code: 'bm', name: 'Bambara', flag: '🇲🇱', nativeName: 'Bamanankan'),
    LanguageModel(code: 'eu', name: 'Basque', flag: '🇪🇸', nativeName: 'Euskara'),
    LanguageModel(code: 'be', name: 'Belarusian', flag: '🇧🇾', nativeName: 'Беларуская'),
    LanguageModel(code: 'bn', name: 'Bengali', flag: '🇧🇩', nativeName: 'বাংলা'),
    LanguageModel(code: 'bho', name: 'Bhojpuri', flag: '🇮🇳', nativeName: 'भोजपुरी'),
    LanguageModel(code: 'brx', name: 'Bodo', flag: '🇮🇳', nativeName: 'बड़ो'),
    LanguageModel(code: 'bs', name: 'Bosnian', flag: '🇧🇦', nativeName: 'Bosanski'),
    LanguageModel(code: 'brh', name: 'Brahui', flag: '🇵🇰', nativeName: 'براہوئی'),
    LanguageModel(code: 'br', name: 'Breton', flag: '🇫🇷', nativeName: 'Brezhoneg'),
    LanguageModel(code: 'bg', name: 'Bulgarian', flag: '🇧🇬', nativeName: 'Български'),
    LanguageModel(code: 'my', name: 'Burmese', flag: '🇲🇲', nativeName: 'မြန်မာဘာသာ'),
    // C
    LanguageModel(code: 'yue', name: 'Cantonese', flag: '🇭🇰', nativeName: '廣東話'),
    LanguageModel(code: 'ca', name: 'Catalan', flag: '🇪🇸', nativeName: 'Català'),
    LanguageModel(code: 'ceb', name: 'Cebuano', flag: '🇵🇭', nativeName: 'Cebuano'),
    LanguageModel(code: 'shu', name: 'Chadian Arabic', flag: '🇹🇩', nativeName: 'لهجة تشادية'),
    LanguageModel(code: 'hne', name: 'Chhattisgarhi', flag: '🇮🇳', nativeName: 'छत्तीसगढ़ी'),
    LanguageModel(code: 'ny', name: 'Chichewa', flag: '🇲🇼', nativeName: 'Chichewa'),
    LanguageModel(code: 'zh-CN', name: 'Chinese (Simplified)', flag: '🇨🇳', nativeName: '简体中文'),
    LanguageModel(code: 'zh-TW', name: 'Chinese (Traditional)', flag: '🇹🇼', nativeName: '繁體中文'),
    LanguageModel(code: 'co', name: 'Corsican', flag: '🇫🇷', nativeName: 'Corsu'),
    LanguageModel(code: 'hr', name: 'Croatian', flag: '🇭🇷', nativeName: 'Hrvatski'),
    LanguageModel(code: 'cs', name: 'Czech', flag: '🇨🇿', nativeName: 'Čeština'),
    // D
    LanguageModel(code: 'da', name: 'Danish', flag: '🇩🇰', nativeName: 'Dansk'),
    LanguageModel(code: 'doi', name: 'Dogri', flag: '🇮🇳', nativeName: 'डोगरी'),
    LanguageModel(code: 'nl', name: 'Dutch', flag: '🇳🇱', nativeName: 'Nederlands'),
    // E
    LanguageModel(code: 'en-US', name: 'English (US)', flag: '🇺🇸', nativeName: 'English'),
    LanguageModel(code: 'en-GB', name: 'English (UK)', flag: '🇬🇧', nativeName: 'English'),
    LanguageModel(code: 'eo', name: 'Esperanto', flag: '🌍', nativeName: 'Esperanto'),
    LanguageModel(code: 'et', name: 'Estonian', flag: '🇪🇪', nativeName: 'Eesti'),
    LanguageModel(code: 'ee', name: 'Ewe', flag: '🇹🇬', nativeName: 'Eʋegbe'),
    // F
    LanguageModel(code: 'fan', name: 'Fang', flag: '🇬🇶', nativeName: 'Fang'),
    LanguageModel(code: 'fo', name: 'Faroese', flag: '🇫🇴', nativeName: 'Føroyskt'),
    LanguageModel(code: 'fil', name: 'Filipino / Tagalog', flag: '🇵🇭', nativeName: 'Filipino'),
    LanguageModel(code: 'fi', name: 'Finnish', flag: '🇫🇮', nativeName: 'Suomi'),
    LanguageModel(code: 'fr', name: 'French', flag: '🇫🇷', nativeName: 'Français'),
    LanguageModel(code: 'fr-CA', name: 'French (Canada)', flag: '🇨🇦', nativeName: 'Français canadien'),
    LanguageModel(code: 'fy', name: 'Frisian', flag: '🇳🇱', nativeName: 'Frysk'),
    LanguageModel(code: 'ff', name: 'Fulani', flag: '🇸🇳', nativeName: 'Pulaar'),
    // G
    LanguageModel(code: 'gan', name: 'Gan Chinese', flag: '🇨🇳', nativeName: '赣语'),
    LanguageModel(code: 'gl', name: 'Galician', flag: '🇪🇸', nativeName: 'Galego'),
    LanguageModel(code: 'ka', name: 'Georgian', flag: '🇬🇪', nativeName: 'ქართული'),
    LanguageModel(code: 'de', name: 'German', flag: '🇩🇪', nativeName: 'Deutsch'),
    LanguageModel(code: 'el', name: 'Greek', flag: '🇬🇷', nativeName: 'Ελληνικά'),
    LanguageModel(code: 'gn', name: 'Guarani', flag: '🇵🇾', nativeName: 'Avañe\'ẽ'),
    LanguageModel(code: 'gu', name: 'Gujarati', flag: '🇮🇳', nativeName: 'ગુજરાતી'),
    // H
    LanguageModel(code: 'hak', name: 'Hakka', flag: '🇨🇳', nativeName: '客家话'),
    LanguageModel(code: 'ht', name: 'Haitian Creole', flag: '🇭🇹', nativeName: 'Kreyòl ayisyen'),
    LanguageModel(code: 'bgc', name: 'Haryanvi', flag: '🇮🇳', nativeName: 'हरियाणवी'),
    LanguageModel(code: 'ha', name: 'Hausa', flag: '🇳🇬', nativeName: 'Hausa'),
    LanguageModel(code: 'he', name: 'Hebrew', flag: '🇮🇱', nativeName: 'עברית'),
    LanguageModel(code: 'hi', name: 'Hindi', flag: '🇮🇳', nativeName: 'हिन्दी'),
    LanguageModel(code: 'hil', name: 'Hiligaynon', flag: '🇵🇭', nativeName: 'Hiligaynon'),
    LanguageModel(code: 'hmn', name: 'Hmong', flag: '🇱🇦', nativeName: 'Hmoob'),
    LanguageModel(code: 'hu', name: 'Hungarian', flag: '🇭🇺', nativeName: 'Magyar'),
    // I
    LanguageModel(code: 'is', name: 'Icelandic', flag: '🇮🇸', nativeName: 'Íslenska'),
    LanguageModel(code: 'ig', name: 'Igbo', flag: '🇳🇬', nativeName: 'Igbo'),
    LanguageModel(code: 'ilo', name: 'Ilocano', flag: '🇵🇭', nativeName: 'Ilokano'),
    LanguageModel(code: 'id', name: 'Indonesian', flag: '🇮🇩', nativeName: 'Bahasa Indonesia'),
    LanguageModel(code: 'ga', name: 'Irish', flag: '🇮🇪', nativeName: 'Gaeilge'),
    LanguageModel(code: 'it', name: 'Italian', flag: '🇮🇹', nativeName: 'Italiano'),
    // J
    LanguageModel(code: 'ja', name: 'Japanese', flag: '🇯🇵', nativeName: '日本語'),
    LanguageModel(code: 'jv', name: 'Javanese', flag: '🇮🇩', nativeName: 'Basa Jawa'),
    // K
    LanguageModel(code: 'kab', name: 'Kabyle', flag: '🇩🇿', nativeName: 'Taqbaylit'),
    LanguageModel(code: 'kn', name: 'Kannada', flag: '🇮🇳', nativeName: 'ಕನ್ನಡ'),
    LanguageModel(code: 'kr', name: 'Kanuri', flag: '🇳🇬', nativeName: 'Kanuri'),
    LanguageModel(code: 'ks', name: 'Kashmiri', flag: '🇮🇳', nativeName: 'कश्मीरी'),
    LanguageModel(code: 'kk', name: 'Kazakh', flag: '🇰🇿', nativeName: 'Қазақ'),
    LanguageModel(code: 'km', name: 'Khmer', flag: '🇰🇭', nativeName: 'ខ្មែរ'),
    LanguageModel(code: 'kha', name: 'Khasi', flag: '🇮🇳', nativeName: 'খাসি'),
    LanguageModel(code: 'ki', name: 'Kikuyu', flag: '🇰🇪', nativeName: 'Gĩkũyũ'),
    LanguageModel(code: 'rw', name: 'Kinyarwanda', flag: '🇷🇼', nativeName: 'Ikinyarwanda'),
    LanguageModel(code: 'rn', name: 'Kirundi', flag: '🇧🇮', nativeName: 'Ikirundi'),
    LanguageModel(code: 'kg', name: 'Kongo', flag: '🇨🇩', nativeName: 'Kikongo'),
    LanguageModel(code: 'kok', name: 'Konkani', flag: '🇮🇳', nativeName: 'कोंकणी'),
    LanguageModel(code: 'ko', name: 'Korean', flag: '🇰🇷', nativeName: '한국어'),
    LanguageModel(code: 'kri', name: 'Krio', flag: '🇸🇱', nativeName: 'Krio'),
    LanguageModel(code: 'ku', name: 'Kurdish', flag: '🇮🇶', nativeName: 'Kurdî'),
    LanguageModel(code: 'kmr', name: 'Kurmanji', flag: '🇹🇷', nativeName: 'Kurmancî'),
    LanguageModel(code: 'ky', name: 'Kyrgyz', flag: '🇰🇬', nativeName: 'Кыргызча'),
    // L
    LanguageModel(code: 'lo', name: 'Lao', flag: '🇱🇦', nativeName: 'ລາວ'),
    LanguageModel(code: 'la', name: 'Latin', flag: '🏛️', nativeName: 'Latina'),
    LanguageModel(code: 'lv', name: 'Latvian', flag: '🇱🇻', nativeName: 'Latviešu'),
    LanguageModel(code: 'ln', name: 'Lingala', flag: '🇨🇩', nativeName: 'Lingála'),
    LanguageModel(code: 'lt', name: 'Lithuanian', flag: '🇱🇹', nativeName: 'Lietuvių'),
    LanguageModel(code: 'lu', name: 'Luba-Katanga', flag: '🇨🇩', nativeName: 'Kiluba'),
    LanguageModel(code: 'lg', name: 'Luganda', flag: '🇺🇬', nativeName: 'Luganda'),
    LanguageModel(code: 'lb', name: 'Luxembourgish', flag: '🇱🇺', nativeName: 'Lëtzebuergesch'),
    // M
    LanguageModel(code: 'mk', name: 'Macedonian', flag: '🇲🇰', nativeName: 'Македонски'),
    LanguageModel(code: 'mag', name: 'Magahi', flag: '🇮🇳', nativeName: 'मगही'),
    LanguageModel(code: 'mg', name: 'Malagasy', flag: '🇲🇬', nativeName: 'Malagasy'),
    LanguageModel(code: 'mai', name: 'Maithili', flag: '🇮🇳', nativeName: 'मैथिली'),
    LanguageModel(code: 'ms', name: 'Malay', flag: '🇲🇾', nativeName: 'Bahasa Melayu'),
    LanguageModel(code: 'ml', name: 'Malayalam', flag: '🇮🇳', nativeName: 'മലയാളം'),
    LanguageModel(code: 'mt', name: 'Maltese', flag: '🇲🇹', nativeName: 'Malti'),
    LanguageModel(code: 'mni', name: 'Manipuri', flag: '🇮🇳', nativeName: 'মৈতৈলোন্'),
    LanguageModel(code: 'mr', name: 'Marathi', flag: '🇮🇳', nativeName: 'मराठी'),
    LanguageModel(code: 'mwr', name: 'Marwari', flag: '🇮🇳', nativeName: 'मारवाड़ी'),
    LanguageModel(code: 'mi', name: 'Māori', flag: '🇳🇿', nativeName: 'Te reo Māori'),
    LanguageModel(code: 'nan', name: 'Min Nan / Hokkien', flag: '🇹🇼', nativeName: '閩南語'),
    LanguageModel(code: 'mn', name: 'Mongolian', flag: '🇲🇳', nativeName: 'Монгол'),
    LanguageModel(code: 'sr-ME', name: 'Montenegrin', flag: '🇲🇪', nativeName: 'Crnogorski'),
    LanguageModel(code: 'lus', name: 'Mizo', flag: '🇮🇳', nativeName: 'Mizo ṭawng'),
    // N
    LanguageModel(code: 'ne', name: 'Nepali', flag: '🇳🇵', nativeName: 'नेपाली'),
    LanguageModel(code: 'nb-NO', name: 'Norwegian Bokmål', flag: '🇳🇴', nativeName: 'Norsk bokmål'),
    LanguageModel(code: 'nn-NO', name: 'Norwegian Nynorsk', flag: '🇳🇴', nativeName: 'Norsk nynorsk'),
    // O
    LanguageModel(code: 'oc', name: 'Occitan', flag: '🇫🇷', nativeName: 'Occitan'),
    LanguageModel(code: 'or', name: 'Odia', flag: '🇮🇳', nativeName: 'ଓଡ଼ିଆ'),
    // P
    LanguageModel(code: 'ps', name: 'Pashto', flag: '🇦🇫', nativeName: 'پښتو'),
    LanguageModel(code: 'fa', name: 'Persian', flag: '🇮🇷', nativeName: 'فارسی'),
    LanguageModel(code: 'pl', name: 'Polish', flag: '🇵🇱', nativeName: 'Polski'),
    LanguageModel(code: 'pt-BR', name: 'Portuguese (Brazil)', flag: '🇧🇷', nativeName: 'Português'),
    LanguageModel(code: 'pt-PT', name: 'Portuguese (Portugal)', flag: '🇵🇹', nativeName: 'Português'),
    LanguageModel(code: 'pa', name: 'Punjabi', flag: '🇮🇳', nativeName: 'ਪੰਜਾਬੀ'),
    // Q
    LanguageModel(code: 'qu', name: 'Quechua', flag: '🇵🇪', nativeName: 'Runa Simi'),
    LanguageModel(code: 'raj', name: 'Rajasthani', flag: '🇮🇳', nativeName: 'राजस्थानी'),
    LanguageModel(code: 'ro', name: 'Romanian', flag: '🇷🇴', nativeName: 'Română'),
    LanguageModel(code: 'rm', name: 'Romansh', flag: '🇨🇭', nativeName: 'Rumantsch'),
    LanguageModel(code: 'ru', name: 'Russian', flag: '🇷🇺', nativeName: 'Русский'),
    // S
    LanguageModel(code: 'sm', name: 'Samoan', flag: '🇼🇸', nativeName: 'Gagana Sāmoa'),
    LanguageModel(code: 'sa', name: 'Sanskrit', flag: '🇮🇳', nativeName: 'संस्कृत'),
    LanguageModel(code: 'sat', name: 'Santali', flag: '🇮🇳', nativeName: 'ᱥᱟᱱᱛᱟᱲᱤ'),
    LanguageModel(code: 'skr', name: 'Saraiki', flag: '🇵🇰', nativeName: 'سرائیکی'),
    LanguageModel(code: 'gd', name: 'Scottish Gaelic', flag: '🏴󠁧󠁢󠁳󠁣󠁴󠁿', nativeName: 'Gàidhlig'),
    LanguageModel(code: 'sr', name: 'Serbian', flag: '🇷🇸', nativeName: 'Српски'),
    LanguageModel(code: 'st', name: 'Sesotho', flag: '🇱🇸', nativeName: 'Sesotho'),
    LanguageModel(code: 'tn', name: 'Setswana', flag: '🇧🇼', nativeName: 'Setswana'),
    LanguageModel(code: 'sn', name: 'Shona', flag: '🇿🇼', nativeName: 'ChiShona'),
    LanguageModel(code: 'scn', name: 'Sicilian', flag: '🇮🇹', nativeName: 'Sicilianu'),
    LanguageModel(code: 'sd', name: 'Sindhi', flag: '🇵🇰', nativeName: 'سنڌي'),
    LanguageModel(code: 'si', name: 'Sinhala', flag: '🇱🇰', nativeName: 'සිංහල'),
    LanguageModel(code: 'sk', name: 'Slovak', flag: '🇸🇰', nativeName: 'Slovenčina'),
    LanguageModel(code: 'sl', name: 'Slovenian', flag: '🇸🇮', nativeName: 'Slovenščina'),
    LanguageModel(code: 'so', name: 'Somali', flag: '🇸🇴', nativeName: 'Soomaali'),
    LanguageModel(code: 'es-MX', name: 'Spanish (Latin America)', flag: '🇲🇽', nativeName: 'Español'),
    LanguageModel(code: 'es-ES', name: 'Spanish (Spain)', flag: '🇪🇸', nativeName: 'Español'),
    LanguageModel(code: 'su', name: 'Sundanese', flag: '🇮🇩', nativeName: 'Basa Sunda'),
    LanguageModel(code: 'sw', name: 'Swahili', flag: '🇰🇪', nativeName: 'Kiswahili'),
    LanguageModel(code: 'sv', name: 'Swedish', flag: '🇸🇪', nativeName: 'Svenska'),
    // T
    LanguageModel(code: 'tg', name: 'Tajik', flag: '🇹🇯', nativeName: 'Тоҷикӣ'),
    LanguageModel(code: 'zgh', name: 'Tamazight', flag: '🇲🇦', nativeName: 'ⵜⴰⵎⴰⵣⵉⵖⵜ'),
    LanguageModel(code: 'ta', name: 'Tamil', flag: '🇮🇳', nativeName: 'தமிழ்'),
    LanguageModel(code: 'tt', name: 'Tatar', flag: '🇷🇺', nativeName: 'Татар'),
    LanguageModel(code: 'te', name: 'Telugu', flag: '🇮🇳', nativeName: 'తెలుగు'),
    LanguageModel(code: 'th', name: 'Thai', flag: '🇹🇭', nativeName: 'ไทย'),
    LanguageModel(code: 'ti', name: 'Tigrinya', flag: '🇪🇷', nativeName: 'ትግርኛ'),
    LanguageModel(code: 'tpi', name: 'Tok Pisin', flag: '🇵🇬', nativeName: 'Tok Pisin'),
    LanguageModel(code: 'to', name: 'Tongan', flag: '🇹🇴', nativeName: 'Lea faka-Tonga'),
    LanguageModel(code: 'tcy', name: 'Tulu', flag: '🇮🇳', nativeName: 'ತುಳು'),
    LanguageModel(code: 'tr', name: 'Turkish', flag: '🇹🇷', nativeName: 'Türkçe'),
    // U
    LanguageModel(code: 'uk', name: 'Ukrainian', flag: '🇺🇦', nativeName: 'Українська'),
    LanguageModel(code: 'ur', name: 'Urdu', flag: '🇵🇰', nativeName: 'اردو'),
    LanguageModel(code: 'ug', name: 'Uyghur', flag: '🇨🇳', nativeName: 'ئۇيغۇرچە'),
    LanguageModel(code: 'uz', name: 'Uzbek', flag: '🇺🇿', nativeName: 'O\'zbek'),
    // V
    LanguageModel(code: 'vec', name: 'Venetian', flag: '🇮🇹', nativeName: 'Vèneto'),
    LanguageModel(code: 'vi', name: 'Vietnamese', flag: '🇻🇳', nativeName: 'Tiếng Việt'),
    // W
    LanguageModel(code: 'war', name: 'Waray', flag: '🇵🇭', nativeName: 'Winaray'),
    LanguageModel(code: 'cy', name: 'Welsh', flag: '🏴󠁧󠁢󠁷󠁬󠁳󠁿', nativeName: 'Cymraeg'),
    LanguageModel(code: 'wo', name: 'Wolof', flag: '🇸🇳', nativeName: 'Wolof'),
    LanguageModel(code: 'wuu', name: 'Wu Chinese', flag: '🇨🇳', nativeName: '吴语'),
    // X
    LanguageModel(code: 'hsn', name: 'Xiang Chinese', flag: '🇨🇳', nativeName: '湘语'),
    LanguageModel(code: 'ts', name: 'Xitsonga', flag: '🇿🇦', nativeName: 'Xitsonga'),
    // Y
    LanguageModel(code: 'yi', name: 'Yiddish', flag: '🇮🇱', nativeName: 'ייִדיש'),
    LanguageModel(code: 'yo', name: 'Yoruba', flag: '🇳🇬', nativeName: 'Yorùbá'),
    // Z
    LanguageModel(code: 'zu', name: 'Zulu', flag: '🇿🇦', nativeName: 'isiZulu'),
    LanguageModel(code: 'xh', name: 'isiXhosa', flag: '🇿🇦', nativeName: 'isiXhosa'),
  ];

  static LanguageModel? getByCode(String code) {
    try {
      return availableLanguages.firstWhere((lang) => lang.code == code);
    } catch (e) {
      return null;
    }
  }
}
