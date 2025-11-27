import 'dart:ui';

///this class is used for home screen only to refresh and update data when needed
class EventBus {
  static final _listeners = <VoidCallback>[];

  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  static void notifyHomeRefresh() {
    for (final listener in _listeners) {
      listener();
    }
  }
}
