import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/course_model.dart';

class StorageManagementScreen extends StatefulWidget {
  const StorageManagementScreen({super.key});

  @override
  State<StorageManagementScreen> createState() => _StorageManagementScreenState();
}

class _StorageManagementScreenState extends State<StorageManagementScreen> {
  bool _isLoading = true;
  List<FileSystemEntity> _modelDirs = [];
  Map<String, int> _dirSizes = {};
  int _totalSize = 0;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    setState(() => _isLoading = true);
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelBaseDir = Directory('${appDir.path}/mms_models');
      
      if (await modelBaseDir.exists()) {
        final dirs = await modelBaseDir.list().where((e) => e is Directory).toList();
        
        int total = 0;
        Map<String, int> sizes = {};
        
        for (var dir in dirs) {
          int dirSize = await _getDirSize(dir as Directory);
          sizes[dir.path] = dirSize;
          total += dirSize;
        }
        
        setState(() {
          _modelDirs = dirs;
          _dirSizes = sizes;
          _totalSize = total;
        });
      } else {
        setState(() {
          _modelDirs = [];
          _dirSizes = {};
          _totalSize = 0;
        });
      }
    } catch (e) {
      debugPrint("Error loading storage info: \$e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<int> _getDirSize(Directory dir) async {
    int totalSize = 0;
    try {
      if (await dir.exists()) {
        await for (var entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
    } catch (_) {}
    return totalSize;
  }

  Future<void> _deleteModel(Directory dir, String langName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Model?'),
        content: const Text('Are you sure you want to delete the downloaded voices for \$langName? You will need to download it again to use offline text-to-speech.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await dir.delete(recursive: true);
        await _loadStorageInfo();
      } catch (e) {
        debugPrint("Failed to delete directory: \$e");
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '\$bytes B';
    if (bytes < 1024 * 1024) return '\${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '\${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '\${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Management'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Text('Downloaded Voices (TTS)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: _modelDirs.isEmpty 
                  ? _buildEmptyState()
                  : _buildModelList(),
              ),
            ],
          ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storage, color: AppColors.primaryTeal, size: 32),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Offline Data', style: TextStyle(color: AppColors.textMedium, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                _formatBytes(_totalSize),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 16),
          Text('No downloaded models', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('All offline TTS voices have been cleared.', style: TextStyle(color: AppColors.textMedium)),
        ],
      ),
    );
  }

  Widget _buildModelList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _modelDirs.length,
      itemBuilder: (context, index) {
        final dir = _modelDirs[index] as Directory;
        final langCode = dir.path.split(Platform.pathSeparator).last;
        final size = _dirSizes[dir.path] ?? 0;
        
        final languageModel = LanguageModel.getByCode(langCode);
        final langName = languageModel?.name ?? langCode.toUpperCase();
        final langFlag = languageModel?.flag ?? '📁';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Text(langFlag, style: const TextStyle(fontSize: 28)),
            title: Text(langName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(_formatBytes(size), style: const TextStyle(color: AppColors.textMedium)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _deleteModel(dir, langName),
            ),
          ),
        );
      },
    );
  }
}
