import 'dart:collection';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr_notifier/jaspr_notifier.dart' show ReactiveNotifier;
import 'package:jaspr_notifier/src/notifier/notifier_impl.dart';
import 'package:jaspr_notifier/src/context/viewmodel_context_notifier.dart';

import 'no_rebuild_wrapper.dart';

/// Reactive Builder for simple state or direct model state.
class ReactiveBuilder<T> extends StatefulComponent {
  final NotifierImpl<T> notifier;

  /// Builds the component based on the current reactive state.
  ///
  /// This function provides:
  /// - [state]: The current reactive value of type `T`.
  /// - [notifier]: The internal ```NotifierImpl<T>``` containing state update methods and logic.
  /// - [keep]: A wrapper function used to prevent unnecessary component rebuilds by maintaining component identity.
  ///
  /// Useful for customizing the UI based on reactive changes while having full access to state logic and optimization tools.
  final Component Function(
    /// The current state value.
    T state,

    /// The notifier instance that provides update methods and internal logic.
    NotifierImpl<T> notifier,

    /// A wrapper that helps prevent unnecessary rebuilds.
    /// Wrap any component that should remain stable between state updates.
    Component Function(Component child) keep,
  )
  build;

  const ReactiveBuilder({
    super.key,
    required this.notifier,
    required this.build,
  });

  @override
  State<ReactiveBuilder<T>> createState() => _ReactiveBuilderState<T>();
}

class _ReactiveBuilderState<T> extends State<ReactiveBuilder<T>> {
  late T value;
  final HashMap<Key, NoRebuildWrapper> _noRebuildComponents = HashMap.from({});

  @override
  void initState() {
    super.initState();

    // Register context BEFORE accessing the notifier to ensure it's available during init()
    // Pass the actual notifier value if it's a ViewModel
    // Use unique identifier for each builder instance
    final notifierValue = component.notifier.notifier;
    final uniqueBuilderType = 'ReactiveBuilder<$T>_$hashCode';
    context.registerForViewModels(
      uniqueBuilderType,
      notifierValue is ChangeNotifier ? notifierValue : null,
    );

    // Add reference for component-aware lifecycle if notifier is ReactiveNotifier
    if (component.notifier is ReactiveNotifier) {
      final reactiveNotifier = component.notifier as ReactiveNotifier;
      reactiveNotifier.addReference('ReactiveBuilder_$hashCode');
    }

    value = notifierValue;
    component.notifier.addListener(_valueChanged);
  }

  @override
  void didUpdateComponent(ReactiveBuilder<T> oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.notifier != component.notifier) {
      // Remove reference from old notifier
      if (oldComponent.notifier is ReactiveNotifier) {
        final oldReactiveNotifier = oldComponent.notifier as ReactiveNotifier;
        oldReactiveNotifier.removeReference('ReactiveBuilder_$hashCode');
      }

      oldComponent.notifier.removeListener(_valueChanged);
      value = component.notifier.notifier;
      component.notifier.addListener(_valueChanged);

      // Add reference to new notifier
      if (component.notifier is ReactiveNotifier) {
        final reactiveNotifier = component.notifier as ReactiveNotifier;
        reactiveNotifier.addReference('ReactiveBuilder_$hashCode');
      }
    }
  }

  @override
  void dispose() {
    component.notifier.removeListener(_valueChanged);

    // Remove reference for component-aware lifecycle if notifier is ReactiveNotifier
    if (component.notifier is ReactiveNotifier) {
      final reactiveNotifier = component.notifier as ReactiveNotifier;
      reactiveNotifier.removeReference('ReactiveBuilder_$hashCode');

      // Legacy auto-dispose check (will be replaced by reference counting auto-dispose)
      if (reactiveNotifier.autoDispose && !reactiveNotifier.hasListeners) {
        /// Clean current reactive and any dispose on Viewmodel
        reactiveNotifier.cleanCurrentNotifier();
      }
    }

    // Automatically unregister context using the same unique identifier
    // Pass the actual notifier value if it's a ViewModel
    final notifierValue = component.notifier.notifier;
    final uniqueBuilderType = 'ReactiveBuilder<$T>_$hashCode';
    context.unregisterFromViewModels(
      uniqueBuilderType,
      notifierValue is ChangeNotifier ? notifierValue : null,
    );

    _noRebuildComponents.clear();

    super.dispose();
  }

  void _valueChanged() {
    if (mounted) {
      setState(() {
        value = component.notifier.notifier;
      });
    }
  }

  Component _noRebuild(Component keep) {
    final key = keep.key ?? ValueKey(keep.hashCode + keep.runtimeType.hashCode);
    if (!_noRebuildComponents.containsKey(key)) {
      _noRebuildComponents[key] = NoRebuildWrapper(child: keep);
    }
    return _noRebuildComponents[key]!;
  }

  @override
  Component build(BuildContext context) {
    // Note: Rebuild tracking disabled to avoid VM service errors
    // The in-app DevTool uses its own tracking mechanism

    return component.build(value, component.notifier, _noRebuild);
  }
}
