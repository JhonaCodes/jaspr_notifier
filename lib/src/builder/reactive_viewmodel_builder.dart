import 'dart:collection';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr_notifier/jaspr_notifier.dart';
import 'package:jaspr_notifier/src/context/viewmodel_context_notifier.dart';

/// [ReactiveViewModelBuilder]
/// ReactiveViewModelBuilder is a specialized component for handling ViewModel states
/// It's designed to work specifically with StateNotifierImpl implementations
/// and provides efficient state management and rebuilding mechanisms
///
class ReactiveViewModelBuilder<VM, T> extends StatefulComponent {
  /// New ViewModel approach, takes precedence over notifier if both are provided
  final ViewModel<T> viewmodel;

  /// Builds the component based on the current [ViewModel] state.
  ///
  /// This function provides:
  /// - [state]: The current state value managed by the [ViewModel].
  /// - [viewmodel]: The [ViewModel] instance containing business logic, async control, and update methods.
  /// - [keep]: A helper function to prevent unnecessary component rebuilds by maintaining component identity.
  ///
  /// Use this builder when working with complex state logic encapsulated in a ```ViewModel<T>```.
  final Component Function(
    /// The current value of the reactive state.
    T state,

    /// The ViewModel that manages the internal logic and state updates.
    VM viewmodel,

    /// Function used to wrap components that should remain stable across rebuilds.
    Component Function(Component child) keep,
  )
  build;

  /// Constructor that ensures either notifier or viewmodel is provided
  const ReactiveViewModelBuilder({
    super.key,
    required this.viewmodel,
    required this.build,
  });

  @override
  State<ReactiveViewModelBuilder<VM, T>> createState() =>
      _ReactiveBuilderStateViewModel<VM, T>();
}

/// State class for ReactiveViewModelBuilder
class _ReactiveBuilderStateViewModel<VM, T>
    extends State<ReactiveViewModelBuilder<VM, T>> {
  /// Current value of the state
  late T value;

  /// Cache for components that shouldn't rebuild
  final HashMap<Key, _NoRebuildWrapperViewModel> _noRebuildComponents =
      HashMap.from({});

  @override
  void initState() {
    super.initState();

    // Register context BEFORE accessing the viewmodel to ensure it's available during init()
    // Use unique identifier for each builder instance to handle multiple builders for same ViewModel
    final uniqueBuilderType = 'ReactiveViewModelBuilder<$VM,$T>_$hashCode';
    context.registerForViewModels(uniqueBuilderType, component.viewmodel);

    // Add reference for component-aware lifecycle if viewmodel is from ReactiveNotifier
    // We need to find the parent ReactiveNotifier that contains this ViewModel
    _addReferenceToParentNotifier();

    // Re-initialize ViewModels that were created without context
    (component.viewmodel as ViewModel).reinitializeWithContext();

    // Initialize with data from either source
    value = component.viewmodel.data;

    // Subscribe to changes from either source
    component.viewmodel.addListener(_valueChanged);
  }

  /// Find and add reference to the parent ReactiveNotifier that contains this ViewModel
  void _addReferenceToParentNotifier() {
    try {
      // Look for a ReactiveNotifier that contains this ViewModel
      final instances = ReactiveNotifier.getInstances;
      for (final instance in instances) {
        if (instance.notifier == component.viewmodel) {
          // Found the ReactiveNotifier containing this ViewModel
          instance.addReference('ReactiveViewModelBuilder_$hashCode');
          break;
        }
      }
    } catch (e) {
      // If we can't find the parent ReactiveNotifier, that's okay
      // This ViewModel might be used directly without ReactiveNotifier wrapper
    }
  }

  @override
  void didUpdateComponent(ReactiveViewModelBuilder<VM, T> oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.viewmodel != component.viewmodel) {
      // Remove reference from old viewmodel's parent ReactiveNotifier
      _removeReferenceFromParentNotifier(oldComponent.viewmodel);

      oldComponent.viewmodel.removeListener(_valueChanged);
      value = component.viewmodel.data;
      component.viewmodel.addListener(_valueChanged);

      // Add reference to new viewmodel's parent ReactiveNotifier
      _addReferenceToParentNotifier();
    }
  }

  /// Find and remove reference from the parent ReactiveNotifier that contains this ViewModel
  void _removeReferenceFromParentNotifier(dynamic viewmodel) {
    try {
      // Look for a ReactiveNotifier that contains this ViewModel
      final instances = ReactiveNotifier.getInstances;
      for (final instance in instances) {
        if (instance.notifier == viewmodel) {
          // Found the ReactiveNotifier containing this ViewModel
          instance.removeReference('ReactiveViewModelBuilder_$hashCode');
          break;
        }
      }
    } catch (e) {
      // If we can't find the parent ReactiveNotifier, that's okay
      // This ViewModel might be used directly without ReactiveNotifier wrapper
    }
  }

  @override
  void dispose() {
    // Cleanup subscriptions and timer
    component.viewmodel.removeListener(_valueChanged);

    // Remove reference from parent ReactiveNotifier
    _removeReferenceFromParentNotifier(component.viewmodel);

    // Automatically unregister context using the same unique identifier
    final uniqueBuilderType = 'ReactiveViewModelBuilder<$VM,$T>_$hashCode';
    context.unregisterFromViewModels(uniqueBuilderType, component.viewmodel);

    // Handle auto-dispose if applicable
    if (component.viewmodel is ReactiveNotifierViewModel) {
      final reactiveViewModel =
          component.viewmodel as ReactiveNotifierViewModel;
      if (reactiveViewModel.autoDispose &&
          !reactiveViewModel.notifier.hasListeners) {
        reactiveViewModel.dispose();
      }
    }

    _noRebuildComponents.clear();

    super.dispose();
  }

  /// Handles state changes from the notifier
  void _valueChanged() {
    if (mounted) {
      setState(() {
        value = component.viewmodel.data;
      });
    }
  }

  /// Creates or retrieves a cached component that shouldn't rebuild
  Component _noRebuild(Component keep) {
    final key = keep.key ?? ValueKey(keep.hashCode);
    if (!_noRebuildComponents.containsKey(key)) {
      _noRebuildComponents[key] = _NoRebuildWrapperViewModel(builder: keep);
    }
    return _noRebuildComponents[key]!;
  }

  @override
  Component build(BuildContext context) {
    // Note: Rebuild tracking disabled to avoid VM service errors
    // The in-app DevTool uses its own tracking mechanism

    return component.build(value, (component.viewmodel as VM), _noRebuild);
  }
}

/// Component wrapper that prevents rebuilds of its children
/// Used by the _noRebuild function to optimize performance
class _NoRebuildWrapperViewModel extends StatefulComponent {
  /// The component to be wrapped and prevented from rebuilding
  final Component builder;

  const _NoRebuildWrapperViewModel({required this.builder});

  @override
  _NoRebuildWrapperStateViewModel createState() =>
      _NoRebuildWrapperStateViewModel();
}

/// State for _NoRebuildWrapperViewModel
/// Maintains a single instance of the child component
class _NoRebuildWrapperStateViewModel
    extends State<_NoRebuildWrapperViewModel> {
  /// Cached instance of the child component
  late Component child;

  @override
  void initState() {
    super.initState();
    // Store the initial component
    child = component.builder;
  }

  @override
  Component build(BuildContext context) {
    return child;
  }
}
