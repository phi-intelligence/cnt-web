import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/content_item.dart';
import '../utils/state_persistence.dart';
import 'dart:async';

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
  
  Timer? _positionSaveTimer;

  AudioPlayerState() {
    _initPlayer();
    _loadSavedState();
  }
  
  Future<void> _loadSavedState() async {
    try {
      final savedState = await StatePersistence.loadMusicPlayerState();
      if (savedState != null) {
        final savedTrackId = savedState['currentTrackId'] as String?;
        final savedPositionMs = savedState['currentTrackPositionMs'] as int?;
        final savedIsPlaying = savedState['isPlaying'] as bool?;
        final savedVolume = savedState['volume'] as double?;
        
        // Restore volume if saved
        if (savedVolume != null && savedVolume > 0) {
          await setVolume(savedVolume);
        }
        
        // Note: We can't restore the track itself here because we need ContentItem
        // The UI should check for saved state and restore the track separately
        // For now, we'll save the track ID and let the UI handle restoration
        
        print('✅ Restored music player state: trackId=$savedTrackId, position=$savedPositionMs, playing=$savedIsPlaying');
      }
    } catch (e) {
      print('❌ Error loading music player state: $e');
    }
  }
  
  Future<void> _saveState() async {
    try {
      final trackId = _currentTrack?.id?.toString();
      final queueIds = _queue.map((track) => track.id?.toString()).whereType<String>().toList();
      
      await StatePersistence.saveMusicPlayerState(
        currentTrackId: trackId,
        currentTrackPositionMs: _position.inMilliseconds,
        queueTrackIds: queueIds.isNotEmpty ? queueIds : null,
        isPlaying: _isPlaying,
        volume: _volume,
      );
    } catch (e) {
      print('⚠️ Error saving music player state: $e');
    }
  }
  
  void _schedulePositionSave() {
    _positionSaveTimer?.cancel();
    // Save position every 5 seconds
    _positionSaveTimer = Timer(const Duration(seconds: 5), () {
      _saveState();
    });
  }

  void _initPlayer() {
    _player.positionStream.listen((position) {
      _position = position;
      _schedulePositionSave(); // Auto-save position periodically
      notifyListeners();
    });

    _player.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });

    _player.playingStream.listen((playing) {
      _isPlaying = playing;
      _saveState(); // Save immediately when playing state changes
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
      _saveState(); // Save when track changes
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
      
      // Check if we should restore position from saved state
      final savedState = await StatePersistence.loadMusicPlayerState();
      if (savedState != null) {
        final savedTrackId = savedState['currentTrackId'] as String?;
        final savedPositionMs = savedState['currentTrackPositionMs'] as int?;
        
        // If this is the same track and we have a saved position, restore it
        if (savedTrackId == item.id?.toString() && savedPositionMs != null && savedPositionMs > 0) {
          await _player.seek(Duration(milliseconds: savedPositionMs));
        }
      }
      
      await play(); // Auto-play
      _saveState(); // Save when track starts playing
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
    _saveState(); // Save when volume changes
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
    _saveState(); // Save when queue changes
    notifyListeners();
  }

  void clearQueue() {
    _queue.clear();
    _saveState(); // Save when queue changes
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
    _positionSaveTimer?.cancel();
    _saveState(); // Final save on dispose
    _player.dispose();
    super.dispose();
  }
}

