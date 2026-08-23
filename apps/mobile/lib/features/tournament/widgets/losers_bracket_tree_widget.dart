import 'package:flutter/material.dart';
import 'bracket_tree_widget.dart';
class LosersBracketTreeWidget extends StatelessWidget {
  final List<Map<String, dynamic>> losersMatches;

  const LosersBracketTreeWidget({
    Key? key,
    required this.losersMatches,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BracketTreeWidget(
      matches: losersMatches,
      titlePrefix: 'LOSERS',
    );
  }
}

