import 'package:flutter/material.dart';

class SlideInPageRoute extends PageRouteBuilder {
  final Widget page;

  SlideInPageRoute({required this.page})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero);
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            );

            return Stack(
              children: [
                // Add a dismissible barrier
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    color: Colors.black.withOpacity(animation.value * 0.5),
                  ),
                ),
                SlideTransition(
                  position: tween.animate(curvedAnimation),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500), // Max width of the panel
                      child: Material(
                        elevation: 16,
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          barrierColor: Colors.transparent, // Use a custom animated barrier
          barrierDismissible: true,
          opaque: false, // Important for barrier to be visible
        );
}
