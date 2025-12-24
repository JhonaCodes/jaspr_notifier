import 'dart:collection';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_notifier/jaspr_notifier.dart';
import 'package:jaspr_notifier/src/context/viewmodel_context_notifier.dart';

import 'no_rebuild_wrapper.dart';

class ReactiveAsyncBuilder<VM, T> extends StatefulComponent {
  final AsyncViewModelImpl<T> notifier;

  /// Called when the asynchronous state is available and ready to render.
  ///
  /// - [data]: The latest data value emitted by the state (typically a model or primitive).
  /// - [state]: The associated [AsyncViewModelImpl] that contains internal logic, actions,
  ///   and mutation methods related to this state.
  /// - [keep]: A helper function used to wrap components that should be preserved across rebuilds,
  ///   preventing unnecessary component reconstruction.
  ///
  /// This function is called only when the state has successfully loaded data.
  ///
  /// Example usage:
  /// ```dart
  /// onData: (data, viewModel, keep) {
  ///   return keep(
  ///     Text(data.title),
  ///   );
  /// }
  /// ```
  final Component Function(
      T data, VM viewmodel, Component Function(Component child) keep) onData;
  final Component Function()? onLoading;
  final Component Function(Object? error, StackTrace? stackTrace)? onError;
  final Component Function()? onInitial;

  const ReactiveAsyncBuilder({
    super.key,
    required this.notifier,
    required this.onData,
    this.onLoading,
    this.onError,
    this.onInitial,
  });

  @override
  State<ReactiveAsyncBuilder<VM, T>> createState() =>
      _ReactiveAsyncBuilderState<VM, T>();
}

class _ReactiveAsyncBuilderState<VM, T>
    extends State<ReactiveAsyncBuilder<VM, T>> {
  final HashMap<Key, NoRebuildWrapper> _noRebuildComponents = HashMap.from({});

  @override
  void initState() {
    super.initState();

    // Register context BEFORE accessing the notifier to ensure it's available during init()
    // Use unique identifier for each builder instance to handle multiple builders for same ViewModel
    final uniqueBuilderType = 'ReactiveAsyncBuilder<$VM,$T>_$hashCode';
    context.registerForViewModels(uniqueBuilderType, component.notifier);

    // Add reference for component-aware lifecycle if notifier is from ReactiveNotifier
    // We need to find the parent ReactiveNotifier that contains this AsyncViewModel
    _addReferenceToParentNotifier();

    // Call reinitializeWithContext for consistency with ReactiveViewModelBuilder
    (component.notifier as AsyncViewModelImpl).reinitializeWithContext();

    component.notifier.addListener(_valueChanged);
  }

  /// Find and add reference to the parent ReactiveNotifier that contains this AsyncViewModel
  void _addReferenceToParentNotifier() {
    try {
      // Look for a ReactiveNotifier that contains this AsyncViewModel
      final instances = ReactiveNotifier.getInstances;
      for (final instance in instances) {
        if (instance.notifier == component.notifier) {
          // Found the ReactiveNotifier containing this AsyncViewModel
          instance.addReference('ReactiveAsyncBuilder_$hashCode');
          break;
        }
      }
    } catch (e) {
      // If we can't find the parent ReactiveNotifier, that's okay
      // This AsyncViewModel might be used directly without ReactiveNotifier wrapper
    }
  }

  @override
  void didUpdateComponent(ReactiveAsyncBuilder<VM, T> oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.notifier != component.notifier) {
      // Remove reference from old notifier's parent ReactiveNotifier
      _removeReferenceFromParentNotifier(oldComponent.notifier);

      oldComponent.notifier.removeListener(_valueChanged);
      component.notifier.addListener(_valueChanged);

      // Add reference to new notifier's parent ReactiveNotifier
      _addReferenceToParentNotifier();
    }
  }

  /// Find and remove reference from the parent ReactiveNotifier that contains this AsyncViewModel
  void _removeReferenceFromParentNotifier(dynamic asyncViewModel) {
    try {
      // Look for a ReactiveNotifier that contains this AsyncViewModel
      final instances = ReactiveNotifier.getInstances;
      for (final instance in instances) {
        if (instance.notifier == asyncViewModel) {
          // Found the ReactiveNotifier containing this AsyncViewModel
          instance.removeReference('ReactiveAsyncBuilder_$hashCode');
          break;
        }
      }
    } catch (e) {
      // If we can't find the parent ReactiveNotifier, that's okay
      // This AsyncViewModel might be used directly without ReactiveNotifier wrapper
    }
  }

  @override
  void dispose() {
    component.notifier.removeListener(_valueChanged);

    // Remove reference from parent ReactiveNotifier
    _removeReferenceFromParentNotifier(component.notifier);

    // Automatically unregister context using the same unique identifier
    final uniqueBuilderType = 'ReactiveAsyncBuilder<$VM,$T>_$hashCode';
    context.unregisterFromViewModels(uniqueBuilderType, component.notifier);

    if (component.notifier is ReactiveNotifier) {
      final reactiveNotifier = component.notifier as ReactiveNotifier;
      if (reactiveNotifier.autoDispose && !reactiveNotifier.hasListeners) {
        /// Clean current reactive and any dispose on Viewmodel
        reactiveNotifier.cleanCurrentNotifier();
      }
    }

    _noRebuildComponents.clear();

    super.dispose();
  }

  void _valueChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Component _noRebuild(Component keep) {
    final key = keep.key ?? ValueKey(keep.hashCode);
    if (!_noRebuildComponents.containsKey(key)) {
      _noRebuildComponents[key] = NoRebuildWrapper(child: keep);
    }
    return _noRebuildComponents[key]!;
  }

  @override
  Component build(BuildContext context) {
    // Note: Rebuild tracking disabled to avoid VM service errors
    // The in-app DevTool uses its own tracking mechanism

    return component.notifier.when(
      initial: () => component.onInitial?.call() ?? div([]),
      loading: () => component.onLoading?.call() ?? Component.text('Loading...'),
      success: (data) =>
          component.onData(data, (component.notifier as VM), _noRebuild),
      error: (error, stackTrace) => component.onError != null
          ? component.onError!(error, stackTrace)
          : Component.text('Error: $error'),
    );
  }
}

/// A component that handles a Future and provides reactive notification
/// through a ReactiveNotifier to avoid flickering when navigating between screens.
///
/// This component combines the functionality of FutureBuilder with a reactive
/// state management approach, allowing immediate data display through [defaultData]
/// and notification of state changes through [createStateNotifier].
///
/// Example usage:
/// ```dart
/// ReactiveFutureBuilder<OrderItem?>(
///   future: OrderService.instance.notifier.loadById(orderId),
///   defaultData: OrderService.instance.notifier.getByPid(orderId),
///   createStateNotifier: OrderService.currentOrderItem,
///   onSuccess: (order) => ReactiveBuilder(
///     notifier: OrderService.currentOrderItem,
///     builder: (orderData, _) {
///       if (orderData == null) {
///         return const Text('Not found');
///       }
///       return OrderDetailView(order: orderData);
///     },
///   ),
///   onLoading: () => const Text('Loading...'),
///   onError: (error, stackTrace) => Text('Error: $error'),
/// )
/// ```
///
/// In this example, the component:
/// 1. Attempts to load data using a Future
/// 2. Shows default data immediately (if available) to prevent flickering
/// 3. Updates a ReactiveNotifier so other components can access the same data
/// 4. Handles loading, error, and success states appropriately
class ReactiveFutureBuilder<T> extends StatefulComponent {
  /// The Future that will provide the data.
  final Future<T> future;

  /// Builder function for rendering the UI when the Future completes successfully.
  /// Receives the data of type T from the Future and a keep function to prevent rebuilds.
  final Component Function(T data, Component Function(Component child) keep) onData;

  /// Optional builder function for the loading state.
  /// If not provided, a default loading text will be shown.
  final Component Function()? onLoading;

  /// Optional builder function for handling errors.
  /// Receives the error object and stack trace.
  final Component Function(Object? error, StackTrace? stackTrace)? onError;

  /// Optional builder function for the initial state before the Future is processed.
  /// If not provided, nothing will be rendered.
  final Component Function()? onInitial;

  /// Optional ReactiveNotifier that will be updated with the data from the Future.
  /// This allows other components to react to data changes.
  final ReactiveNotifier<T>?
      createStateNotifier; // Not sure if we need for AsyncViewmodelImpl, maybe just use ReactiveNotifier

  /// Controls whether state updates should trigger UI rebuilds.
  /// - If true, updates will notify listeners and trigger rebuilds.
  /// - If false, updates will be silent and won't trigger rebuilds.
  final bool notifyChangesFromNewState;

  /// Optional default data to display immediately without waiting for the Future.
  /// This is particularly useful to avoid flickering when navigating back to a screen.
  /// If provided, the Future will still be executed, but the UI will show these data first.
  final T? defaultData;

  /// Creates a ReactiveFutureBuilder.
  ///
  /// The [future] and [onData] parameters are required.
  /// All other parameters are optional.
  const ReactiveFutureBuilder({
    super.key,
    required this.future,
    required this.onData,
    this.onLoading,
    this.onError,
    this.onInitial,
    this.defaultData,
    this.createStateNotifier,
    this.notifyChangesFromNewState = false,
  });

  @override
  State<ReactiveFutureBuilder<T>> createState() =>
      _ReactiveFutureBuilderState<T>();
}

class _ReactiveFutureBuilderState<T> extends State<ReactiveFutureBuilder<T>> {
  final HashMap<Key, NoRebuildWrapper> _noRebuildComponents = HashMap.from({});

  // State tracking for Future
  bool _isLoading = false;
  T? _data;
  Object? _error;
  StackTrace? _stackTrace;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // Start loading the future if no default data
    if (component.defaultData == null) {
      _loadFuture();
    } else {
      _data = component.defaultData;
      _hasInitialized = true;
      _onCreateNotify(_data as T);
      // Still load the future in the background
      _loadFuture();
    }
  }

  void _loadFuture() {
    if (!_hasInitialized) {
      setState(() {
        _isLoading = true;
      });
    } else {
      _isLoading = true;
    }

    component.future.then((value) {
      if (mounted) {
        setState(() {
          _data = value;
          _isLoading = false;
          _error = null;
          _stackTrace = null;
          _hasInitialized = true;
        });
        _onCreateNotify(value);
      }
    }).catchError((error, stackTrace) {
      if (mounted) {
        setState(() {
          _error = error;
          _stackTrace = stackTrace;
          _isLoading = false;
          _hasInitialized = true;
        });
      }
    });
  }

  /// Updates the ReactiveNotifier with new data.
  ///
  /// Uses [component.notifyChangesFromNewState] to determine whether to call
  /// [updateState] or [updateSilently] on the notifier.
  void _onCreateNotify(T val) {
    if (component.createStateNotifier != null) {
      component.notifyChangesFromNewState
          ? component.createStateNotifier!.updateState(val)
          : component.createStateNotifier!.updateSilently(val);
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
  void dispose() {
    if (component.createStateNotifier != null) {
      component.createStateNotifier!.cleanCurrentNotifier();
    }
    _noRebuildComponents.clear();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    // If we have an error, show error state
    if (_error != null) {
      return component.onError != null
          ? component.onError!(_error, _stackTrace)
          : Component.text('Error: $_error');
    }

    // If we have data, show success state
    if (_data != null) {
      return component.onData(_data as T, _noRebuild);
    }

    // If loading, show loading state
    if (_isLoading) {
      return component.onLoading?.call() ?? Component.text('Loading...');
    }

    // Initial state - not yet initialized
    if (!_hasInitialized) {
      return component.onInitial?.call() ?? div([]);
    }

    // Fallback: return empty div
    return div([]);
  }
}
