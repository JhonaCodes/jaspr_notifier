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
final counter = CounterService.instance;

counter.listen((value) {
  print('Counter changed to: $value');
});

// Stop listening when done
counter.stopListening();
```

## Inter-ViewModel Communication

jaspr_notifier supports explicit, reactive communication between ViewModels using the `listenVM` API. This enables clean service-to-service communication with automatic state synchronization.

### Basic Communication Pattern

**Pattern:** One ViewModel listens to changes in another ViewModel and reacts accordingly.

```dart
// User Service
mixin UserService {
  static final ReactiveNotifierViewModel<UserViewModel, UserModel> currentUser =
    ReactiveNotifierViewModel<UserViewModel, UserModel>(() => UserViewModel());
}

// Notification Service
mixin NotificationService {
  static final ReactiveNotifierViewModel<NotificationViewModel, NotificationModel> notifications =
    ReactiveNotifierViewModel<NotificationViewModel, NotificationModel>(() => NotificationViewModel());
}

// User ViewModel - source of user state
class UserViewModel extends ViewModel<UserModel> {
  UserViewModel() : super(UserModel.guest());

  @override
  void init() {
    final cachedUser = LocalStorage.getUser();
    if (cachedUser != null) {
      updateSilently(cachedUser);
    }
  }

  void login(UserModel user) {
    updateState(user);
  }

  void logout() {
    updateState(UserModel.guest());
  }
}

// Notification ViewModel - listens to user changes
class NotificationViewModel extends ViewModel<NotificationModel> {
  NotificationViewModel() : super(NotificationModel.empty());

  // Instance variable to store current user state
  UserModel? currentUser;

  @override
  void init() {
    // listenVM returns current value AND sets up listener
    currentUser = UserService.currentUser.notifier.listenVM((userData) {
      // This callback executes on every user state change
      currentUser = userData;
      _updateNotificationsForUser(userData);
    });

    // Use the returned value for initial setup
    if (currentUser != null && currentUser!.isLoggedIn) {
      _loadInitialNotifications(currentUser!);
    }
  }

  void _updateNotificationsForUser(UserModel user) {
    if (!user.isLoggedIn) {
      updateState(NotificationModel.empty());
      return;
    }

    transformState((state) => state.copyWith(
      userId: user.id,
      userName: user.name,
    ));
  }

  Future<void> _loadInitialNotifications(UserModel user) async {
    final notifications = await _repository.getForUser(user.id);
    transformState((state) => state.copyWith(items: notifications));
  }
}
```

### Using in Components

```dart
class NotificationBadge extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    return ReactiveViewModelBuilder<NotificationViewModel, NotificationModel>(
      viewmodel: NotificationService.notifications.notifier,
      build: (notifications, vm, keep) {
        return div(classes: 'notification-badge', [
          Component.text('Notifications: ${notifications.unreadCount}'),
        ]);
      },
    );
  }
}
```

### Multiple Service Communication

A single ViewModel can listen to multiple services:

```dart
mixin SettingsService {
  static final ReactiveNotifierViewModel<SettingsViewModel, SettingsModel> settings =
    ReactiveNotifierViewModel<SettingsViewModel, SettingsModel>(() => SettingsViewModel());
}

class DashboardViewModel extends ViewModel<DashboardModel> {
  DashboardViewModel() : super(DashboardModel.initial());

  // Instance variables for cross-service state
  UserModel? currentUser;
  SettingsModel? currentSettings;

  @override
  void init() {
    // Listen to user changes
    currentUser = UserService.currentUser.notifier.listenVM((user) {
      currentUser = user;
      _updateDashboard();
    });

    // Listen to settings changes
    currentSettings = SettingsService.settings.notifier.listenVM((settings) {
      currentSettings = settings;
      _updateDashboard();
    });

    // Initial dashboard update
    _updateDashboard();
  }

  void _updateDashboard() {
    if (currentUser == null || currentSettings == null) return;

    transformState((state) => state.copyWith(
      userName: currentUser!.name,
      theme: currentSettings!.theme,
      language: currentSettings!.language,
    ));
  }
}
```

### callOnInit Parameter

Use `callOnInit: true` to execute the callback immediately with the current state:

```dart
@override
void init() {
  // Callback fires immediately, then on every subsequent change
  UserService.currentUser.notifier.listenVM((userData) {
    currentUser = userData;
    syncWithUser(userData);
  }, callOnInit: true);

  // No need to manually handle initial state - callback already executed
}
```

### Best Practices

**1. Always Store State in Instance Variables**

```dart
class MyViewModel extends ViewModel<MyModel> {
  // Store state from other services
  UserModel? currentUser;
  SettingsModel? currentSettings;
}
```

**2. Use Explicit Service References**

```dart
// CORRECT: Explicit and traceable
UserService.currentUser.notifier.listenVM((user) { ... });

// AVOID: Implicit lookups (not the jaspr_notifier way)
```

**3. Guard Against Null States**

```dart
void _updateDashboard() {
  if (currentUser == null) return;
  if (currentSettings == null) return;

  // Safe to use currentUser! and currentSettings!
}
```

**4. Use hasInitializedListenerExecution for Safety**

Prevent duplicate execution during initialization:

```dart
Future<void> _handleUserChange(UserModel user) async {
  if (!hasInitializedListenerExecution) return;
  await loadDataForUser(user);
}
```

### Memory Management

**Automatic Cleanup:** All `listenVM()` listeners are automatically cleaned up when `dispose()` is called on the ViewModel. No manual cleanup needed!

**Multiple Listeners:** Unlike `listen()`, `listenVM()` supports multiple concurrent listeners on the same ViewModel.

**Debug Monitoring:** Use `activeListenerCount` to monitor active listeners:

```dart
final count = UserService.currentUser.notifier.activeListenerCount;
print('User ViewModel has $count active listeners');
```

## ViewModel Lifecycle Hooks

jaspr_notifier provides powerful lifecycle hooks that give you fine-grained control over ViewModel behavior.

### onStateChanged Hook

Called automatically after **every** state change, providing access to both previous and new state values.

**Signature:**
```dart
@protected
void onStateChanged(T previous, T next)
```

**Use Cases:**
- Logging and analytics
- Automatic validation
- Side effects (theme changes, persistence)
- Derived state updates

**Example:**
```dart
class UserViewModel extends ViewModel<UserModel> {
  UserViewModel() : super(UserModel.guest());

  @override
  void onStateChanged(UserModel previous, UserModel next) {
    // Log authentication changes
    if (previous.isLoggedIn != next.isLoggedIn) {
      if (next.isLoggedIn) {
        print('User logged in: ${next.email}');
      } else {
        print('User logged out');
      }
    }

    // Validate email changes
    if (previous.email != next.email && next.email.isNotEmpty) {
      if (!_isValidEmail(next.email)) {
        _showEmailValidationError();
      }
    }

    // Persist changes
    if (previous != next) {
      LocalStorage.saveUser(next);
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
```

**Important:**
- Called for **both** `updateState()` and `updateSilently()`
- Never call `updateState()` inside `onStateChanged()` (creates infinite loop)
- Keep operations lightweight - defer heavy work

### onResume Hook

Called after initialization completes successfully - perfect for post-initialization tasks.

**Signature:**
```dart
@protected
FutureOr<void> onResume(T data) async
```

**Use Cases:**
- Setting up secondary listeners
- Starting background tasks
- Triggering follow-up actions
- Logging initialization completion

**Example:**
```dart
class DashboardViewModel extends AsyncViewModelImpl<DashboardData> {
  StreamSubscription? _realtimeSubscription;

  @override
  Future<DashboardData> init() async {
    return await dashboardService.fetchInitialData();
  }

  @override
  FutureOr<void> onResume(DashboardData? data) async {
    // Set up realtime updates after initial data loads
    _realtimeSubscription = dashboardService
        .realtimeUpdates()
        .listen(_handleRealtimeUpdate);

    print('Dashboard ready with ${data?.items.length ?? 0} items');
  }

  void _handleRealtimeUpdate(DashboardUpdate update) {
    transformDataState((current) => current?.applyUpdate(update));
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}
```

**Call Sequence:**
```
Constructor → init() → setupListeners() → onResume() → [Active State]
```

**Important:**
- Only called if `init()` succeeds (not called on error)
- Can be async or sync
- Handle null data gracefully in AsyncViewModelImpl
- Use for non-critical operations only

### setupListeners Hook

Centralized location for registering external listeners and establishing reactive connections.

**Signature:**
```dart
@mustCallSuper
Future<void> setupListeners({List<String> currentListeners = const []}) async
```

**Use Cases:**
- Register listeners to other ViewModels
- Set up inter-ViewModel communication
- Establish reactive data flow
- Register external service listeners

**Example:**
```dart
class NotificationViewModel extends ViewModel<NotificationModel> {
  NotificationViewModel() : super(NotificationModel.empty());

  UserModel? currentUser;

  @override
  Future<void> setupListeners({List<String> currentListeners = const []}) async {
    // Register listener to UserService
    currentUser = UserService.currentUser.notifier.listenVM((userData) {
      currentUser = userData;
      _updateNotificationsForUser(userData);
    });

    // Always call super
    await super.setupListeners(currentListeners: [
      'UserService.currentUser',
    ]);
  }

  void _updateNotificationsForUser(UserModel user) {
    if (!user.isLoggedIn) {
      updateState(NotificationModel.empty());
    }
  }
}
```

**Important:**
- **Always call `super.setupListeners()`**
- Called automatically after `init()`
- Paired with `removeListeners()` for cleanup

### removeListeners Hook

Cleanup method to remove all external listeners and prevent memory leaks.

**Signature:**
```dart
@mustCallSuper
Future<void> removeListeners({List<String> currentListeners = const []}) async
```

**Use Cases:**
- Clean up external listeners
- Cancel subscriptions
- Remove inter-ViewModel connections
- Prevent memory leaks

**Example:**
```dart
class DataSyncViewModel extends ViewModel<SyncState> {
  StreamSubscription? _subscription;

  @override
  Future<void> setupListeners({List<String> currentListeners = const []}) async {
    // Set up external subscription
    _subscription = externalService.updates.listen(_handleUpdate);

    await super.setupListeners(currentListeners: ['ExternalService']);
  }

  @override
  Future<void> removeListeners({List<String> currentListeners = const []}) async {
    // Clean up subscription
    _subscription?.cancel();
    _subscription = null;

    // Always call super
    await super.removeListeners(currentListeners: ['ExternalService']);
  }

  void _handleUpdate(UpdateEvent event) {
    transformState((state) => state.applyUpdate(event));
  }
}
```

**Important:**
- **Always call `super.removeListeners()`**
- Called automatically on `dispose()`
- Called before `init()` in `reload()`
- Pair with `setupListeners()` for proper cleanup

### Lifecycle Diagram

```
┌─────────────────────────────────────────────────────────┐
│                  ViewModel Lifecycle                     │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Constructor → init() → setupListeners() → onResume()   │
│                                                         │
│       │          │            │              │          │
│       ▼          ▼            ▼              ▼          │
│   Initial    Sync init   Register       Post-init      │
│   state      logic       listeners      tasks          │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  State Updates: updateState / transformState            │
│       │                                                 │
│       ▼                                                 │
│  onStateChanged(previous, next) → notifyListeners()     │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  reload() → removeListeners() → init() → ...            │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  dispose() → removeListeners() → cleanup → done         │
│                                                         │
└─────────────────────────────────────────────────────────┘
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