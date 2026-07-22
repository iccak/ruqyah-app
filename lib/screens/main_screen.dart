import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:audio_service/audio_service.dart';

import '../main.dart';
import '../models/audio_item.dart';
import '../models/ruqyah_item.dart';
import 'audio_library_screen.dart';
import 'edit_ruqyah_modal.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  void _showRuqyahModal(BuildContext context, [RuqyahPlaylist? playlist]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditRuqyahModal(existingPlaylist: playlist),
    );
  }

  void _deletePlaylist(BuildContext context, RuqyahPlaylist playlist) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الرقية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        content: Text('هل أنت تأكد من رغبتك في حذف "${playlist.name}"؟', style: const TextStyle(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontSize: 18)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
            onPressed: () {
              playlist.delete();
              Navigator.pop(ctx);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ruqyahBox = Hive.box<RuqyahPlaylist>('playlists');
    final audioBox = Hive.box<AudioItem>('audios');

    return Scaffold(
      appBar: AppBar(
        title: const Text('الرقية الشرعية', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.library_music, size: 30),
            tooltip: 'مكتبة السور',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AudioLibraryScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 28),
                label: const Text('إنشاء رقية جديدة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _showRuqyahModal(context),
              ),
            ),
          ),
          const Divider(thickness: 2),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: ruqyahBox.listenable(),
              builder: (context, Box<RuqyahPlaylist> box, _) {
                if (box.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد رقية مضافة حتى الآن.\nاضغط على "إنشاء رقية جديدة"',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    final playlist = box.getAt(index)!;

                    final summaryText = playlist.sequence.map((item) {
                      final audio = audioBox.get(item.audioId);
                      final title = audio?.title ?? "سورة مفقودة";
                      return "$title (${item.repeatCount} مرات)";
                    }).join(" ، ");

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.black12, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playlist.name,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black90),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              summaryText.isEmpty ? "لا تحتوي على سور" : summaryText,
                              style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[800],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  ),
                                  icon: const Icon(Icons.play_arrow, size: 28),
                                  label: const Text('تشغيل', style: TextStyle(fontSize: 18)),
                                  onPressed: () => audioHandler.startRuqyah(playlist),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 28, color: Colors.blue),
                                      onPressed: () => _showRuqyahModal(context, playlist),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 28, color: Colors.red),
                                      onPressed: () => _deletePlaylist(context, playlist),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const BottomAudioPlayerControl(),
        ],
      ),
    );
  }
}

class BottomAudioPlayerControl extends StatelessWidget {
  const BottomAudioPlayerControl({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, mediaSnapshot) {
        final mediaItem = mediaSnapshot.data;
        if (mediaItem == null) return const SizedBox.shrink();

        return Container(
          color: Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: StreamBuilder<PlaybackState>(
            stream: audioHandler.playbackState,
            builder: (context, stateSnapshot) {
              final state = stateSnapshot.data;
              final isPlaying = state?.playing ?? false;

              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          mediaItem.title,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          mediaItem.artist ?? '',
                          style: const TextStyle(color: Colors.amberAccent, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle, color: Colors.white, size: 40),
                    onPressed: isPlaying ? audioHandler.pause : audioHandler.play,
                  ),
                  IconButton(
                    icon: const Icon(Icons.stop_circle, color: Colors.redAccent, size: 40),
                    onPressed: audioHandler.stop,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
