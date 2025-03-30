import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MessagesSettingsDialog extends StatefulWidget {
  final String chatId;
  final Function(bool) onSave;

  const MessagesSettingsDialog({
    super.key,
    required this.chatId,
    required this.onSave,
  });

  @override
  _MessagesSettingsDialogState createState() => _MessagesSettingsDialogState();
}

class _MessagesSettingsDialogState extends State<MessagesSettingsDialog> {
  bool? _selectedValue;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentSetting();
  }

  Future<void> _loadCurrentSetting() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('groupChats')
          .doc(widget.chatId)
          .get();

      if (doc.exists) {
        _selectedValue = doc['MessagesOnlyAdmin'] ?? false;
      }
    } catch (e) {
      _errorMessage = "Failed to load Messages settings: ${e.toString()}";
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Messages Settings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else ...[
              Text(
                "Allow messages only from admin",
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                  color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<bool>(
                    isExpanded: true,
                    value: _selectedValue,
                    items: const [
                      DropdownMenuItem(
                        value: true,
                        child: Text('Enabled', style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      DropdownMenuItem(
                        value: false,
                        child: Text('Disabled', style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                    ],
                    onChanged: (bool? newValue) {
                      setState(() => _selectedValue = newValue);
                    },
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: theme.colorScheme.primary,
                  ),
                  onPressed: _isLoading ? null : _handleSave,
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_selectedValue == null) return;

    setState(() => _isLoading = true);

    try {
      await widget.onSave(_selectedValue!);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to update Messages settings: ${e.toString()}";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
}