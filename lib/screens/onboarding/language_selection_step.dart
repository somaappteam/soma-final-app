import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/course_model.dart';

class LanguageSelectionStep extends StatefulWidget {
  final bool isTargetLanguage;
  final Map<String, dynamic> onboardingData;
  final VoidCallback onNext;

  const LanguageSelectionStep({
    super.key,
    required this.isTargetLanguage,
    required this.onboardingData,
    required this.onNext,
  });

  @override
  State<LanguageSelectionStep> createState() => _LanguageSelectionStepState();
}

class _LanguageSelectionStepState extends State<LanguageSelectionStep> {
  String? _selectedLanguageCode;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final key = widget.isTargetLanguage ? 'target_language' : 'native_language';
    final existing = widget.onboardingData[key];
    if (existing != null && existing is LanguageModel) {
      _selectedLanguageCode = existing.code;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter languages based on search
    var languages = LanguageModel.availableLanguages.where((lang) {
      if (_searchQuery.isEmpty) return true;
      return lang.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          lang.nativeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          lang.code.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // If selecting target language, filter out the chosen native language for clarity
    if (widget.isTargetLanguage && widget.onboardingData.containsKey('native_language')) {
      final nativeLang = widget.onboardingData['native_language'] as LanguageModel;
      languages.removeWhere((lang) => lang.code == nativeLang.code);
    }

    // Group languages by first letter
    final groupedLanguages = <String, List<LanguageModel>>{};
    for (final lang in languages) {
      final firstLetter = lang.name[0].toUpperCase();
      groupedLanguages.putIfAbsent(firstLetter, () => []).add(lang);
    }
    final sortedKeys = groupedLanguages.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isTargetLanguage ? 'I want to learn...' : 'I speak...',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.isTargetLanguage 
                    ? 'What language do you want to learn?'
                    : 'Select your native language',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search 185+ languages...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: _searchQuery.isNotEmpty ? languages.length : sortedKeys.length,
            itemBuilder: (context, index) {
              if (_searchQuery.isNotEmpty) {
                final lang = languages[index];
                return _buildLanguageCard(lang);
              } else {
                final letter = sortedKeys[index];
                final langs = groupedLanguages[letter]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Text(
                        letter,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                    ...langs.map((lang) => _buildLanguageCard(lang)),
                  ],
                );
              }
            },
          ),
        ),

        _buildBottomButton(languages),
      ],
    );
  }

  Widget _buildLanguageCard(LanguageModel lang) {
    final isSelected = _selectedLanguageCode == lang.code;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppColors.primaryTeal : AppColors.neutralLight,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: () => _selectLanguage(lang),
        leading: Text(
          lang.flag,
          style: const TextStyle(fontSize: 28),
        ),
        title: Text(
          lang.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(lang.nativeName),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: AppColors.primaryTeal)
            : null,
      ),
    );
  }

  Widget _buildBottomButton(List<LanguageModel> languages) {
    if (_selectedLanguageCode == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            final selectedLang = LanguageModel.availableLanguages.firstWhere((l) => l.code == _selectedLanguageCode);
            final key = widget.isTargetLanguage ? 'target_language' : 'native_language';
            widget.onboardingData[key] = selectedLang;
            widget.onNext();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryTeal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward),
            ],
          ),
        ),
      ),
    );
  }

  void _selectLanguage(LanguageModel lang) {
    setState(() {
      _selectedLanguageCode = lang.code;
    });
  }
}

