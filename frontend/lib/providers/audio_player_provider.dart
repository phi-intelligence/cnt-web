import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/content_item.dart';

class AudioPlayerState extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  
  ContentItem? _currentTrack;
  List<ContentItem> _queue = [];
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;

  ContentItem? get currentTrack => _currentTrack;
  List<ContentItem> get queue => _queue;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;

  AudioPlayerState() {
    _initPlayer();
  }

  void _initPlayer() {
    _player.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });

    _player.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });

    _player.playingStream.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });

    // Listen for when playback completes
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        // Track finished - clear it so player disappears
        _currentTrack = null;
        _isPlaying = false;
        notifyListeners();
      }
    });

    // Note: loadingStateStream may not be available in this just_audio version
    // _player.loadingStateStream.listen((loadingState) {
    //   _isLoading = loadingState == LoadingState.loading || loadingState == LoadingState.buffering;
    //   notifyListeners();
    // });
  }

  Future<void> loadTrack(ContentItem track) async {
    if (track.audioUrl == null) {
      print('No audio URL available for track');
      return;
    }
    
    _currentTrack = track;
    try {
      await _player.setUrl(track.audioUrl!);
      await _player.setVolume(_volume);
      notifyListeners();
    } catch (e) {
      print('Error loading track: $e');
    }
  }

  /// Play a ContentItem directly (main entry point from UI)
  Future<void> playContent(ContentItem item) async {
    if (item.audioUrl == null) {
      print('No audio URL available for ${item.title}');
      return;
    }

    _currentTrack = item;
    try {
      print('Loading audio: ${item.audioUrl}');
      await _player.setUrl(item.audioUrl!);
      await _player.setVolume(_volume);
      await play(); // Auto-play
      notifyListeners();
    } catch (e) {
      print('Error playing content: $e');
      _error = 'Failed to play audio: $e';
      notifyListeners();
    }
  }

  String? _error;
  String? get error => _error;

  Future<void> play() async {
    try {
      await _player.play();
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      print('Error playing: $e');
    }
  }

  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
    notifyListeners();
  }

  /// Stop playback and clear current track
  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _currentTrack = null;
    _position = Duration.zero;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
    notifyListeners();
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
    notifyListeners();
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;
    
    final currentIndex = _queue.indexOf(_currentTrack!);
    if (currentIndex >= 0 && currentIndex < _queue.length - 1) {
      final nextTrack = _queue[currentIndex + 1];
      await loadTrack(nextTrack);
      await play();
    }
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;
    
    final currentIndex = _queue.indexOf(_currentTrack!);
    if (currentIndex > 0) {
      final prevTrack = _queue[currentIndex - 1];
      await loadTrack(prevTrack);
      await play();
    } else {
      // Restart current track
      await seek(Duration.zero);
    }
  }

  void addToQueue(ContentItem track) {
    _queue.add(track);
    notifyListeners();
  }

  void clearQueue() {
    _queue.clear();
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

