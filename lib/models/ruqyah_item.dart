import 'package:hive/hive.dart';

part 'ruqyah_item.g.dart';

@HiveType(typeId: 1)
class RuqyahSequenceItem {
  @HiveField(0)
  final String audioId;

  @HiveField(1)
  final int repeatCount;

  RuqyahSequenceItem({
    required this.audioId,
    required this.repeatCount,
  });
}

@HiveType(typeId: 2)
class RuqyahPlaylist extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<RuqyahSequenceItem> sequence;

  RuqyahPlaylist({
    required this.id,
    required this.name,
    required this.sequence,
  });
}
