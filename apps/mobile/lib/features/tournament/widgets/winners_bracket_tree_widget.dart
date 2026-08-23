import 'package:flutter/material.dart';
import 'bracket_tree_widget.dart';
class WinnersBracketTreeWidget extends StatelessWidget {
  final List<Map<String, dynamic>> winnersMatches;

  const WinnersBracketTreeWidget({
    Key? key,
    required this.winnersMatches,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BracketTreeWidget(
      matches: winnersMatches,
      titlePrefix: 'WINNERS',
    );
  }
}

