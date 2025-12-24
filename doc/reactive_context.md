# ReactiveContextBuilder

`ReactiveContextBuilder` is an advanced component that allows you to manually inject `ReactiveNotifier` instances into the component tree using `InheritedComponent` (similar to InheritedWidget in Flutter).

This strategy can provide performance benefits in very large trees by allowing deep descendants to access state without passing it down, although the singleton pattern of `ReactiveNotifier` usually makes this unnecessary for state access. The primary use case here is for scoping or when using `ReactiveContextEnhanced` features explicitly.

## Usage

```dart
ReactiveContextBuilder(
  forceInheritedFor: [MyService.instance],
  child: MyDeepComponent(),
)
```

In descendants:

```dart
// Enhanced context access (if extensions are used)
// or via standard lookup if available
```

*Note: For most applications, standard `ReactiveBuilder` usage with Singleton access is recommended and sufficient.*
