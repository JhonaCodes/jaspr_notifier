# jaspr_notifier

[![pub package](https://img.shields.io/pub/v/jaspr_notifier.svg)](https://pub.dev/packages/jaspr_notifier)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**State management for Jaspr with MVVM-inspired ViewModels & Notifiers** - Direct port of [reactive_notifier](https://pub.dev/packages/reactive_notifier) for the Jaspr framework.

jaspr_notifier brings powerful, singleton-based state management to Jaspr web applications, maintaining the same philosophy and API as reactive_notifier but adapted for Jaspr's Component architecture.

## Features

- **Singleton Pattern** - Create once, reuse always.
- **MVVM Architecture** - Clean separation with ViewModel and AsyncViewModelImpl
- **Automatic Context** - BuildContext available in ViewModels automatically
- **Reactive Builders** - Efficient rebuilds with ReactiveBuilder, ReactiveViewModelBuilder, ReactiveAsyncBuilder
- **Type-Safe** - Full Dart type safety with generic support
- **Zero Boilerplate** - Minimal setup, maximum productivity
- **100% Jaspr Native** - Built specifically for Jaspr's Component system

## Philosophy

jaspr_notifier follows the **"create once, reuse always"** philosophy:
- State is created as singletons and accessed throughout the app
- No need for Provider wrappers or dependency injection
- Direct access from anywhere in your component tree
- Automatic cleanup and lifecycle management

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  jaspr: ^0.22.0
  jaspr_notifier: ^1.0.0
```

## Quick Start

### 1. Create a Service with Mixin Pattern

```dart
import 'package:jaspr_notifier/jaspr_notifier.dart';

// Use mixin pattern for reactive state
mixin CounterService {
  static final ReactiveNotifier<int> instance =
      ReactiveNotifier<int>(() => 0);

  static void increment() {
    instance.updateState(instance.notifier + 1);
  }

  static void decrement() {
    instance.updateState(instance.notifier - 1);
  }

  static void reset() {
    instance.updateState(0);
  }
}
```

### 2. Use ReactiveBuilder

```dart
import 'package:jaspr/server.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_notifier/jaspr_notifier.dart';

class CounterPage extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    return ReactiveBuilder<int>(
      notifier: CounterService.instance,
      build: (count, notifier, keep) {
        return div([
          Component.text('Count: $count'),
          button(
            onClick: (_) => CounterService.increment(),
            [Component.text('Increment')],
          ),
        ]);
      },
    );
  }
}
```

### 3. Run Your App

```dart
void main() {
  runApp(App());
}

class App extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    return Document(
      title: 'Counter App',
      body: CounterPage(),
    );
  }
}
```

## Core Concepts

### Two Patterns: Mixin vs ViewModel

jaspr_notifier provides two patterns depending on your needs:

#### Mixin Pattern - For Simple Reactive State

Use `mixin` with `ReactiveNotifier` for simple state management:

```dart
mixin CounterService {
  static final ReactiveNotifier<int> instance =
      ReactiveNotifier<int>(() => 0);

  static void increment() {
    instance.updateState(instance.notifier + 1);
  }
}

// Usage
ReactiveBuilder<int>(
  notifier: CounterService.instance,
  build: (count, notifier, keep) => Component.text('$count'),
)

// Call methods
CounterService.increment();
```

**Use when:**
- Simple state (primitives, simple models)
- Global state (theme, language, settings)
- Static utility services

#### ViewModel Pattern - For Complex Business Logic

Use `class extends ViewModel` for complex state with lifecycle:

```dart
class UserViewModel extends ViewModel<User> {
  UserViewModel() : super(User.empty());

  @override
  void init() {
    loadUser();
  }

  Future<void> loadUser() async {
    final user = await api.getUser();
    updateState(user);
  }
}

// Usage
ReactiveViewModelBuilder<UserViewModel, User>(
  viewmodel: UserViewModel.instance,
  build: (user, vm, keep) => Component.text(user.name),
)

// Call methods
UserViewModel.instance.loadUser();
```

**Use when:**
- Complex business logic
- Lifecycle hooks needed (init, onResume, onPause, dispose)
- BuildContext access required
- State change callbacks needed

### Singleton Access

**ViewModel** - For synchronous state:
```dart
class ThemeViewModel extends ViewModel<ThemeMode> {
  ThemeViewModel() : super(ThemeMode.light);

  void toggleTheme() {
    updateState(
      notifier == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light
    );
  }
}
```

**AsyncViewModelImpl** - For async operations:
```dart
class UserViewModel extends AsyncViewModelImpl<User> {
  @override
  Future<User> init() async {
    final response = await api.fetchUser();
    return User.fromJson(response);
  }

  Future<void> updateUser(User user) async {
    await api.updateUser(user);
    await reinit(); // Reload data
  }
}
```

### Reactive Builders

**ReactiveBuilder** - Basic reactive UI:
```dart
ReactiveBuilder<String>(
  notifier: messageNotifier,
  build: (message, notifier, keep) {
    return text(message);
  },
)
```

**ReactiveViewModelBuilder** - For ViewModels:
```dart
ReactiveViewModelBuilder<ThemeViewModel, ThemeMode>(
  viewmodel: ThemeViewModel.instance,
  build: (theme, vm, keep) {
    return div(classes: theme == ThemeMode.dark ? 'dark' : 'light', [
      button(
        onClick: (_) => vm.toggleTheme(),
        [text('Toggle Theme')],
      ),
    ]);
  },
)
```

**ReactiveAsyncBuilder** - For async operations:
```dart
ReactiveAsyncBuilder<UserViewModel, User>(
  notifier: UserViewModel.instance,
  onLoading: () => Component.text('Loading...'),
  onData: (user, vm, keep) {
    return div([
      text('Name: ${user.name}'),
      text('Email: ${user.email}'),
    ]);
  },
  onError: (error, stack) => Component.text('Error: $error'),
)
```

### BuildContext in ViewModels

ViewModels automatically have access to BuildContext:

```dart
class NavigationViewModel extends ViewModel<String> {
  NavigationViewModel() : super('/home');

  void navigateTo(String route) {
    updateState(route);

    // Access context directly
    if (hasContext) {
      final ctx = context!;
      // Use context for navigation, dialogs, etc.
    }
  }
}
```

### Global Context Initialization

Initialize global context once in your app root:

```dart
class App extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    // Initialize global context for all ViewModels
    ReactiveNotifier.initContext(context);

    return Document(
      title: 'My App',
      body: HomePage(),
    );
  }
}
```

## Advanced Features

### Keep/NoRebuild Optimization

Prevent expensive components from rebuilding:

```dart
ReactiveBuilder<User>(
  notifier: userNotifier,
  build: (user, notifier, keep) {
    return div([
      // This won't rebuild when user changes
      keep(ExpensiveChart()),

      // This rebuilds normally
      text('User: ${user.name}'),
    ]);
  },
)
```

### Transform State

Modify state with a transformer function:

```dart
class CartViewModel extends ViewModel<List<Item>> {
  CartViewModel() : super([]);

  void addItem(Item item) {
    transformState((cart) => [...cart, item]);
  }

  void removeItem(String id) {
    transformState((cart) => cart.where((i) => i.id != id).toList());
  }
}
```

### Listen to Changes

React to state changes programmatically:

```dart
final counter = CounterViewModel.instance;

counter.listen((value) {
  print('Counter changed to: $value');
});

// Stop listening when done
counter.stopListening();
```

### Cleanup

Clean up all ViewModels and notifiers:

```dart
ReactiveNotifier.cleanupAll();
```

## Migration from reactive_notifier

If you're migrating from Flutter's reactive_notifier:

1. **Imports** - Change `package:reactive_notifier` to `package:jaspr_notifier`
2. **Widgets → Components** - All builders now return `Component` instead of `Widget`
3. **Build Methods** - `Component build(BuildContext context)` instead of `Widget build`
4. **HTML Elements** - Use `div([])`, `text()`, `button()` instead of Flutter widgets
5. **Builder Parameters** - Rename `builder` to `build` (snyc) or `onData` (async) and check updated signatures
6. **No Changes** - ViewModel logic, state management, and patterns remain identical

## Examples

See the [example](example/) directory for:
- **counter_example.dart** - Basic counter with increment/decrement
- More examples coming soon

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see LICENSE file for details

## Credits

jaspr_notifier is a direct port of [reactive_notifier](https://pub.dev/packages/reactive_notifier) by @Jhonacodes, adapted specifically for the Jaspr framework.

## Links

- [Documentation](https://pub.dev/documentation/jaspr_notifier/latest/)
- [Pub.dev](https://pub.dev/packages/jaspr_notifier)
- [GitHub](https://github.com/JhonaCodes/jaspr_notifier)
- [Jaspr Framework](https://github.com/schultek/jaspr)
- [reactive_notifier (Flutter)](https://pub.dev/packages/reactive_notifier)