import 'dart:async';
import 'dart:collection';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_notifier/src/handler/stream_state.dart';
import 'package:jaspr_notifier/src/notifier/reactive_notifier.dart';

import 'no_rebuild_wrapper.dart';

class ReactiveStreamBuilder<VM, T> extends StatefulComponent {
  final ReactiveNotifier<Stream<T>> notifier;

  /// Called when the reactive [Stream] emits a new data event.
  ///
  /// This function provides:
  /// - [data]: The latest value emitted by the stream.
  /// - [state]: The [ReactiveNotifier] that holds the current stream state and allows additional interactions.
  /// - [keep]: A helper function to wrap components that should avoid unnecessary rebuilds.
  ///
  /// Use this builder to render UI based on live stream data while keeping performance optimizations in place.
  final Component Function(
    /// Latest value emitted by the stream.
    T data,

    /// The reactive state that wraps the stream and handles updates.
    VM viewmodel,

    /// Function to prevent unnecessary component rebuilds.
    /// Wrap stable child components with this to preserve identity across builds.
    Component Function(Component child) keep,
  ) onData;
  final Component Function()? onLoading;
  final Component Function(Object error)? onError;
  final Component Function()? onEmpty;
  final Component Function()? onDone;

  const ReactiveStreamBuilder({
    super.key,
    required this.notifier,
    required this.onData,
    this.onLoading,
    this.onError,
    this.onEmpty,
    this.onDone,
  });

  @override
  State<ReactiveStreamBuilder<VM, T>> createState() =>
      _ReactiveStreamBuilderState<VM, T>();
}

class _ReactiveStreamBuilderState<VM, T>
    extends State<ReactiveStreamBuilder<VM, T>> {
  StreamSubscription<T>? _subscription;
  StreamState<T> _state = StreamState<T>.initial();
  final HashMap<Key, NoRebuildWrapper> _noRebuildComponents = HashMap.from({});

  @override
  void initState() {
    super.initState();
    component.notifier.addListener(_onStreamChanged);
    _subscribe(component.notifier.notifier);
  }

  @override
  void dispose() {
    component.notifier.removeListener(_onStreamChanged);

    if (component.notifier.autoDispose && !component.notifier.hasListeners) {
      /// Clean current reactive and any dispose on Viewmodel
      component.notifier.cleanCurrentNotifier();
    }

    _noRebuildComponents.clear();
    _unsubscribe();
    super.dispose();
  }

  void _onStreamChanged() {
    _unsubscribe();
    _subscribe(component.notifier.notifier);
  }

  void _subscribe(Stream<T> stream) {
    setState(() => _state = StreamState.loading());

    _subscription = stream.listen(
      (data) => setState(() => _state = StreamState.data(data)),
      onError: (error) => setState(() => _state = StreamState.error(error)),
      onDone: () => setState(() => _state = StreamState.done()),
    );
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
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
    final result = _state.when(
      initial: () => component.onEmpty?.call(),
      loading: () => component.onLoading?.call() ?? Component.text('Loading...'),
      data: (data) => component.onData(data, (component.notifier as VM), _noRebuild),
      error: (error) => component.onError?.call(error) ?? Component.text('Error: $error'),
      done: () => component.onDone?.call(),
    );

    if (result != null) {
      return result;
    }

    // Return empty div if no result
    return div([]);
  }
}
