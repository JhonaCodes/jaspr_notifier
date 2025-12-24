# Optimization

`jaspr_notifier` includes features to optimize rendering and prevent unnecessary rebuilds.

## The `keep` Function

In all builders (`ReactiveBuilder`, etc.), a `keep` function is provided.

```dart
(state, notifier, keep) => ...
```

This function wraps a Component in a `NoRebuildWrapper`. It tells Jaspr to preserve the existing component instance if it hasn't changed, bypassing the build phase for that subtree.

**When to use:**
- Static content (headers, footers).
- Expensive components that don't depend on the `state`.
- Images or complex SVG that are constant.

**Example:**

```dart
ReactiveBuilder<int>(
  notifier: counter,
  build: (count, notifier, keep) {
    return div([
      text('Count: $count'), // Rebuilds when count changes
      
      keep(MyExpensiveChart()), // Preserved across rebuilds!
    ]);
  },
)
```

## `updateSilently`

If you want to update the state but NOT trigger a UI rebuild (e.g., intermediate calculations, logging), use `updateSilently`.

```dart
notifier.updateSilently(newValue);
```

## `ReactiveContextBuilder` (Advanced)

For high-performance scenarios, `ReactiveContextBuilder` uses InheritedWidgets to strictly limit rebuild scope, though the standard builders are usually sufficient and easier to use.