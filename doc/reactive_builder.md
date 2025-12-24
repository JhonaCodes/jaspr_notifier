# ReactiveBuilder

`ReactiveBuilder<T>` is the fundamental component for listening to `ReactiveNotifier<T>` changes.

## Usage

```dart
ReactiveBuilder<int>(
  notifier: CounterService.instance, // ReactiveNotifier<int>
  build: (count, notifier, keep) {
    return div([
      text('Count: $count'),
    ]);
  },
)
```

## Parameters

- `notifier`: The `ReactiveNotifier<T>` instance to listen to.
- `build`: A function that builds the component.
  - `state`: The current value `T`.
  - `notifier`: The notifier instance (useful for calling update methods).
  - `keep`: A function `Component Function(Component)` to prevent rebuilding static parts of the tree (optimization).

## Optimization with `keep`

Use `keep` to wrap components that don't depend on the state `T`. This prevents them from being destroyed and recreated on every update.

```dart
ReactiveBuilder<int>(
  notifier: service,
  build: (count, notifier, keep) {
    return div([
      text('Count: $count'),
      keep(HeavyComponent()), // Won't rebuild
    ]);
  },
)
```
