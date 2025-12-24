# ReactiveNotifier

`ReactiveNotifier<T>` is the core class for managing state. It wraps a value of type `T` and notifies listeners when the value changes. It is designed to be used as a singleton.

## Creation

You typically create a `ReactiveNotifier` as a static final variable in a mixin or class.

```dart
mixin MyService {
  static final ReactiveNotifier<int> counter = 
      ReactiveNotifier<int>(() => 0);
}
```

### Parameters

- `create`: A function that returns the initial state `T`.
- `related`: Optional list of related `ReactiveNotifier` instances (for dependency management).
- `key`: Optional `Key` for identifying the instance (mostly internal use).
- `autoDispose`: If `true`, the notifier will be automatically disposed when it has no listeners for a certain period.

## Methods

### `updateState(T newState)`

Updates the state to `newState` and notifies listeners.

```dart
MyService.counter.updateState(5);
```

### `updateSilently(T newState)`

Updates the state to `newState` **without** notifying listeners.

```dart
MyService.counter.updateSilently(5);
```

### `transformState(T Function(T) transformer)`

Updates the state by transforming the current state.

```dart
MyService.counter.transformState((current) => current + 1);
```

### `transformStateSilently(T Function(T) transformer)`

Updates the state by transforming the current state **without** notifying listeners.

```dart
MyService.counter.transformStateSilently((current) => current + 1);
```

## Lifecycle Management

### Auto Dispose

If `autoDispose` is set to `true` (default is `false`), the notifier will schedule itself for disposal when the last reference (listener) is removed.

```dart
static final instance = ReactiveNotifier<int>(
  () => 0,
  autoDispose: true,
);
```

### Manual Disposal

You can manually dispose a notifier and its resources.

```dart
MyService.instance.dispose();
```

### Cleaning

`cleanCurrentNotifier()` attempts to remove the instance from the global registry if it's unused.

```dart
MyService.instance.cleanCurrentNotifier();
```

## Re-initialization

You can recreate a disposed notifier or reset its state.

```dart
// Recreates the instance using the original factory function
MyService.instance.recreate();
```
