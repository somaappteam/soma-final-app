import 'package:flutter/material.dart';
import '../../services/tts_service.dart';
import '../../services/mms_tts_service.dart';
import '../../models/course_model.dart';
import '../../widgets/tts_download_dialog.dart';

class TtsDebuggerScreen extends StatefulWidget {
  const TtsDebuggerScreen({super.key});

  @override
  State<TtsDebuggerScreen> createState() => _TtsDebuggerScreenState();
}

class _TtsDebuggerScreenState extends State<TtsDebuggerScreen> {
  final TextEditingController _textController = TextEditingController(
    text: 'Amakuru? Muraho neza?', // "How are you? Are you doing well?" in Kinyarwanda
  );
  
  LanguageModel _selectedLanguage = LanguageModel.availableLanguages.firstWhere(
    (l) => l.code == 'rw',
    orElse: () => LanguageModel.availableLanguages.first,
  );

  final TtsService _ttsService = TtsService();
  final MmsTtsService _mmsTtsService = MmsTtsService();
  
  bool _isSpeaking = false;
  bool _isModelDownloaded = false;
  String _status = 'Idle';

  @override
  void initState() {
    super.initState();
    _checkModelStatus();
  }

  Future<void> _checkModelStatus() async {
    final downloaded = await _mmsTtsService.isModelDownloaded(_selectedLanguage.code);
    if (mounted) {
      setState(() {
        _isModelDownloaded = downloaded;
        _status = downloaded ? 'Model ready' : 'Model not downloaded';
      });
    }
  }

  Future<void> _downloadModel() async {
    showMmsTtsDownloadDialog(
      context,
      languageCode: _selectedLanguage.code,
      languageName: _selectedLanguage.name,
    );
    // Poll for status
    while (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      final downloaded = await _mmsTtsService.isModelDownloaded(_selectedLanguage.code);
      if (downloaded) {
        setState(() {
          _isModelDownloaded = true;
          _status = 'Model ready';
        });
        break;
      }
    }
  }

  Future<void> _speak() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _isSpeaking = true;
      _status = 'Synthesizing...';
    });

    try {
      await _ttsService.speak(
        _textController.text,
        languageCode: _selectedLanguage.code,
        languageName: _selectedLanguage.name,
        context: context,
      );
      setState(() => _status = 'Speaking completed');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TTS Debugger'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test any MMS TTS language',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Language Selector
            Card(
              child: ListTile(
                title: const Text('Select Language'),
                subtitle: Text('${_selectedLanguage.flag} ${_selectedLanguage.name} (${_selectedLanguage.code})'),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: _showLanguagePicker,
              ),
            ),
            const SizedBox(height: 16),

            // Text Input
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Text to speak',
                border: OutlineInputBorder(),
                hintText: 'Enter text here...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Status Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Model Local:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Icon(
                        _isModelDownloaded ? Icons.check_circle : Icons.error_outline,
                        color: _isModelDownloaded ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            if (!_isModelDownloaded)
              ElevatedButton.icon(
                onPressed: _downloadModel,
                icon: const Icon(Icons.download),
                label: const Text('Download Model'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue.shade700,
                ),
              )
            else
              FilledButton.icon(
                onPressed: _isSpeaking ? null : _speak,
                icon: _isSpeaking 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.volume_up),
                label: Text(_isSpeaking ? 'Processing...' : 'Speak Now'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            
            const SizedBox(height: 40),
            
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              'Instruction: \n1. Select Kinyarwanda.\n2. Tap Download (it will use the new willwade repository).\n3. Tap Speak.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: LanguageModel.availableLanguages.length,
          itemBuilder: (context, index) {
            final lang = LanguageModel.availableLanguages[index];
            return ListTile(
              leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
              title: Text(lang.name),
              subtitle: Text(lang.code),
              onTap: () {
                setState(() {
                  _selectedLanguage = lang;
                });
                Navigator.pop(context);
                _checkModelStatus();
              },
            );
          },
        );
      },
    );
  }
}
