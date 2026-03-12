import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import '../models/language.dart';
import '../widgets/animated_widgets.dart';
import 'home_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  Language? selectedNative;
  Language? selectedTarget;
  bool showTargetSelection = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          showTargetSelection ? 'I want to learn' : 'I speak',
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: showTargetSelection 
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                onPressed: () => setState(() {
                  showTargetSelection = false;
                  selectedTarget = null;
                  _searchController.clear();
                  _searchQuery = '';
                }),
              )
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search language...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
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
              itemCount: appState.availableLanguages
                  .where((lang) => lang.name.toLowerCase().contains(_searchQuery))
                  .length,
              itemBuilder: (context, index) {
                final filteredLanguages = appState.availableLanguages
                    .where((lang) => lang.name.toLowerCase().contains(_searchQuery))
                    .toList();
                final lang = filteredLanguages[index];
                final isSelected = showTargetSelection 
                    ? selectedTarget == lang
                    : selectedNative == lang;
                
                return AnimatedCard(
                  delayMs: index * 50,
                  onTap: () => _selectLanguage(lang),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.tealGradient : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected 
                            ? AppColors.primaryTeal 
                            : Colors.grey.shade200,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          lang.flag,
                          style: const TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          lang.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.textDark,
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
          if (selectedNative != null && !showTargetSelection)
            Padding(
              padding: const EdgeInsets.all(24),
              child: PulsingButton(
                onPressed: () => setState(() {
                  showTargetSelection = true;
                  _searchController.clear();
                  _searchQuery = '';
                }),
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
          if (selectedTarget != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: PulsingButton(
                color: AppColors.success,
                onPressed: () {
                  context.read<AppState>().selectLanguages(
                    selectedNative!,
                    selectedTarget!,
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Start Learning',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.rocket_launch),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _selectLanguage(Language lang) {
    setState(() {
      if (showTargetSelection) {
        if (selectedTarget == lang) {
          selectedTarget = null;
        } else {
          selectedTarget = lang;
        }
      } else {
        if (selectedNative == lang) {
          selectedNative = null;
        } else {
          selectedNative = lang;
        }
      }
    });
  }
}
