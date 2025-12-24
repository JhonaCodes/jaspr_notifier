# ViewModel

`ViewModel<T>` is an abstract class for managing complex synchronous state and business logic. It extends `ChangeNotifier` and integrates with `jaspr_notifier`'s lifecycle and context system.

## Creating a ViewModel

Extend `ViewModel<T>` where `T` is your state type.

```dart
class CounterViewModel extends ViewModel<int> {
  CounterViewModel() : super(0); // Initial state

  @override
  void init() {
    // Initialization logic (synchronous)
    print('ViewModel initialized');
  }

  void increment() {
    updateState(data + 1);
  }
}
```

## Accessing State

- `data`: Returns the current state `T`.
- `init()`: Called automatically on creation. Must be synchronous.

## Updating State

- `updateState(T newState)`: Updates state and notifies listeners.
- `updateSilently(T newState)`: Updates state without notifying.
- `transformState(T Function(T) transformer)`: Transforms current state and notifies.
- `transformStateSilently(T Function(T) transformer)`: Transforms current state without notifying.

## Lifecycle

- `init()`: Called once when the ViewModel is created.
- `dispose()`: Called when the ViewModel is disposed. Override to clean up resources (timers, streams).
- `onResume(T data)`: Called after initialization is complete.
- `onStateChanged(T previous, T next)`: Called after every state change.

```dart
@override
void onStateChanged(int previous, int next) {
  print('Changed from $previous to $next');
}
```

## Context Access

ViewModels have access to `BuildContext`. See [Context Management](context_management.md).

```dart
void navigate() {
  if (hasContext) {
    // Use context
  }
}
```

## Inter-ViewModel Communication

You can listen to other ViewModels safely.

### `setupListeners()`

Override this method to register listeners. It is called automatically after initialization.

```dart
@override
Future<void> setupListeners() async {
  // Listen to another ViewModel
  OtherService.instance.notifier.listenVM((otherState) {
    // React to change
    if (otherState.isLoggedIn) {
       loadUserData();
    }
  });
  
  // Or add standard listeners
  someExternalStream.listen((event) {
     updateState(event);
  });
}
```

### `removeListeners()`

Override this to clean up any external listeners (streams, etc.) when the ViewModel is disposed.

```dart
@override
Future<void> removeListeners() async {
  await _streamSubscription?.cancel();
  super.removeListeners();
}
```
