import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

/// A chat bubble for an arbitrary file (pdf, doc, video, zip, etc).
/// Tapping it downloads the file to a cache dir and opens it with the device's
/// default app for that type.
class FileBubble extends StatefulWidget {
  final String url;
  final String fileName;
  final String fileType; // extension, e.g. "pdf"
  final bool isMine;

  const FileBubble({
    super.key,
    required this.url,
    required this.fileName,
    required this.fileType,
    this.isMine = false,
  });

  @override
  State<FileBubble> createState() => _FileBubbleState();
}

class _FileBubbleState extends State<FileBubble> {
  bool _busy = false;

  IconData get _icon {
    final t = widget.fileType.toLowerCase();
    if (['pdf'].contains(t)) return Icons.picture_as_pdf_rounded;
    if (['doc', 'docx', 'txt', 'rtf'].contains(t)) {
      return Icons.description_rounded;
    }
    if (['xls', 'xlsx', 'csv'].contains(t)) return Icons.table_chart_rounded;
    if (['ppt', 'pptx'].contains(t)) return Icons.slideshow_rounded;
    if (['mp4', 'mov', 'mkv', 'avi', 'webm'].contains(t)) {
      return Icons.movie_rounded;
    }
    if (['mp3', 'wav', 'm4a', 'aac', 'ogg'].contains(t)) {
      return Icons.audiotrack_rounded;
    }
    if (['zip', 'rar', '7z'].contains(t)) return Icons.folder_zip_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Future<void> _open() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/${widget.fileName}';
      await Dio().download(widget.url, path);
      final result = await OpenFile.open(path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open file: ${result.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open file: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.isMine ? Colors.white : Theme.of(context).colorScheme.primary;
    final bg = widget.isMine
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).cardColor;
    final textColor = widget.isMine
        ? Colors.white
        : (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Theme.of(context).colorScheme.onSurface);

    return GestureDetector(
      onTap: _open,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: widget.isMine
              ? null
              : Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: fg.withOpacity(widget.isMine ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _busy
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: fg),
                    )
                  : Icon(_icon, color: fg),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: textColor, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.fileType.toUpperCase(),
                    style: TextStyle(
                      color: widget.isMine ? Colors.white70 : Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
