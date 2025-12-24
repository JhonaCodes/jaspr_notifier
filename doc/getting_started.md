# Getting Started

jaspr_notifier is a powerful state management solution for Jaspr, ported from `reactive_notifier`. It provides a clean, MVVM-inspired architecture with singleton-based state access.

## Installation

Add `jaspr_notifier` to your `pubspec.yaml`:

```yaml
dependencies:
  jaspr: ^0.22.0
  jaspr_notifier: ^1.0.0
```

Run `dart pub get` to install the package.

## Basic Usage (Mixin Pattern)

For simple global state, use the mixin pattern with `ReactiveNotifier`.

### 1. Create a Service

```dart
import 'package:jaspr_notifier/jaspr_notifier.dart';

mixin CounterService {
  // Create a singleton notifier
  static final ReactiveNotifier<int> instance =
      ReactiveNotifier<int>(() => 0);

  // Define actions
  static void increment() {
    instance.updateState(instance.notifier + 1);
  }
}
```

### 2. Consume in UI

Use `ReactiveBuilder` to listen to changes.

```dart
import 'package:jaspr/server.dart';
import 'package:jaspr_notifier/jaspr_notifier.dart';

class CounterComponent extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    return ReactiveBuilder<int>(
      notifier: CounterService.instance,
      build: (count, notifier, keep) {
        return div([
          text('Count: $count'),
          button(
            onClick: (_) => CounterService.increment(),
            [text('Increment')],
          ),
        ]);
      },
    );
  }
}
```

## Advanced Usage (ViewModel Pattern)

For complex business logic and lifecycle management, use `ViewModel`.

### 1. Create a ViewModel

```dart
class UserViewModel extends ViewModel<User> {
  UserViewModel() : super(User.empty());

  @override
  void init() {
    // Initialize data
  }

  void updateUser(String name) {
    updateState(data.copyWith(name: name));
  }
}
```

### 2. Create a Service Wrapper

```dart
mixin UserService {
  static final instance = ReactiveNotifier<UserViewModel>(
    () => UserViewModel(),
  );
}
```

### 3. Consume in UI

Use `ReactiveViewModelBuilder`.

```dart
ReactiveViewModelBuilder<UserViewModel, User>(
  viewmodel: UserService.instance.notifier, // or just UserService.instance
  build: (user, vm, keep) {
    return div([
      text('User: ${user.name}'),
      button(
        onClick: (_) => vm.updateUser('New Name'),
        [text('Update')],
      ),
    ]);
  },
)
```

## Next Steps

- Learn about [ReactiveNotifier](reactive_notifier.md)
- Explore [ViewModels](viewmodel.md) and [AsyncViewModels](async_viewmodel.md)
- Understand [Builders](reactive_builder.md)
