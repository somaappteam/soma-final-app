import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_widgets.dart';

class LanguageSelectionStep extends StatefulWidget {
  final Map<String, dynamic> onboardingData;
  final VoidCallback onNext;

  const LanguageSelectionStep({
    super.key,
    required this.onboardingData,
    required this.onNext,
  });

  @override
  State<LanguageSelectionStep> createState() => _LanguageSelectionStepState();
}

class _LanguageSelectionStepState extends State<LanguageSelectionStep> {
  int _currentSubStep = 0; // 0 = native language, 1 = target language
  String? _selectedNativeLanguage;
  String? _selectedTargetLanguage;

  final List<Map<String, dynamic>> _languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸', 'nativeName': 'English'},
    {'code': 'es', 'name': 'Spanish', 'flag': '🇪🇸', 'nativeName': 'Español'},
    {'code': 'fr', 'name': 'French', 'flag': '🇫🇷', 'nativeName': 'Français'},
    {'code': 'de', 'name': 'German', 'flag': '🇩🇪', 'nativeName': 'Deutsch'},
    {'code': 'it', 'name': 'Italian', 'flag': '🇮🇹', 'nativeName': 'Italiano'},
    {'code': 'pt', 'name': 'Portuguese', 'flag': '🇧🇷', 'nativeName': 'Português'},
    {'code': 'ja', 'name': 'Japanese', 'flag': '🇯🇵', 'nativeName': '日本語'},
    {'code': 'ko', 'name': 'Korean', 'flag': '🇰🇷', 'nativeName': '한국어'},
    {'code': 'zh', 'name': 'Chinese', 'flag': '🇨🇳', 'nativeName': '中文'},
    {'code': 'ru', 'name': 'Russian', 'flag': '🇷🇺', 'nativeName': 'Русский'},
    {'code': 'ar', 'name': 'Arabic', 'flag': '🇸🇦', 'nativeName': 'العربية'},
    {'code': 'hi', 'name': 'Hindi', 'flag': '🇮🇳', 'nativeName': 'हिन्दी'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentSubStep == 0 ? 'I speak...' : 'I want to learn...',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _currentSubStep == 0 
                    ? 'Select your native language'
                    : 'What language do you want to learn?',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _languages.length,
            itemBuilder: (context, index) {
              final lang = _languages[index];
              final isNative = _selectedNativeLanguage == lang['code'];
              final isTarget = _selectedTargetLanguage == lang['code'];
              final isSelected = _currentSubStep == 0 ? isNative : isTarget;
              final isDisabled = _currentSubStep == 1 && _selectedNativeLanguage == lang['code'];

              return AnimatedCard(
                delayMs: index * 50,
                onTap: isDisabled ? null : () => _selectLanguage(lang),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.tealGradient : null,
                    color: isSelected 
                        ? null 
                        : isDisabled 
                            ? Colors.grey.shade100 
                            : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected 
                          ? AppColors.primaryTeal 
                          : isDisabled
                              ? Colors.grey.shade300
                              : Colors.grey.shade200,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            lang['flag'],
                            style: TextStyle(
                              fontSize: 48,
                              color: isDisabled ? Colors.grey.shade400 : null,
                            ),
                          ),
                          if (isDisabled)
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.block,
                                color: Colors.grey.shade400,
                                size: 24,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        lang['name'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected 
                              ? Colors.white 
                              : isDisabled
                                  ? Colors.grey.shade400
                                  : AppColors.textDark,
                        ),
                      ),
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: AppColors.primaryTeal,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_selectedNativeLanguage != null && _currentSubStep == 0)
          Padding(
            padding: const EdgeInsets.all(24),
            child: PulsingButton(
              onPressed: () => setState(() => _currentSubStep = 1),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward),
                ],
              ),
            ),
          ),
        if (_selectedTargetLanguage != null && _currentSubStep == 1)
          Padding(
            padding: const EdgeInsets.all(24),
            child: PulsingButton(
              color: AppColors.success,
              onPressed: () {
                widget.onboardingData['native_language'] = _selectedNativeLanguage;
                widget.onboardingData['target_language'] = _selectedTargetLanguage;
                widget.onNext();
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _selectLanguage(Map<String, dynamic> lang) {
    setState(() {
      if (_currentSubStep == 0) {
        if (_selectedNativeLanguage == lang['code']) {
          _selectedNativeLanguage = null;
        } else {
          _selectedNativeLanguage = lang['code'];
        }
      } else {
        if (_selectedTargetLanguage == lang['code']) {
          _selectedTargetLanguage = null;
        } else {
          _selectedTargetLanguage = lang['code'];
        }
      }
    });
  }
}
