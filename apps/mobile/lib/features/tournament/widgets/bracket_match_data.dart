class BracketMatchData {
  final String p1;
  final String s1;
  final String p2;
  final String s2;
  final bool isUserMatch;
  final bool isOpponentMatch;
  final bool isFinished;
  final bool isLiveNext;
  final bool isUpcoming;
  final bool isTbd;

  BracketMatchData({
    required this.p1,
    required this.s1,
    required this.p2,
    required this.s2,
    this.isUserMatch = false,
    this.isOpponentMatch = false,
    this.isFinished = false,
    this.isLiveNext = false,
    this.isUpcoming = false,
    this.isTbd = false,
  });
}

