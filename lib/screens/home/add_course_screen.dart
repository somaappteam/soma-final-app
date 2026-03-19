import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../models/course_model.dart';
import '../../models/language.dart';
import '../../providers/course_provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';

class AddCourseScreen extends StatefulWidget {
  const AddCourseScreen({super.key});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  int _currentStep = 0;
  String? _selectedNativeLanguage;
  String? _selectedTargetLanguage;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _existingCoursePairs = {};

  @override
  void initState() {
    super.initState();
    _loadExistingCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadExistingCourses() {
    final courseProvider = context.read<CourseProvider>();
    final existingCourses = courseProvider.courses;
    
    setState(() {
      _existingCoursePairs = existingCourses.map((c) => '${c.nativeLanguage}-${c.targetLanguage}').toSet();
    });
  }

  bool _isDuplicateCourse(String nativeCode, String targetCode) {
    return _existingCoursePairs.contains('$nativeCode-$targetCode');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  _buildStepIndicator(),
                  Expanded(
                    child: _currentStep == 0
                        ? _buildLanguageSelection(
                            title: 'Languages I Speak',
                            subtitle: 'Select your native language',
                            selectedLanguage: _selectedNativeLanguage,
                            onSelect: (code) {
                              setState(() {
                                _selectedNativeLanguage = code;
                                _currentStep = 1;
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                          )
                        : _buildLanguageSelection(
                            title: 'Languages I Want to Learn',
                            subtitle: 'Select a language to learn',
                            selectedLanguage: _selectedTargetLanguage,
                            onSelect: (code) {
                              if (_isDuplicateCourse(_selectedNativeLanguage!, code)) {
                                _showDuplicateWarning();
                              } else {
                                setState(() {
                                  _selectedTargetLanguage = code;
                                });
                                _showConfirmation();
                              }
                            },
                          ),
                  ),
                ],
              ),
              _buildDownloadOverlay(appState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryTeal.withValues(alpha: 0.15),
            AppColors.darkTeal.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.neutralMid.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add New Course',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose your language pair',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: _currentStep >= 0
                        ? const LinearGradient(
                            colors: [AppColors.primaryTeal, AppColors.darkTeal],
                          )
                        : null,
                    color: _currentStep >= 0 ? null : AppColors.neutralMid,
                    shape: BoxShape.circle,
                    boxShadow: _currentStep >= 0
                        ? [
                            BoxShadow(
                              color: AppColors.primaryTeal.withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: const Icon(
                    Icons.language,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'I Speak',
                  style: TextStyle(
                    color: _currentStep >= 0 ? AppColors.primaryTeal : AppColors.neutralMid,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 3,
            decoration: BoxDecoration(
              gradient: _currentStep >= 1
                  ? const LinearGradient(
                      colors: [AppColors.primaryTeal, AppColors.darkTeal],
                    )
                  : null,
              color: _currentStep >= 1 ? null : AppColors.neutralMid,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: _currentStep >= 1
                        ? const LinearGradient(
                            colors: [AppColors.primaryTeal, AppColors.darkTeal],
                          )
                        : null,
                    color: _currentStep >= 1 ? null : AppColors.neutralMid,
                    shape: BoxShape.circle,
                    boxShadow: _currentStep >= 1
                        ? [
                            BoxShadow(
                              color: AppColors.primaryTeal.withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'I Learn',
                  style: TextStyle(
                    color: _currentStep >= 1 ? AppColors.primaryTeal : AppColors.neutralMid,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelection({
    required String title,
    required String subtitle,
    required String? selectedLanguage,
    required Function(String) onSelect,
  }) {
    // Filter languages based on search
    var languages = LanguageModel.availableLanguages.where((lang) {
      if (_searchQuery.isEmpty) return true;
      return lang.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          lang.nativeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          lang.code.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Filter out already selected native language from target options
    if (_currentStep == 1 && _selectedNativeLanguage != null) {
      languages.removeWhere((lang) => lang.code == _selectedNativeLanguage);
    }

    // Group languages by first letter
    final groupedLanguages = <String, List<LanguageModel>>{};
    for (final lang in languages) {
      final firstLetter = lang.name[0].toUpperCase();
      groupedLanguages.putIfAbsent(firstLetter, () => []).add(lang);
    }
    final sortedKeys = groupedLanguages.keys.toList()..sort();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
              fillColor: Theme.of(context).brightness == Brightness.dark 
                  ? AppColors.darkElevated 
                  : AppColors.neutralLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _searchQuery.isNotEmpty
              ? _buildSearchResults(languages, selectedLanguage, onSelect)
              : _buildAlphabeticalList(groupedLanguages, sortedKeys, selectedLanguage, onSelect),
        ),
      ],
    );
  }

  Widget _buildSearchResults(
    List<LanguageModel> languages,
    String? selectedLanguage,
    Function(String) onSelect,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: languages.length,
      itemBuilder: (context, index) {
        final language = languages[index];
        final isSelected = selectedLanguage == language.code;

        return _buildLanguageCard(language, isSelected, onSelect);
      },
    );
  }

  Widget _buildAlphabeticalList(
    Map<String, List<LanguageModel>> groupedLanguages,
    List<String> sortedKeys,
    String? selectedLanguage,
    Function(String) onSelect,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final letter = sortedKeys[index];
        final languages = groupedLanguages[letter]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  letter,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
            ),
            ...languages.map((language) {
              final isSelected = selectedLanguage == language.code;
              return _buildLanguageCard(language, isSelected, onSelect);
            }),
          ],
        );
      },
    );
  }

  Widget _buildLanguageCard(
    LanguageModel language,
    bool isSelected,
    Function(String) onSelect,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? const BorderSide(color: AppColors.primaryTeal, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        onTap: () => onSelect(language.code),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [AppColors.primaryTeal, AppColors.darkTeal],
                  )
                : null,
            color: isSelected ? null : (Theme.of(context).brightness == Brightness.dark 
                ? AppColors.darkElevated 
                : AppColors.neutralLight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              language.flag,
              style: const TextStyle(fontSize: 32),
            ),
          ),
        ),
        title: Text(
          language.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              language.nativeName,
              style: const TextStyle(
                color: AppColors.textMedium,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? AppColors.darkElevated.withValues(alpha: 0.5) 
                    : AppColors.neutralLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                language.code,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMedium,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        trailing: isSelected
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primaryTeal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              )
            : const Icon(Icons.chevron_right, color: AppColors.textMedium),
      ),
    ).animate().fadeIn(delay: (50).ms);
  }

  void _showDuplicateWarning() {
    final targetLang = LanguageModel.getByCode(_selectedTargetLanguage!);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.accentCoral),
            SizedBox(width: 8),
            Text('Course Already Exists'),
          ],
        ),
        content: Text(
          'You already have a course for learning ${targetLang?.name ?? 'this language'} from your selected native language. You cannot add duplicate courses.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Choose Different Language'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedTargetLanguage = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showConfirmation() {
    if (_selectedNativeLanguage == null || _selectedTargetLanguage == null) {
      return;
    }

    final nativeLang = LanguageModel.getByCode(_selectedNativeLanguage!);
    final targetLang = LanguageModel.getByCode(_selectedTargetLanguage!);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Start Learning?',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You\'re about to start learning:',
              style: TextStyle(color: AppColors.textMedium),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryTeal.withValues(alpha: 0.1), AppColors.darkTeal.withValues(alpha: 0.05)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    targetLang?.flag ?? '',
                    style: const TextStyle(fontSize: 56),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    targetLang?.name ?? '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    targetLang?.nativeName ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? AppColors.darkElevated 
                    : AppColors.neutralLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    nativeLang?.flag ?? '',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'From ${nativeLang?.name ?? ''}',
                    style: const TextStyle(color: AppColors.textMedium),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentStep = 0;
                _selectedNativeLanguage = null;
                _selectedTargetLanguage = null;
              });
            },
            child: const Text('Start Over'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              // Capture providers before popping context
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final courseProvider = context.read<CourseProvider>();
              final appState = context.read<AppState>();
              final nativeLang = LanguageModel.getByCode(_selectedNativeLanguage!);
              final targetLang = LanguageModel.getByCode(_selectedTargetLanguage!);
              if (nativeLang == null || targetLang == null) return;

              final native = Language(nativeLang.code, nativeLang.name, nativeLang.flag, nativeLang.nativeName);
              final target = Language(targetLang.code, targetLang.name, targetLang.flag, targetLang.nativeName);

              navigator.pop();

              await courseProvider.addCourse(
                nativeLanguage: _selectedNativeLanguage!,
                targetLanguage: _selectedTargetLanguage!,
              );

              if (!mounted) return;

              // Trigger app state to select and potentially download TTS
              appState.selectLanguages(native, target);

              if (courseProvider.error == null) {
                // Return to previous screen
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('🎉 Started learning ${target.name}!'),
                    backgroundColor: AppColors.primaryTeal,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(courseProvider.error!),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: const Icon(Icons.play_arrow),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            label: const Text('Start Learning'),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadOverlay(AppState appState) {
    if (!appState.isTtsDownloading || appState.hideTtsOverlay) return const SizedBox.shrink();

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? AppColors.darkElevated 
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_download,
                size: 48,
                color: AppColors.primaryTeal,
              ).animate(onPlay: (controller) => controller.repeat()).scale(duration: 1000.ms),
              const SizedBox(height: 16),
              const Text(
                'Downloading Voice Model...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Fetching high-quality AI offline voice files. This may take a minute depending on your connection.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMedium,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              LinearProgressIndicator(
                value: appState.ttsDownloadProgress,
                backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 12),
              Text(
                '${(appState.ttsDownloadProgress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  appState.hideTtsOverlayForNow();
                  if (mounted && Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  'Download in Background',
                  style: TextStyle(color: AppColors.textMedium, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

