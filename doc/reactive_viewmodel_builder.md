# ReactiveViewModelBuilder

`ReactiveViewModelBuilder<VM, T>` is designed for use with `ViewModel<T>`. It provides access to both the state `T` and the ViewModel instance `VM`.

## Usage

```dart
ReactiveViewModelBuilder<UserViewModel, User>(
  viewmodel: UserService.instance.notifier,
  build: (user, vm, keep) {
    return div([
      text('User: ${user.name}'),
      button(
        onClick: (_) => vm.updateName('New'),
        [text('Update')],
      ),
    ]);
  },
)
```

## Parameters

- `viewmodel`: The `ViewModel<T>` instance.
- `build`: The build function.
  - `state`: The current state `T`.
  - `vm`: The ViewModel instance `VM`.
  - `keep`: Optimization wrapper.

## Auto-Context Registration

When this builder is mounted, it automatically registers the `BuildContext` with the ViewModel, making `vm.context` available.
