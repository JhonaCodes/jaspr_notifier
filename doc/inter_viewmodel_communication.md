# Inter-ViewModel Communication

One of the most powerful features of `jaspr_notifier` is the ability to easily and safely communicate between ViewModels. This allows you to build a reactive architecture where changes in one part of your app automatically trigger updates in others.

## The `listenVM` Method

The `listenVM` method is the core mechanism for this communication. It allows one ViewModel to listen to changes in another.

### Why use `listenVM` instead of `addListener`?

- **Automatic Cleanup**: `listenVM` tracks the subscription and automatically cleans it up when the listening ViewModel is disposed.
- **Cycle Safety**: It helps prevent memory leaks caused by circular references.
- **Simplified Syntax**: It provides the current state directly in the callback.

## Basic Usage

To listen to another ViewModel, override the `setupListeners` method in your ViewModel and use `listenVM`.

```dart
class CartViewModel extends ViewModel<List<Product>> {
  CartViewModel() : super([]);

  @override
  Future<void> setupListeners() async {
    // Listen to AuthViewModel
    // When the user logs out, clear the cart
    AuthService.instance.notifier.listenVM((authState) {
      if (!authState.isLoggedIn) {
        updateState([]); // Clear cart
      }
    });
  }
}
```

## Listening to AsyncViewModels

You can also listen to `AsyncViewModelImpl`. The callback receives the full `AsyncState<T>`.

```dart
class DashboardViewModel extends ViewModel<DashboardState> {
  DashboardViewModel() : super(DashboardState.initial());

  @override
  Future<void> setupListeners() async {
    // Listen to UserViewModel (Async)
    UserService.instance.notifier.listenVM((userState) {
      if (userState.isLoading) {
        // Show loading in dashboard
      } else if (userState.isSuccess) {
        // Update dashboard with user name
        transformState((state) => state.copyWith(userName: userState.data?.name));
      }
    });
  }
}
```

## `callOnInit`

By default, the callback is only fired for *subsequent* changes. If you want the callback to fire immediately with the *current* value when setting up the listener, set `callOnInit: true`.

```dart
OtherService.instance.notifier.listenVM(
  (state) {
    // Handle state
  },
  callOnInit: true, // Execute immediately with current state
);
```

## Lifecycle Methods

To effectively manage communication and side effects, `ViewModel` and `AsyncViewModelImpl` provide robust lifecycle hooks.

### `setupListeners()`

This method is called automatically after the ViewModel has been initialized. It is the designated place to register listeners.

- **For `ViewModel`**: Called after `init()`.
- **For `AsyncViewModelImpl`**: Called after the initial async `init()` completes.

### `removeListeners()`

Called automatically when the ViewModel is disposed. Override this if you need to manually cancel subscriptions that weren't created with `listenVM` (e.g., standard Dart Streams).

```dart
StreamSubscription? _sub;

@override
Future<void> setupListeners() async {
  // Standard stream
  _sub = someStream.listen((event) => updateState(event));
  
  // Safe listenVM (auto-cleaned)
  OtherService.instance.notifier.listenVM((_) => ...);
}

@override
Future<void> removeListeners() async {
  await _sub?.cancel(); // Manually clean standard stream
  super.removeListeners(); // Always call super
}
```

### `onResume(T data)`

Called after `setupListeners()` is complete. This is useful for logic that depends on both initialization and listeners being ready.

```dart
@override
FutureOr<void> onResume(T data) async {
  print('ViewModel is fully ready with data: $data');
  // Trigger initial actions that might depend on other ViewModels
}
```

### `onStateChanged` / `onAsyncStateChanged`

These hooks allow you to react to changes *within* the same ViewModel.

- **`ViewModel`**: `void onStateChanged(T previous, T next)`
- **`AsyncViewModelImpl`**: `void onAsyncStateChanged(AsyncState<T> previous, AsyncState<T> next)`

Useful for logging, analytics, or derived state updates.

```dart
@override
void onStateChanged(int previous, int next) {
  if (next > previous) {
    Analytics.logEvent('counter_incremented');
  }
}
```
