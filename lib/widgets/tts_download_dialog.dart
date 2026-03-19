import 'package:flutter/material.dart';
import '../services/mms_tts_service.dart';
import '../theme/app_theme.dart';

/// Shows a bottom sheet explaining that the device doesn't support [languageName]
/// TTS natively, and offering to download the MMS TTS model for it.
///
/// MMS TTS is Meta's offline speech model supporting 1,000+ languages.
void showMmsTtsDownloadDialog(
  BuildContext context, {
  required String languageCode,
  required String languageName,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MmsTtsDownloadSheet(
      languageCode: languageCode,
      languageName: languageName,
    ),
  );
}

class _MmsTtsDownloadSheet extends StatefulWidget {
  final String languageCode;
  final String languageName;

  const _MmsTtsDownloadSheet({
    required this.languageCode,
    required this.languageName,
  });

  @override
  State<_MmsTtsDownloadSheet> createState() => _MmsTtsDownloadSheetState();
}

class _MmsTtsDownloadSheetState extends State<_MmsTtsDownloadSheet> {
  final MmsTtsService _mmsTts = MmsTtsService();

  _DownloadState _state = _DownloadState.idle;
  double _progress = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyDownloaded();
  }

  Future<void> _checkIfAlreadyDownloaded() async {
    final downloaded = await _mmsTts.isModelDownloaded(widget.languageCode);
    if (downloaded && mounted) {
      setState(() => _state = _DownloadState.done);
    }
  }

  Future<void> _download() async {
    setState(() {
      _state = _DownloadState.downloading;
      _progress = 0;
      _errorMessage = null;
    });

    try {
      await _mmsTts.downloadModel(
        widget.languageCode,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (mounted) setState(() => _state = _DownloadState.done);
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _DownloadState.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.record_voice_over_rounded,
                color: AppColors.primaryPurple,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              '${widget.languageName} voice not available',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Description
            Text(
              'Your device\'s built-in TTS doesn\'t support ${widget.languageName}. '
              'You can download the MMS TTS model — it\'s an offline AI voice that '
              'supports 1,000+ languages.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Progress / Status area
            if (_state == _DownloadState.downloading) ...[
              LinearProgressIndicator(
                value: _progress,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_progress * 100).toStringAsFixed(0)}%  —  Downloading ${widget.languageName} voice…',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
            ],

            if (_state == _DownloadState.done) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.languageName} voice ready!',
                    style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            if (_state == _DownloadState.error) ...[
              Text(
                _errorMessage != null
                    ? 'Download failed: $_errorMessage'
                    : 'Download failed. Please check your connection and try again.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],

            // Action buttons
            Row(
              children: [
                // Not Now
                if (_state != _DownloadState.done)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _state == _DownloadState.downloading
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Not Now'),
                    ),
                  ),
                if (_state != _DownloadState.done) const SizedBox(width: 12),

                // Download / Done / Retry
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _state == _DownloadState.downloading
                        ? null
                        : _state == _DownloadState.done
                            ? () => Navigator.pop(context)
                            : _download,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: AppColors.primaryPurple,
                    ),
                    icon: Icon(
                      _state == _DownloadState.done
                          ? Icons.done
                          : _state == _DownloadState.error
                              ? Icons.refresh
                              : Icons.download_rounded,
                      size: 20,
                    ),
                    label: Text(
                      _state == _DownloadState.done
                          ? 'Done'
                          : _state == _DownloadState.error
                              ? 'Retry'
                              : 'Download (${_estimateSizeMB(widget.languageCode)})',
                    ),
                  ),
                ),
              ],
            ),

            // Info footer
            if (_state == _DownloadState.idle || _state == _DownloadState.error) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Works offline once downloaded',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Returns a rough size estimate string for the download button label.
  String _estimateSizeMB(String languageCode) {
    // MMS TTS ONNX models are typically ~114-115 MB in this repo
    return '~115 MB';
  }
}

enum _DownloadState { idle, downloading, done, error }

