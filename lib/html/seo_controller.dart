import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:rxdart/rxdart.dart';
import 'package:seo/src/seo_html.dart';
import 'package:seo/src/seo_tag.dart';
import 'package:seo/src/seo_tree.dart';

class SeoController extends StatefulWidget {
  final bool enabled;

  final SeoTree tree;
  final Widget child;

  const SeoController({
    super.key,
    this.enabled = true,
    required this.tree,
    required this.child,
  });

  @override
  State<SeoController> createState() => _SeoControllerState();

  static Widget process({
    required BuildContext context,
    required SeoTag tag,
    required Widget child,
  }) {
    if (kIsWeb) {
      return context
          .dependOnInheritedWidgetOfExactType<_InheritedSeoTreeWidget>()!
          .tree
          .process(tag, child);
    } else {
      return const SizedBox.shrink();
    }
  }
}

class _SeoControllerState extends State<SeoController> {
  StreamSubscription? _subscription;
  int? _headHash;
  int? _bodyHash;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant SeoController oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.enabled != widget.enabled) {
      _subscribe();
    }
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = null;

    if (widget.enabled) {
      _subscription = widget.tree
          .changes()
          .debounceTime(const Duration(milliseconds: 250))
          .listen((_) => _update());
    }
  }

  void _update() async {
    if (!mounted) return;

    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      await SchedulerBinding.instance.endOfFrame;
      if (!mounted) return;
    }

    final html = widget.tree.traverse()?.toHtml();
    if (html != null) {
      _updateHead(html);
      _updateBody(html);
    }
  }

  void _updateHead(SeoHtml html) {
    final head = document.head;
    if (head == null) return;

    final hash = html.head.hashCode;
    if (_headHash == hash) return;
    _headHash = hash;

    head.children
        .where((element) => element.attributes.containsKey('flt-seo'))
        .forEach((element) => element.remove());

    head.insertAdjacentHtml(
      'beforeEnd',
      html.head,
      validator: NodeValidatorBuilder()
        ..allowHtml5(uriPolicy: _AllowAllUriPolicy())
        ..allowCustomElement(
          'meta',
          attributes: ['name', 'property', 'http-equiv', 'content', 'flt-seo'],
        )
        ..allowCustomElement(
          'link',
          attributes: ['title', 'rel', 'type', 'href', 'media', 'flt-seo'],
        )
        ..allowCustomElement(
          'script',
          attributes: ['type', 'flt-seo'],
        ),
    );
  }

  void _updateBody(SeoHtml html) {
    final body = document.body;
    if (body == null) return;

    final hash = html.body.hashCode;
    if (_bodyHash == hash) return;
    _bodyHash = hash;

    body.children
        .where((element) => element.localName == 'flt-seo')
        .forEach((element) => element.remove());

    body.insertAdjacentHtml(
      'afterBegin',
      '<flt-seo>${html.body}</flt-seo>',
      validator: NodeValidatorBuilder()
        ..allowHtml5(uriPolicy: _AllowAllUriPolicy())
        ..allowCustomElement('flt-seo')
        ..allowCustomElement('noscript')
        ..allowCustomElement('h1', attributes: ['style'])
        ..allowCustomElement('h2', attributes: ['style'])
        ..allowCustomElement('h3', attributes: ['style'])
        ..allowCustomElement('h4', attributes: ['style'])
        ..allowCustomElement('h5', attributes: ['style'])
        ..allowCustomElement('h6', attributes: ['style'])
        ..allowCustomElement('p', attributes: ['style']),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _InheritedSeoTreeWidget(
        tree: widget.tree,
        child: widget.child,
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}

class _AllowAllUriPolicy implements UriPolicy {
  @override
  bool allowsUri(String uri) => true;
}

class _InheritedSeoTreeWidget extends InheritedWidget {
  final SeoTree tree;

  const _InheritedSeoTreeWidget({
    required this.tree,
    required super.child,
  });

  @override
  bool updateShouldNotify(_InheritedSeoTreeWidget old) => true;
}
