# AsyncViewModelImpl

`AsyncViewModelImpl<T>` is a specialized ViewModel for handling asynchronous state (loading, success, error). It wraps the state in an `AsyncState<T>` object.

## Creating an AsyncViewModel

Extend `AsyncViewModelImpl<T>`.

```dart
class UserViewModel extends AsyncViewModelImpl<User> {
  UserViewModel() : super(AsyncState.initial());

  @override
  Future<User> init() async {
    // Perform async operation
    return await api.fetchUser();
  }
}
```

## State Management

The state is wrapped in `AsyncState<T>`.

- `isLoading`: Returns true if loading.
- `hasData`: Returns true if data is successfully loaded.
- `data`: Returns the data `T` (throws if error).
- `error`: Returns error object if any.

## Initialization

- `init()`: Must return `Future<T>`. Called automatically if `loadOnInit` is true (default).
- `reload()`: Re-runs `init()` and updates state (sets loading, then data/error).

## Updating State

- `updateState(T data)`: Sets state to `success(data)`.
- `loadingState()`: Sets state to `loading`.
- `errorState(Object error, [StackTrace? stack])`: Sets state to `error`.
- `updateSilently(T data)`: Sets success state without notifying.
- `transformDataState(T? Function(T?) transformer)`: Transforms the data of the current success state.
- `transformDataStateSilently(T? Function(T?) transformer)`: Transforms data without notifying.
- `transformState(AsyncState<T> Function(AsyncState<T>) transformer)`: Transforms the entire state object.

## Configuration

You can configure initialization behavior in the constructor.

```dart
UserViewModel() : super(
  AsyncState.initial(),
  loadOnInit: true,      // Auto-call init()
  waitForContext: false, // Wait for context before init()?
);
```

If `waitForContext` is true, `init()` will only be called once a `ReactiveAsyncBuilder` (or other context provider) attaches and provides a context.

## Pattern Matching

Helper methods to handle UI based on state.

```dart
vm.when(
  initial: () => ...,
  loading: () => ...,
  success: (data) => ...,
  error: (err, stack) => ...,
)
```

## Listeners and Cleanup

Like `ViewModel`, you can override `setupListeners` and `removeListeners`.

```dart
@override
Future<void> setupListeners() async {
  // Listen to other viewmodels or streams
}

@override
Future<void> removeListeners() async {
  // Cancel subscriptions
  super.removeListeners();
}
```
