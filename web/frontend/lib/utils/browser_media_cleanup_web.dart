import 'dart:html' as html;

final Set<html.MediaStream> _activeStreams = <html.MediaStream>{};

void registerBrowserMediaStream(Object? stream) {
  if (stream is html.MediaStream) {
    _activeStreams.add(stream);
  }
}

void unregisterBrowserMediaStream(Object? stream) {
  if (stream is html.MediaStream) {
    _activeStreams.remove(stream);
  }
}

/// Synchronously stops all registered browser media tracks.
/// Used on tab close where async cleanup may not finish.
void stopAllBrowserMediaTracksSync() {
  for (final stream in _activeStreams.toList()) {
    for (final track in stream.getTracks()) {
      track.stop();
    }
  }
  _activeStreams.clear();
}
