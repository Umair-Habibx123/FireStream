import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminSettingsDialog extends StatefulWidget {
  final String chatId;
  final Function(bool) onSave;

  const AdminSettingsDialog({
    super.key,
    required this.chatId,
    required this.onSave,
  });

  @override
  _AdminSettingsDialogState createState() => _AdminSettingsDialogState();
}

class _AdminSettingsDialogState extends State<AdminSettingsDialog> {
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
        _selectedValue = doc['SettingOnlyAdmin'] ?? false;
      }
    } catch (e) {
      _errorMessage = "Failed to load admin settings: ${e.toString()}";
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Admin Settings',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Allow settings change only by Admin",
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<bool>(
                      value: _selectedValue,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: true, child: Text('Enabled')),
                        DropdownMenuItem(value: false, child: Text('Disabled')),
                      ],
                      onChanged: (bool? newValue) {
                        setState(() => _selectedValue = newValue);
                      },
                    ),
                  ),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
              ],
            ),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade700,
            textStyle: const TextStyle(fontSize: 16),
          ),
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          child: const Text('Save'),
          onPressed: _handleSave,
        ),
      ],
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
        _errorMessage = "Failed to update admin settings: ${e.toString()}";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
}