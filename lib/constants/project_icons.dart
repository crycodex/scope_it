import 'package:flutter/material.dart';

/// Curated icon set for projects. Only these icons are used so tree-shaking works.
const List<IconData> kProjectIcons = [
  Icons.folder,
  Icons.language,
  Icons.phone_iphone,
  Icons.dns,
  Icons.smart_toy,
  Icons.business_center,
  Icons.palette,
  Icons.code,
  Icons.rocket_launch,
  Icons.shopping_cart,
  Icons.health_and_safety,
  Icons.school,
  Icons.restaurant,
  Icons.local_shipping,
  Icons.credit_card,
  Icons.analytics,
  Icons.dashboard,
  Icons.camera_alt,
  Icons.music_note,
  Icons.sports_soccer,
  Icons.travel_explore,
  Icons.store,
  Icons.home_work,
  Icons.construction,
];

/// Returns the [IconData] from [kProjectIcons] with the given code point, or null.
/// Use this instead of IconData(code, fontFamily: 'MaterialIcons') so icon font tree-shaking works.
IconData? iconDataFromCode(int codePoint) {
  for (final icon in kProjectIcons) {
    if (icon.codePoint == codePoint) return icon;
  }
  return null;
}
