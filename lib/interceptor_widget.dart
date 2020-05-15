// Created by Ngoclv on 5/15/2020 14:59
// Copyright © 2020 VinID
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

typedef InterceptTouchEvent = bool Function();

typedef OnPointerAllowed = bool Function(PointerDownEvent);

class InterceptorWidget extends StatefulWidget {
  final OnPointerAllowed pointerAllowed;
  final VoidCallback onTap;
  final double width;
  final double height;

  InterceptorWidget({Key key, this.width, this.height,
    @required this.pointerAllowed, this.onTap})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _InterceptorState();
  }
}

class _InterceptorState extends State<InterceptorWidget> {

  Map<Type, GestureRecognizerFactory> gestures = <Type, GestureRecognizerFactory>{};
  _CustomTapGestureRecognizer gestureRecognizer;

  @override
  void initState() {
    super.initState();
   gestureRecognizer  =
    _CustomTapGestureRecognizer(
        pointerAllowed: _pointerAllowed, debugOwner: this);
    gestures[_CustomTapGestureRecognizer] = GestureRecognizerFactoryWithHandlers<_CustomTapGestureRecognizer>(
    () => gestureRecognizer, (_CustomTapGestureRecognizer instant) {
    instant..onTap = _tap;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: gestures,
      behavior: HitTestBehavior.translucent,
      child: _InnerWidget(
        width: widget.width,
        height: widget.height,
        interceptTouchEvent: gestureRecognizer.isAllowed,
      ),
    );
  }

  void _tap() {
    widget.onTap();
  }

  bool _pointerAllowed(PointerDownEvent event) {
    final ret = widget.pointerAllowed(event);
    if(ret == false) {
      SchedulerBinding.instance.addPostFrameCallback((_){
         gestureRecognizer.reset();
         setState(() {});
      });
    }
    return ret;
  }
}

class _CustomTapGestureRecognizer extends TapGestureRecognizer {
  VoidCallback onTap;
  final OnPointerAllowed pointerAllowed;
  bool _isAllowed = true;

  _CustomTapGestureRecognizer(
      {Object debugOwner, this.onTap, @required this.pointerAllowed})
      : super(debugOwner: debugOwner);

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    _isAllowed = pointerAllowed(event);
    return _isAllowed;
  }

  @override
  void handleTapUp({PointerDownEvent down, PointerUpEvent up}) {
    if (onTap != null) {
      invokeCallback('onPointerUp', onTap);
    }
  }

  bool isAllowed() => _isAllowed;
  void reset() {
    _isAllowed = true;
  }
}

class _InnerWidget extends SingleChildRenderObjectWidget {
  final InterceptTouchEvent interceptTouchEvent;
  final double width;
  final double height;

  _InnerWidget({this.width, this.height, this.interceptTouchEvent});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _SimpleRenderObject(interceptTouchEvent: interceptTouchEvent)
    ..width = width
    ..height = height;
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _SimpleRenderObject)..interceptTouchEvent =
        interceptTouchEvent
        ..width = width
        ..height = height;
  }
}

class _SimpleRenderObject extends RenderProxyBox {
  InterceptTouchEvent interceptTouchEvent;
  double width;
  double height;

  _SimpleRenderObject({RenderBox child, @required this.interceptTouchEvent})
      : super(child);

  @override
  void performLayout() {
    size = constraints.constrainDimensions(width?? 0, height?? 0);
  }

  bool hitTest(BoxHitTestResult result, {@required Offset position}) {
    return !interceptTouchEvent();
  }
}
