import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class CreateCompetitionScreen extends StatefulWidget {
  const CreateCompetitionScreen({super.key});

  @override
  State<CreateCompetitionScreen> createState() => _CreateCompetitionScreenState();
}

class _CreateCompetitionScreenState extends State<CreateCompetitionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final String _gameType = 'vocabulary';
  String _language = 'Spanish';
  String _difficulty = 'medium';
  int _maxPlayers = 4;
  bool _isPrivate = false;
  bool _isPremiumOnly = false;

  final List<String> _languages = ['Spanish', 'French', 'German', 'Italian', 'Japanese'];
  final List<String> _difficulties = ['easy', 'medium', 'hard', 'expert'];
  final List<int> _playerCounts = [2, 4, 6, 8];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Create Competition',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Game Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.title),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    'Language',
                    _language,
                    _languages,
                    (value) => setState(() => _language = value!),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    'Difficulty',
                    _difficulty,
                    _difficulties,
                    (value) => setState(() => _difficulty = value!),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    'Max Players',
                    '$_maxPlayers',
                    _playerCounts.map((e) => '$e').toList(),
                    (value) => setState(() => _maxPlayers = int.parse(value!)),
                  ),
                  const SizedBox(height: 24),
                  _buildSwitch(
                    'Private Game',
                    'Only invited players can join',
                    _isPrivate,
                    (value) => setState(() => _isPrivate = value),
                  ),
                  _buildSwitch(
                    'Premium Only',
                    'Only premium users can join',
                    _isPremiumOnly,
                    (value) => setState(() => _isPremiumOnly = value),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _createGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Create Game',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 300.ms);
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSwitch(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMedium,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primaryTeal,
      ),
    );
  }

  void _createGame() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game created successfully!')),
      );
    }
  }
}
