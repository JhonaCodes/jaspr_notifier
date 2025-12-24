# Context Management

`jaspr_notifier` provides a system to automatically give `ViewModel`s access to `BuildContext`. This is useful for navigation, accessing themes, or other context-dependent features.

## Automatic Registration

When you use any builder (`ReactiveBuilder`, `ReactiveViewModelBuilder`, etc.), the `BuildContext` of that component is automatically registered with the associated ViewModel.

## Accessing Context in ViewModel

In your `ViewModel` or `AsyncViewModelImpl`:

```dart
void doSomething() {
  if (hasContext) {
    final ctx = context; // BuildContext?
    // Use ctx
  }
}
```

### `requireContext()`

If context is mandatory, use `requireContext()` which throws a descriptive error if unavailable.

```dart
void navigate() {
  final ctx = requireContext('Navigation');
  // Navigate...
}
```

## Global Context

You can register a global context at the root of your app. This is useful for services that need context before any specific UI is built, or for persistent context access.

```dart
// In your App component
@override
Component build(BuildContext context) {
  ReactiveNotifier.initContext(context);
  return ...
}
```

Then in ViewModel:

```dart
final ctx = globalContext; // or requireGlobalContext()
```

## `waitForContext` (AsyncViewModel)

`AsyncViewModelImpl` has a `waitForContext` parameter. If set to `true`, `init()` will be delayed until a context becomes available (i.e., when the first builder mounts).

```dart
MyVM() : super(AsyncState.initial(), waitForContext: true);

@override
Future<void> init() async {
  // Context is guaranteed to be available here
  final theme = Theme.of(requireContext()); 
}
```
