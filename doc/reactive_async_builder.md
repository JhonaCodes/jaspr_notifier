# ReactiveAsyncBuilder

`ReactiveAsyncBuilder<VM, T>` is used with `AsyncViewModelImpl<T>`. It handles the 4 states of async data: initial, loading, success, and error.

## Usage

```dart
ReactiveAsyncBuilder<UserViewModel, User>(
  notifier: UserService.instance.notifier,
  onLoading: () => div([text('Loading...')]),
  onError: (err, stack) => div([text('Error: $err')]),
  onData: (user, vm, keep) {
    return div([
      text('User: ${user.name}'),
      button(
        onClick: (_) => vm.reload(),
        [text('Refresh')],
      ),
    ]);
  },
)
```

## Parameters

- `notifier`: The `AsyncViewModelImpl<T>` instance.
- `onData`: (Required) Called when state is success. Provides `data`, `vm`, and `keep`.
- `onLoading`: Optional. Called when loading. Defaults to "Loading...".
- `onError`: Optional. Called when error. Defaults to "Error: ...".
- `onInitial`: Optional. Called when state is initial (before loading starts).
