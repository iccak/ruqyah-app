import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/audio_item.dart';
import '../models/ruqyah_item.dart';

class EditRuqyahModal extends StatefulWidget {
  final RuqyahPlaylist? existingPlaylist;

  const EditRuqyahModal({Key? key, this.existingPlaylist}) : super(key: key);

  @override
  State<EditRuqyahModal> createState() => _EditRuqyahModalState();
}

class _EditRuqyahModalState extends State<EditRuqyahModal> {
  final TextEditingController _nameController = TextEditingController();
  final Map<String, int> _selectedAudioCounts = {};

  @override
  void initState() {
    super.initState();
    if (widget.existingPlaylist != null) {
      _nameController.text = widget.existingPlaylist!.name;
      for (var seq in widget.existingPlaylist!.sequence) {
        _selectedAudioCounts[seq.audioId] = seq.repeatCount;
      }
    }
  }

  void _savePlaylist() {
    if (_nameController.text.trim().isEmpty) return;

    final sequenceList = _selectedAudioCounts.entries
        .where((entry) => entry.value > 0)
        .map((entry) => RuqyahSequenceItem(audioId: entry.key, repeatCount: entry.value))
        .toList();

    final box = Hive.box<RuqyahPlaylist>('playlists');

    if (widget.existingPlaylist != null) {
      widget.existingPlaylist!.name = _nameController.text.trim();
      widget.existingPlaylist!.sequence = sequenceList;
      widget.existingPlaylist!.save();
    } else {
      final newPlaylist = RuqyahPlaylist(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        sequence: sequenceList,
      );
      box.put(newPlaylist.id, newPlaylist);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final audioBox = Hive.box<AudioItem>('audios');
    final allAudios = audioBox.values.toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 16,
        right: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existingPlaylist == null ? 'إنشاء رقية جديدة' : 'تعديل الرقية',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            style: const TextStyle(fontSize: 20),
            decoration: const InputDecoration(
              labelText: 'اسم الرقية (مثال: رقية النوم)',
              labelStyle: TextStyle(fontSize: 18),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('اختر السور وتكرار كل سورة:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          
          allAudios.isEmpty 
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('يرجى إضافة مقاطع mp3 من "مكتبة السور" أولاً', style: TextStyle(color: Colors.red, fontSize: 16)),
                )
              : Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: allAudios.length,
                    itemBuilder: (context, index) {
                      final audio = allAudios[index];
                      final count = _selectedAudioCounts[audio.id] ?? 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(audio.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.red, size: 32),
                                    onPressed: () {
                                      setState(() {
                                        if (count > 0) {
                                          _selectedAudioCounts[audio.id] = count - 1;
                                        }
                                      });
                                    },
                                  ),
                                  Text('$count', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle, color: Colors.green, size: 32),
                                    onPressed: () {
                                      setState(() {
                                        _selectedAudioCounts[audio.id] = count + 1;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

          const SizedBox(height: 16),
          SizedBox(
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
              onPressed: _savePlaylist,
              child: const Text('حفظ', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
