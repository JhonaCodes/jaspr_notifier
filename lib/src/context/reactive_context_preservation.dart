/// Component preservation functionality for ReactiveContext
///
/// This module provides enhanced component preservation capabilities through
/// extension methods and automatic key management, replacing the basic
/// NoRebuildWrapper with a more intuitive and powerful API.
///
/// Key improvements over NoRebuildWrapper:
/// - Extension methods for cleaner API
/// - Automatic key generation and management
/// - Batch preservation for multiple components
/// - Better debugging and logging
library reactive_context_preservation;

import 'dart:developer';

import 'package:jaspr/jaspr.dart';

/// Enhanced component preservation registry with automatic key management
///
/// This class provides a global registry for preserved components, automatically
/// managing keys and ensuring optimal performance through intelligent caching.
///
/// @protected - Internal class, not meant for direct usage
@protected
class _PreservationRegistry {
  /// Global registry for preserved components
  static final Map<String, Component> _preservedComponents = {};
  static final Map<String, int> _componentBuildCounts = {};
  static final Map<String, DateTime> _lastAccessed = {};

  /// Maximum cache size to prevent memory leaks
  static const int _maxCacheSize = 1000;

  /// Cache cleanup interval (in minutes)
  static const int _cleanupIntervalMinutes = 5;

  /// Preserve a component with automatic key management
  @protected
  static Component preserve(Component component, [String? key]) {
    // Generate automatic key if not provided
    final effectiveKey = key ?? _generateAutomaticKey(component);

    // Check if component is already preserved
    if (_preservedComponents.containsKey(effectiveKey)) {
      _updateAccessTime(effectiveKey);

      assert(() {
        log('[ReactiveContext] Using preserved component: $effectiveKey');
        return true;
      }());

      return _preservedComponents[effectiveKey]!;
    }

    // Clean up cache if necessary
    _cleanupCacheIfNeeded();

    // Create preserved component
    final preservedComponent = _PreservedComponent(
      key: ValueKey(effectiveKey),
      child: component,
    );

    // Store in registry
    _preservedComponents[effectiveKey] = preservedComponent;
    _componentBuildCounts[effectiveKey] = 0;
    _updateAccessTime(effectiveKey);

    assert(() {
      log('[ReactiveContext] Created preserved component: $effectiveKey');
      return true;
    }());

    return preservedComponent;
  }

  /// Preserve multiple components with batch operation
  @protected
  static List<Component> preserveAll(
    List<Component> components, [
    String? baseKey,
  ]) {
    final baseEffectiveKey =
        baseKey ?? 'batch_${DateTime.now().millisecondsSinceEpoch}';

    return components.asMap().entries.map((entry) {
      final index = entry.key;
      final component = entry.value;
      final key = '${baseEffectiveKey}_$index';

      return preserve(component, key);
    }).toList();
  }

  /// Generate automatic key based on component properties
  @protected
  static String _generateAutomaticKey(Component component) {
    final componentType = component.runtimeType.toString();
    final componentKey = component.key?.toString() ?? 'null';

    // Create hash based on component properties without timestamp for stability
    var hash = componentType.hashCode;
    hash = hash * 31 + componentKey.hashCode;

    return '${componentType}_${hash.abs()}';
  }

  /// Update access time for LRU cache management
  @protected
  static void _updateAccessTime(String key) {
    _lastAccessed[key] = DateTime.now();
  }

  /// Clean up cache if it exceeds maximum size
  @protected
  static void _cleanupCacheIfNeeded() {
    if (_preservedComponents.length < _maxCacheSize) return;

    final now = DateTime.now();
    final cutoffTime = now.subtract(
      const Duration(minutes: _cleanupIntervalMinutes),
    );

    // Remove old entries
    final keysToRemove = _lastAccessed.entries
        .where((entry) => entry.value.isBefore(cutoffTime))
        .map((entry) => entry.key)
        .toList();

    for (final key in keysToRemove) {
      _preservedComponents.remove(key);
      _componentBuildCounts.remove(key);
      _lastAccessed.remove(key);
    }

    // If still too large, remove least recently used
    if (_preservedComponents.length >= _maxCacheSize) {
      final sortedByAccess = _lastAccessed.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      final toRemove = sortedByAccess
          .take(_maxCacheSize ~/ 2)
          .map((e) => e.key);
      for (final key in toRemove) {
        _preservedComponents.remove(key);
        _componentBuildCounts.remove(key);
        _lastAccessed.remove(key);
      }
    }

    assert(() {
      log(
        '[ReactiveContext] Cleaned up preservation cache. Size: ${_preservedComponents.length}',
      );
      return true;
    }());
  }

  /// Get debug statistics for preservation registry
  @protected
  static Map<String, dynamic> getDebugStatistics() {
    return {
      'totalPreservedComponents': _preservedComponents.length,
      'averageBuildCount': _componentBuildCounts.values.isEmpty
          ? 0
          : _componentBuildCounts.values.reduce((a, b) => a + b) /
                _componentBuildCounts.length,
      'oldestPreservedComponent': _lastAccessed.values.isEmpty
          ? null
          : _lastAccessed.values
                .reduce((a, b) => a.isBefore(b) ? a : b)
                .toString(),
      'cacheUtilization':
          '${((_preservedComponents.length / _maxCacheSize) * 100).toStringAsFixed(1)}%',
    };
  }

  /// Clear all preserved components
  @protected
  static void cleanup() {
    _preservedComponents.clear();
    _componentBuildCounts.clear();
    _lastAccessed.clear();

    assert(() {
      log('[ReactiveContext] Preservation registry cleaned up');
      return true;
    }());
  }
}

/// Enhanced preserved component with better lifecycle management
///
/// This component provides better lifecycle management than NoRebuildWrapper,
/// with proper handling of component updates and debugging capabilities.
///
/// @protected - Internal component, not meant for direct usage
@protected
class _PreservedComponent extends StatefulComponent {
  final Component child;

  const _PreservedComponent({super.key, required this.child});

  @override
  State<_PreservedComponent> createState() => _PreservedComponentState();
}

@protected
class _PreservedComponentState extends State<_PreservedComponent> {
  late Component _preservedChild;
  int _buildCount = 0;

  @override
  void initState() {
    super.initState();
    _preservedChild = component.child;
    _incrementBuildCount();

    assert(() {
      log(
        '[ReactiveContext] Preserved component initialized: ${component.key}',
      );
      return true;
    }());
  }

  @override
  void didUpdateComponent(covariant _PreservedComponent oldComponent) {
    super.didUpdateComponent(oldComponent);

    // Only update if the child component has actually changed
    if (oldComponent.child != component.child) {
      _preservedChild = component.child;
      _incrementBuildCount();

      assert(() {
        log('[ReactiveContext] Preserved component updated: ${component.key}');
        return true;
      }());
    }
  }

  @override
  Component build(BuildContext context) {
    assert(() {
      log(
        '[ReactiveContext] Building preserved component: ${component.key} (build #$_buildCount)',
      );
      return true;
    }());

    return _preservedChild;
  }

  @protected
  void _incrementBuildCount() {
    _buildCount++;
    final keyStr = component.key.toString();
    _PreservationRegistry._componentBuildCounts[keyStr] = _buildCount;
  }
}

/// Extension methods for component preservation
///
/// These extensions provide a clean, intuitive API for component preservation
/// directly on Component objects, making it easy to preserve expensive components
/// without manual wrapper management.
extension ReactiveContextComponentPreservation on Component {
  /// Preserve this component with an optional key
  ///
  /// This method creates a preserved version of the component that won't rebuild
  /// when its parent rebuilds, providing significant performance benefits for
  /// expensive components.
  ///
  /// Usage:
  /// ```dart
  /// ExpensiveComponent().keep('my_key')
  /// ExpensiveComponent().keep() // Auto-generated key
  /// ```
  Component keep([String? key]) {
    return _PreservationRegistry.preserve(this, key);
  }
}

/// Extension methods for BuildContext preservation
///
/// These extensions provide context-aware component preservation capabilities,
/// allowing for more dynamic preservation strategies based on the current
/// build context.
extension ReactiveContextPreservation on BuildContext {
  /// Preserve a component with context-aware key generation
  ///
  /// This method provides context-aware preservation, automatically generating
  /// keys based on the current component context for better uniqueness.
  ///
  /// Usage:
  /// ```dart
  /// context.keep(ExpensiveComponent(), 'my_key')
  /// context.keep(ExpensiveComponent()) // Auto-generated key
  /// ```
  Component keep(Component component, [String? key]) {
    final contextKey = key ?? '${component.runtimeType}_${component.hashCode}';
    return _PreservationRegistry.preserve(component, contextKey);
  }

  /// Preserve multiple components with batch operation
  ///
  /// This method allows for batch preservation of multiple components with a
  /// single operation, automatically managing keys for each component.
  ///
  /// Usage:
  /// ```dart
  /// context.keepAll([component1, component2, component3], 'batch_key')
  /// context.keepAll([component1, component2, component3]) // Auto-generated keys
  /// ```
  List<Component> keepAll(List<Component> components, [String? baseKey]) {
    final contextBaseKey =
        baseKey ?? 'batch_${DateTime.now().millisecondsSinceEpoch}';
    return _PreservationRegistry.preserveAll(components, contextBaseKey);
  }
}

/// Enhanced component preservation with intelligent caching
///
/// This component provides explicit control over component preservation with
/// advanced caching strategies and automatic cleanup.
class ReactiveContextPreservationWrapper extends StatelessComponent {
  final Component child;
  final String? preservationKey;
  final bool enableAutomaticCleanup;

  const ReactiveContextPreservationWrapper({
    super.key,
    required this.child,
    this.preservationKey,
    this.enableAutomaticCleanup = true,
  });

  @override
  Component build(BuildContext context) {
    return _PreservationRegistry.preserve(child, preservationKey);
  }
}

/// Public API functions for component preservation
///
/// These functions provide a clean public API for component preservation
/// while using the enhanced internal implementation.

/// Preserve a component with automatic key management
///
/// This function provides a simple way to preserve components without using
/// extension methods, useful for functional programming patterns.
Component preserveComponent(Component component, [String? key]) {
  return _PreservationRegistry.preserve(component, key);
}

/// Preserve multiple components with batch operation
///
/// This function allows for batch preservation of multiple components with
/// automatic key management and optimization.
List<Component> preserveComponents(
  List<Component> components, [
  String? baseKey,
]) {
  return _PreservationRegistry.preserveAll(components, baseKey);
}

/// Get debug statistics for component preservation
///
/// This function provides detailed statistics about the preservation registry
/// for debugging and performance monitoring.
Map<String, dynamic> getPreservationStatistics() {
  return _PreservationRegistry.getDebugStatistics();
}

/// Clean up all preserved components
///
/// This function clears all preserved components from the registry, useful
/// for testing or memory management.
void cleanupPreservedComponents() {
  _PreservationRegistry.cleanup();
}
