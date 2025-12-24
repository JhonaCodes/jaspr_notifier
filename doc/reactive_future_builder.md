# ReactiveFutureBuilder

`ReactiveFutureBuilder<T>` combines a `Future` with `ReactiveNotifier`. It resolves a future and updates a notifier, while handling UI states.

## Usage

```dart
ReactiveFutureBuilder<User>(
  future: api.fetchUser(),
  createStateNotifier: UserService.instance, // Optional: update this notifier
  onLoading: () => text('Loading...'),
  onData: (user, keep) {
    return text('User: ${user.name}');
  },
  onError: (err, stack) => text('Error: $err'),
)
```

## Features

- **Flicker Prevention**: Can accept `defaultData` to show while loading.
- **State Sync**: Can update a `createStateNotifier` with the result.
- **Handling**: Manages loading, success, and error states similar to `ReactiveAsyncBuilder`.

## Parameters

- `future`: The future to resolve.
- `onData`: (Required) Builder for success state. Provides `data` and `keep`.
- `createStateNotifier`: Optional `ReactiveNotifier` to update with the result.
- `defaultData`: Data to show immediately.
- `notifyChangesFromNewState`: If true, notifying listeners when updating `createStateNotifier`.
