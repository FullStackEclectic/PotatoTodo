import 'package:flutter/material.dart';

/// Fixed icon registry used for persisted category icon code points.
///
/// Keeping the available icons as compile-time constants allows Flutter Web to
/// tree-shake the Material Icons font while still supporting existing data.
class CategoryIcons {
  static const List<IconData> available = [
    Icons.label,
    Icons.work,
    Icons.person,
    Icons.school,
    Icons.shopping_cart,
    Icons.favorite,
    Icons.home,
    Icons.fitness_center,
    Icons.movie,
    Icons.music_note,
    Icons.flag,
    Icons.attach_money,
    Icons.lightbulb,
    Icons.pets,
    Icons.build,
    Icons.code,
    Icons.book,
    Icons.phone,
    Icons.mail,
    Icons.star,
    Icons.bookmark,
    Icons.local_cafe,
    Icons.restaurant,
    Icons.directions_run,
    Icons.sports_basketball,
    Icons.sports_esports,
    Icons.brush,
    Icons.camera_alt,
    Icons.laptop,
    Icons.phone_android,
    Icons.directions_car,
    Icons.flight,
    Icons.schedule,
    Icons.access_time,
    Icons.euro,
    Icons.account_balance,
    Icons.credit_card,
    Icons.cake,
    Icons.celebration,
    Icons.people,
    Icons.family_restroom,
    Icons.child_care,
    Icons.medical_services,
    Icons.local_hospital,
    Icons.library_books,
    Icons.description,
    Icons.menu_book,
    Icons.folder,
    Icons.meeting_room,
  ];

  static final Map<int, IconData> _byCodePoint = {
    for (final icon in available) icon.codePoint: icon,
  };

  static IconData fromCodePoint(int codePoint) {
    return _byCodePoint[codePoint] ?? Icons.label;
  }
}
