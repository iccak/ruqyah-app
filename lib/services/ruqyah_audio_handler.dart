import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:hive/hive.dart';
import '../models/audio_item.dart';
import '../models/ruqyah_item.dart';

class RuqyahAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  List<RuqyahSequenceItem> _sequence = [];
  int _currentSequenceIndex = 0;
  int _currentIteration = 1;

  RuqyahAudioHandler() {
    _init();
  }

  void _init() {
    _player.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;

      if (processingState == ProcessingState.completed) {
        _handleTrackCompletion();
      }

      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (isPlaying) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[processingState]!,
        playing: isPlaying,
      ));
    });
  }

  Future<void> startRuqyah(RuqyahPlaylist playlist) async {
    _sequence = playlist.sequence;
    if (_sequence.isEmpty) return;

    _currentSequenceIndex = 0;
    _currentIteration = 1;

    await _playCurrentTrack();
  }

  Future<void> _playCurrentTrack() async {
    if (_currentSequenceIndex >= _sequence.length) {
      await stop();
      return;
    }

    final currentSeqItem = _sequence[_currentSequenceIndex];
    final audioBox = Hive.box<AudioItem>('audios');
    final audioItem = audioBox.get(currentSeqItem.audioId);

    if (audioItem == null) {
      _advanceSequence();
      return;
    }

    final mediaItem = MediaItem(
      id: audioItem.id,
      album: "الرقية الشرعية",
      title: audioItem.title,
      artist: "تكرار ${_currentIteration} من ${currentSeqItem.repeatCount}",
    );
    this.mediaItem.add(mediaItem);

    try {
      await _player.setFilePath(audioItem.filePath);
      await _player.play();
    } catch (e) {
      _advanceSequence();
    }
  }

  void _handleTrackCompletion() {
    final currentSeqItem = _sequence[_currentSequenceIndex];

    if (_currentIteration < currentSeqItem.repeatCount) {
      _currentIteration++;
      _playCurrentTrack();
    } else {
      _advanceSequence();
    }
  }

  void _advanceSequence() {
    _currentSequenceIndex++;
    _currentIteration = 1;
    if (_currentSequenceIndex < _sequence.length) {
      _playCurrentTrack();
    } else {
      stop();
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    _advanceSequence();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_currentSequenceIndex > 0) {
      _currentSequenceIndex--;
      _currentIteration = 1;
      _playCurrentTrack();
    }
  }
}
