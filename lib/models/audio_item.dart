import 'package:hive/hive.dart';

part 'audio_item.g.dart';

@HiveType(typeId: 0)
class AudioItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String filePath;

  AudioItem({
    required this.id,
    required this.title,
    required this.filePath,
  });
}
