import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Single shared taxonomy for Community Arena video clips, filter pills,
/// post badges, and the Share a Video Clip composer.
enum CommunityVideoCategory {
  technique('TECHNIQUE', 'Technique'),
  sparring('SPARRING', 'Sparring'),
  highlights('HIGHLIGHTS', 'Highlights'),
  tournaments('TOURNAMENTS', 'Tournaments');

  final String wireValue;
  final String label;

  const CommunityVideoCategory(this.wireValue, this.label);

  /// Normalizes canonical and legacy server category strings into the unified taxonomy.
  static CommunityVideoCategory? fromWire(String? raw) {
    if (raw == null) return null;
    final upper = raw.trim().toUpperCase();
    if (upper.isEmpty) return null;
    switch (upper) {
      case 'TECHNIQUE':
      case 'TUTORIALS':
      case 'TUTORIAL':
        return CommunityVideoCategory.technique;
      case 'SPARRING':
      case 'PRACTICE':
      case 'GYM':
        return CommunityVideoCategory.sparring;
      case 'HIGHLIGHTS':
      case 'HIGHLIGHT':
      case 'CLIPS':
        return CommunityVideoCategory.highlights;
      case 'TOURNAMENTS':
      case 'TOURNAMENT':
      case 'MATCHES':
      case 'EVENTS':
        return CommunityVideoCategory.tournaments;
      default:
        return null;
    }
  }

  /// Returns true when a post's raw category matches the selected filter chip.
  /// A null [selectedFilter] represents the "All" filter.
  static bool matchesFilter(
    String? rawCategory,
    CommunityVideoCategory? selectedFilter,
  ) {
    if (selectedFilter == null) return true;
    return fromWire(rawCategory) == selectedFilter;
  }

  /// Human-readable display badge label for post cards.
  static String displayLabelFor(String? rawCategory) {
    final resolved = fromWire(rawCategory);
    if (resolved != null) return resolved.label;
    final trimmed = (rawCategory ?? '').trim();
    return trimmed.isEmpty ? CommunityVideoCategory.highlights.label : trimmed;
  }

  /// Semantic accent color mapped strictly to existing AppTheme tokens.
  static Color accentColorFor(String? rawCategory) {
    final resolved = fromWire(rawCategory);
    switch (resolved) {
      case CommunityVideoCategory.technique:
        return AppTheme.cyan;
      case CommunityVideoCategory.sparring:
        return AppTheme.emerald;
      case CommunityVideoCategory.highlights:
        return AppTheme.goldPrimary;
      case CommunityVideoCategory.tournaments:
        return AppTheme.crimson;
      case null:
        return AppTheme.goldPrimary;
    }
  }
}
