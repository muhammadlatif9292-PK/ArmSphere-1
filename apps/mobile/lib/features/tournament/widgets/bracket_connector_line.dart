import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
class BracketConnectorLine {
  final Offset startPt;
  final Offset endPt;
  final bool isHighlighted;

  BracketConnectorLine({
    required this.startPt,
    required this.endPt,
    required this.isHighlighted,
  });
}

