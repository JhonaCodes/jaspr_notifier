# Migration from reactive_notifier

If you are coming from the Flutter `reactive_notifier` package, transitioning to `jaspr_notifier` is straightforward.

## Key Differences

1.  **Widgets vs Components**: Jaspr uses `Component` instead of `Widget`.
2.  **HTML Elements**: Instead of `Column`, `Row`, `Text`, you use `div()`, `span()`, `text()`, `button()`.
3.  **Imports**: 
    - Remove `package:reactive_notifier/reactive_notifier.dart`
    - Add `package:jaspr_notifier/jaspr_notifier.dart`

## Code Changes

### Builders

**Flutter:**
```dart
ReactiveBuilder<int>(
  notifier: service,
  builder: (context, count, child) { // Child optimization
    return Text('$count');
  },
)
```

**Jaspr:**
```dart
ReactiveBuilder<int>(
  notifier: service,
  build: (count, notifier, keep) { // build parameter is required
    return text('$count');
  },
)
```

The `builder` parameter has been renamed to `build` (for synchronous builders) or `onData` (for asynchronous builders) and its signature has been updated to include the notifier/viewmodel instance and the `keep` function.

### Summary of Builder Changes

| Component | Old Parameter | New Parameter | Signature |
|-----------|---------------|---------------|-----------|
| `ReactiveBuilder` | `builder` | `build` | `(state, notifier, keep)` |
| `ReactiveViewModelBuilder` | `builder` | `build` | `(state, vm, keep)` |
| `ReactiveAsyncBuilder` | `onSuccess` | `onData` | `(data, vm, keep)` |
| `ReactiveFutureBuilder` | `onSuccess` | `onData` | `(data, keep)` |


**Flutter Context:**
In Flutter, `BuildContext` is passed around. In `jaspr_notifier`, it is automatically injected, but you should use `hasContext` checks as context availability depends on the component tree.
