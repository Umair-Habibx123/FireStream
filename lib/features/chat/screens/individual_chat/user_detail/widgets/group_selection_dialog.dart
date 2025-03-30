import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupSelectionDialog extends StatefulWidget {
  final List<QueryDocumentSnapshot> eligibleGroups;
  final String email;
  final String currentUserEmail;

  const GroupSelectionDialog({
    super.key,
    required this.eligibleGroups,
    required this.email,
    required this.currentUserEmail,
  });

  @override
  _GroupSelectionDialogState createState() => _GroupSelectionDialogState();
}

class _GroupSelectionDialogState extends State<GroupSelectionDialog> {
  late List<bool> selectedGroups;

  @override
  void initState() {
    super.initState();
    selectedGroups = widget.eligibleGroups.map((group) {
      List<dynamic> participants = group['participants'] ?? [];
      return participants.contains(widget.email);
    }).toList();
  }

  Future<void> _updateGroupSelections() async {
    for (int i = 0; i < widget.eligibleGroups.length; i++) {
      var group = widget.eligibleGroups[i];
      String groupId = group.id;
      List<dynamic> participants = group['participants'] ?? [];
      List<dynamic> admins = group['admins'] ?? [];

      if (!selectedGroups[i]) {
        if (participants.contains(widget.email)) {
          participants.remove(widget.email);
        }
        if (admins.contains(widget.email)) {
          admins.remove(widget.email);
        }
      }

      if (selectedGroups[i] && !participants.contains(widget.email)) {
        participants.add(widget.email);
      }

      await FirebaseFirestore.instance
          .collection('groupChats')
          .doc(groupId)
          .update({'participants': participants, 'admins': admins});
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Groups updated successfully.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blueAccent.shade200,
                    Colors.blueAccent.shade700,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.group, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Select Groups for ${widget.email}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: widget.eligibleGroups.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            "No groups available",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: widget.eligibleGroups.length,
                        itemBuilder: (context, index) {
                          var group = widget.eligibleGroups[index];
                          String groupName = group['groupName'] ?? 'Unnamed Group';
                          String groupPhotoUrl = group['groupPhotoUrl'] ?? '';

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: StatefulBuilder(
                              builder: (context, setState) {
                                return Card(
                                  elevation: 1,
                                  margin: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    tileColor: selectedGroups[index]
                                        ? Colors.blue.shade50
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        selectedGroups[index] = !selectedGroups[index];
                                      });
                                    },
                                    leading: groupPhotoUrl.isNotEmpty
                                        ? CircleAvatar(
                                            radius: 20,
                                            backgroundImage: NetworkImage(
                                              groupPhotoUrl,
                                            ),
                                            backgroundColor: Colors.grey.shade200,
                                          )
                                        : CircleAvatar(
                                            radius: 20,
                                            backgroundColor: Colors.blue.shade50,
                                            child: const Icon(
                                              Icons.group,
                                              color: Colors.blueAccent,
                                              size: 20,
                                            ),
                                          ),
                                    title: Text(
                                      groupName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    trailing: Checkbox(
                                      value: selectedGroups[index],
                                      onChanged: (value) {
                                        setState(() {
                                          selectedGroups[index] = value!;
                                        });
                                      },
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      activeColor: Colors.blueAccent,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueGrey,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _updateGroupSelections,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blueAccent.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Save"),
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