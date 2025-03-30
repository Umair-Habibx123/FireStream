import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddMembersByDialog extends StatefulWidget {
  final String chatId;
  final Function(String) onSave;

  const AddMembersByDialog({
    super.key,
    required this.chatId,
    required this.onSave,
  });

  @override
  _AddMembersByDialogState createState() => _AddMembersByDialogState();
}

class _AddMembersByDialogState extends State<AddMembersByDialog> {
  String _selectedValue = 'anyone';
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentSetting();
  }

  // Future<void> _loadCurrentSetting() async {
  //   try {
  //     final doc = await FirebaseFirestore.instance
  //         .collection('groupChats')
  //         .doc(widget.chatId)
  //         .get();

  //     final data = doc.data() as Map<String, dynamic>?;
  //     _selectedValue = data?['AddMembersBy'] ?? 'anyone';
  //   } catch (e) {
  //     _errorMessage = "Failed to load existing value: ${e.toString()}";
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

Future<void> _loadCurrentSetting() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('groupChats')
          .doc(widget.chatId)
          .get();

      final data = doc.data(); // No need for cast
      _selectedValue = data?['AddMembersBy'] ?? 'anyone';
    } catch (e) {
      _errorMessage = "Failed to load existing value: ${e.toString()}";
    } finally {
      setState(() => _isLoading = false);
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Who can Add Members',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const CircularProgressIndicator()
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedValue,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                              value: 'anyone', child: Text('Anyone')),
                          DropdownMenuItem(
                              value: 'admin only', child: Text('Admin Only')),
                        ],
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() => _selectedValue = newValue);
                          }
                        },
                      ),
                    ),
                  ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _handleSave,
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);

    try {
      await widget.onSave(_selectedValue);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to update: ${e.toString()}";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
