import 'package:jaspr/server.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_notifier/jaspr_notifier.dart';

/// Counter state model
class CounterState {
  final int count;
  final String message;

  CounterState({required this.count, required this.message});

  String get displayMessage {
    if (count == 0) return 'Start counting!';
    if (count > 0) return 'Count is positive: $count';
    return 'Count is negative: $count';
  }

  bool get isEven => count % 2 == 0;
}

/// Counter Service - manages counter state using mixin pattern
mixin CounterService {
  static final ReactiveNotifier<CounterState> instance =
      ReactiveNotifier<CounterState>(
        () => CounterState(count: 0, message: 'Start counting!'),
      );

  static void increment() {
    final current = instance.notifier;
    final newCount = current.count + 1;
    instance.updateState(
      CounterState(count: newCount, message: 'Incremented to $newCount'),
    );
  }

  static void decrement() {
    final current = instance.notifier;
    final newCount = current.count - 1;
    instance.updateState(
      CounterState(count: newCount, message: 'Decremented to $newCount'),
    );
  }

  static void reset() {
    instance.updateState(CounterState(count: 0, message: 'Counter reset!'));
  }
}

/// Counter component using ReactiveBuilder
class CounterExample extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    return ReactiveBuilder<CounterState>(
      notifier: CounterService.instance,
      build: (state, notifier, keep) {
        return div(classes: 'counter-container', [
          h1([Component.text('Jaspr Notifier Counter Example')]),
          div(classes: 'counter-display', [
            Component.text('Count: ${state.count}'),
          ]),
          div(classes: 'message', [Component.text(state.displayMessage)]),
          div(classes: 'button-group', [
            button(onClick: () => CounterService.decrement(), [
              Component.text('-'),
            ]),
            button(onClick: () => CounterService.reset(), [
              Component.text('Reset'),
            ]),
            button(onClick: () => CounterService.increment(), [
              Component.text('+'),
            ]),
          ]),
        ]);
      },
    );
  }
}

/// Main app
class App extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    return Document(
      title: 'Jaspr Notifier Example',
      head: [link(rel: 'stylesheet', href: 'styles.css')],
      body: CounterExample(),
    );
  }
}

void main() {
  runApp(App());
}