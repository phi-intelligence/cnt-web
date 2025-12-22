import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/content_item.dart';
import '../utils/state_persistence.dart';
import 'dart:async';
import 'dart:math';

class AudioPlayerState extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final Random _random = Random();
  
  ContentItem? _currentTrack;
  List<ContentItem> _queue = [];
  List<ContentItem> _originalQueue = []; // Store original queue order for unshuffle
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  
  // Shuffle and repeat modes
  bool _shuffleEnabled = false;
  bool _repeatEnabled = false;      // Repeat entire queue
  bool _repeatOneEnabled = false;   // Repeat single track

  ContentItem? get currentTrack => _currentTrack;
  List<ContentItem> get queue => _queue;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  bool get shuffleEnabled => _shuffleEnabled;
  bool get repeatEnabled => _repeatEnabled;
  bool get repeatOneEnabled => _repeatOneEnabled;
  
  // Check if there's a next track available
  bool get hasNext {
    if (_queue.isEmpty || _currentTrack == null) return false;
    final currentIndex = _queue.indexOf(_currentTrack!);
    return currentIndex >= 0 && currentIndex < _queue.length - 1;
  }
  
  // Check if there's a previous track available
  bool get hasPrevious {
    if (_queue.isEmpty || _currentTrack == null) return false;
    final currentIndex = _queue.indexOf(_currentTrack!);
    return currentIndex > 0;
  }
  
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
    _player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        await _handleTrackCompletion();
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

  /// Seek to a specific position in the current track
  /// Handles edge cases like seeking beyond duration
  Future<void> seek(Duration position) async {
    try {
      // Clamp position to valid range
      final clampedPosition = Duration(
        milliseconds: position.inMilliseconds.clamp(0, _duration.inMilliseconds),
      );
      
      print('🎵 Seeking to: ${clampedPosition.inSeconds}s / ${_duration.inSeconds}s');
      
      await _player.seek(clampedPosition);
      _position = clampedPosition;
      _saveState();
      notifyListeners();
    } catch (e) {
      print('❌ Seek error: $e');
      _error = 'Failed to seek: $e';
      notifyListeners();
    }
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
  
  /// Handle track completion - auto-play next based on shuffle/repeat settings
  Future<void> _handleTrackCompletion() async {
    print('🎵 Track completed - checking auto-play settings');
    
    // Repeat One: replay the same track
    if (_repeatOneEnabled) {
      print('🔂 Repeat One enabled - replaying current track');
      await _player.seek(Duration.zero);
      await play();
      return;
    }
    
    // If we have a queue, try to play next
    if (_queue.isNotEmpty && _currentTrack != null) {
      final currentIndex = _queue.indexOf(_currentTrack!);
      
      if (currentIndex >= 0 && currentIndex < _queue.length - 1) {
        // Play next track in queue
        print('⏭️ Playing next track in queue');
        await next();
        return;
      } else if (_repeatEnabled && _queue.isNotEmpty) {
        // At end of queue but repeat is enabled - restart from beginning
        print('🔁 Repeat enabled - restarting queue from beginning');
        final firstTrack = _queue.first;
        await loadTrack(firstTrack);
        await play();
        return;
      }
    }
    
    // Repeat All with single track (no queue)
    if (_repeatEnabled && _currentTrack != null) {
      print('🔁 Repeat enabled - replaying single track');
      await _player.seek(Duration.zero);
      await play();
      return;
    }
    
    // No auto-play - keep track visible but mark as stopped
    // This allows users to see what they just listened to and replay if desired
    print('⏹️ Track completed - keeping track info visible');
    _isPlaying = false;
    _position = _duration; // Keep position at end so user can see it finished
    // Don't clear _currentTrack - keep it visible
    notifyListeners();
  }
  
  /// Toggle shuffle mode
  void toggleShuffle() {
    _shuffleEnabled = !_shuffleEnabled;
    
    if (_shuffleEnabled && _queue.isNotEmpty) {
      // Save original queue order and shuffle
      _originalQueue = List.from(_queue);
      _queue.shuffle(_random);
      print('🔀 Shuffle enabled - queue shuffled');
    } else if (!_shuffleEnabled && _originalQueue.isNotEmpty) {
      // Restore original queue order
      _queue = List.from(_originalQueue);
      print('🔀 Shuffle disabled - queue restored');
    }
    
    _saveState();
    notifyListeners();
  }
  
  /// Toggle repeat mode (cycles: off -> repeat all -> repeat one -> off)
  void toggleRepeat() {
    if (!_repeatEnabled && !_repeatOneEnabled) {
      // Off -> Repeat All
      _repeatEnabled = true;
      _repeatOneEnabled = false;
      print('🔁 Repeat All enabled');
    } else if (_repeatEnabled && !_repeatOneEnabled) {
      // Repeat All -> Repeat One
      _repeatEnabled = false;
      _repeatOneEnabled = true;
      print('🔂 Repeat One enabled');
    } else {
      // Repeat One -> Off
      _repeatEnabled = false;
      _repeatOneEnabled = false;
      print('🔁 Repeat disabled');
    }
    
    _saveState();
    notifyListeners();
  }
  
  /// Set shuffle directly
  void setShuffle(bool enabled) {
    if (_shuffleEnabled == enabled) return;
    toggleShuffle();
  }
  
  /// Set repeat mode directly
  void setRepeat({bool repeatAll = false, bool repeatOne = false}) {
    _repeatEnabled = repeatAll;
    _repeatOneEnabled = repeatOne;
    _saveState();
    notifyListeners();
  }
  
  /// Play a list of tracks starting at the specified index
  Future<void> playQueue(List<ContentItem> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) return;
    
    _queue = List.from(tracks);
    _originalQueue = List.from(tracks);
    
    if (_shuffleEnabled) {
      // If shuffle is on, shuffle the queue but keep start track first
      final startTrack = tracks[startIndex.clamp(0, tracks.length - 1)];
      _queue.shuffle(_random);
      // Move start track to front
      _queue.remove(startTrack);
      _queue.insert(0, startTrack);
    }
    
    final trackToPlay = _shuffleEnabled 
        ? _queue.first 
        : tracks[startIndex.clamp(0, tracks.length - 1)];
    
    print('🎵 Playing queue with ${tracks.length} tracks, starting at ${trackToPlay.title}');
    await loadTrack(trackToPlay);
    await play();
  }

  @override
  void dispose() {
    _positionSaveTimer?.cancel();
    _saveState(); // Final save on dispose
    _player.dispose();
    super.dispose();
  }
}

