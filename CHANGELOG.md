# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2]
- Fix Imports

## [1.0.1]
- Update documentation

### Fixed
- **CRITICAL**: Changed import from `package:jaspr/client.dart` to `package:jaspr/jaspr.dart` in `viewmodel_impl.dart`
  - This fixes the "dart:js_interop is not available on this platform" error during server-side rendering
  - ViewModels can now be used in both server and client contexts without compilation errors
  - Resolves incompatibility with Jaspr's server-side rendering (SSR)

## [1.0.0]

### Added
- Initial release of jaspr_notifier
- Complete port of reactive_notifier for Jaspr framework
- `ViewModel<T>` for synchronous state management
- `AsyncViewModelImpl<T>` for async operations
- `ReactiveBuilder<T>` for basic reactive UI
- `ReactiveViewModelBuilder<VM, T>` for ViewModel-based UI
- `ReactiveAsyncBuilder<VM, T>` for async ViewModels
- `ReactiveStreamBuilder<VM, T>` for Stream-based data
- Singleton pattern with `.instance` accessor
- Automatic BuildContext access in ViewModels
- Global context initialization via `ReactiveNotifier.initContext()`
- Keep/NoRebuild optimization for expensive components
- Transform state functionality
- Manual listen/stopListening methods
- Comprehensive cleanup with `cleanupAll()`

### Changed
- Adapted all Widgets to Jaspr Components
- Converted `Widget build()` to `Component build()`
- Updated `Text()` widgets to `Component.text()` / `text()`
- Replaced Flutter HTML widgets with Jaspr DOM functions
- Modified lifecycle methods for Jaspr (didUpdateComponent)
- Removed Flutter-specific APIs (kFlutterMemoryAllocationsEnabled, WidgetsBinding)
- Updated Element.mounted checks to use try-catch pattern

### Technical
- Built on Jaspr 0.22.0
- 100% Dart implementation
- Full type safety maintained
- Zero breaking changes from reactive_notifier API
- All core patterns and philosophies preserved

### Documentation
- Complete README with examples
- API documentation
- Migration guide from reactive_notifier
- Comparison with other state management solutions

## [Unreleased]

### Planned
- Additional examples (todo app, API integration, form handling)
- Performance optimizations
- Enhanced error handling
- More comprehensive testing
- Video tutorials

---

## Version History

- **1.0.0** - Initial release (January 2025)

## Migration from reactive_notifier

If migrating from Flutter's reactive_notifier v4.x.x:

1. Update imports: `reactive_notifier` → `jaspr_notifier`
2. Change Widgets to Components in build methods
3. Replace Flutter widgets with Jaspr DOM elements
4. No changes to ViewModel logic or state management

All APIs remain identical to maintain seamless migration experience.
