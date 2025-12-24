/// A library for managing reactive state in Jaspr applications.
///
/// This library provides classes and components to manage state reactively,
/// ensuring a single instance of state per type and allowing for state
/// changes to trigger UI updates efficiently.
///
/// Port of reactive_notifier for Jaspr framework.

library jaspr_notifier;

/// Export [ReactiveAsyncBuilder] and [ReactiveStreamBuilder]
/// Export the [ReactiveBuilder] component which listens to a [ReactiveNotifier] and rebuilds
/// itself whenever the value changes.
export 'package:jaspr_notifier/src/builder/builder.dart';

/// Export the [AsyncState]
export 'package:jaspr_notifier/src/handler/async_state.dart';

/// Export the base [ReactiveNotifier] class which provides basic state management functionality.
export 'package:jaspr_notifier/src/notifier/reactive_notifier.dart';
export 'package:jaspr_notifier/src/builder/reactive_viewmodel_builder.dart';
export 'package:jaspr_notifier/src/notifier/reactive_notifier_viewmodel.dart';

/// Export ViewModelImpl
export 'package:jaspr_notifier/src/viewmodel/viewmodel_impl.dart';
export 'package:jaspr_notifier/src/viewmodel/async_viewmodel_impl.dart';

/// Export ReactiveContext functionality
export 'package:jaspr_notifier/src/context/reactive_context_extensions.dart';
export 'package:jaspr_notifier/src/context/reactive_context_preservation.dart';

/// Export ReactiveContext builder component
export 'package:jaspr_notifier/src/context/reactive_context_enhanced.dart'
    show ReactiveContextBuilder;

/// Export ViewModel Context Access (no need to import - works automatically)
/// ViewModelContextProvider mixin is already included in ViewModel and AsyncViewModelImpl
export 'package:jaspr_notifier/src/context/viewmodel_context_notifier.dart'
    show ViewModelContextService;
