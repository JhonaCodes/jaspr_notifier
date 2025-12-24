import 'dart:developer';

import 'package:jaspr/jaspr.dart';

class NoRebuildWrapper extends StatefulComponent {
  final Component child;

  const NoRebuildWrapper({super.key, required this.child});

  @override
  NoRebuildWrapperState createState() => NoRebuildWrapperState();
}

class NoRebuildWrapperState extends State<NoRebuildWrapper> {
  late Component _child;

  @override
  void initState() {
    super.initState();
    _child = component.child;
  }

  @override
  void didUpdateComponent(covariant NoRebuildWrapper oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.child != component.child) {
      log('Rebuild on keep old key: ${oldComponent.key.hashCode}  new key: ${component.key.hashCode}');
      // Warning: this breaks the "no rebuild" contract but is safer.
      _child = component.child;
    }
  }

  @override
  Component build(BuildContext context) {
    return _child;
  }
}
