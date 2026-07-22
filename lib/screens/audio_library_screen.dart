import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/audio_item.dart';

class AudioLibraryScreen extends StatelessWidget {
  const AudioLibraryScreen({Key? key}) : super(key: key);

  Future<void> _importAudio(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
    );

    if (result != null && result.files.single.path != null) {
      final pickedFile = File(result.files.single.path!);
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(pickedFile.path);
      final savedPath = p.join(appDir.path, fileName);

      await pickedFile.copy(savedPath);

      final audioTitle = fileName.replaceAll('.mp3', '');
      final newItem = AudioItem(
        id: const Uuid().v4(),
        title: audioTitle,
        filePath: savedPath,
      );

      final box = Hive.box<AudioItem>('audios');
      await box.put(newItem.id, newItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioBox = Hive.box<AudioItem>('audios');

    return Scaffold(
      appBar: AppBar(
        title: const Text('مكتبة السور والصوتيات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.upload_file, size: 28),
                label: const Text('إضافة سورة جديدة (MP3)'),
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondary, foregroundColor: Colors.white),
                onPressed: () => _importAudio(context),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: audioBox.listenable(),
              builder: (context, Box<AudioItem> box, _) {
                if (box.isEmpty) {
                  return const Center(
                    child: Text('لم يتم تحميل أي ملفات صوتية بعد.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    final item = box.getAt(index)!;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(item.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 28),
                        onPressed: () async {
                          final file = File(item.filePath);
                          if (await file.exists()) await file.delete();
                          await item.delete();
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
