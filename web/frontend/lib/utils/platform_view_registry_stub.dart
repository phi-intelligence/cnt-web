// Stub implementation for non-web platforms

/// Stub PlatformViewRegistry for non-web platforms
class PlatformViewRegistryStub {
  void registerViewFactory(String viewTypeId, dynamic Function(int) viewFactory) {
    throw UnsupportedError('Platform views are not supported on this platform.');
  }
}

/// Get stub platform view registry
dynamic getPlatformViewRegistry() {
  return PlatformViewRegistryStub();
}

