import 'package:flutter/material.dart';

Future<void> showSlyDialog(
  BuildContext context,
  String title,
  List<Widget> children,
) async {
  if (MediaQuery.of(context).size.width > 600) {
    await showGeneralDialog(
      barrierDismissible: true,
      barrierLabel: title,
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        return SimpleDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(18),
            ),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 24,
          ),
          contentPadding: const EdgeInsets.only(
            bottom: 24,
            left: 24,
            right: 24,
          ),
          titlePadding: const EdgeInsets.only(
            top: 32,
            bottom: 24,
            left: 16,
            right: 16,
          ),
          title: Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          children: children,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, widget) {
        final animIn = animation.status == AnimationStatus.forward;

        return FadeTransition(
          opacity: animation.drive(
            Tween(
              begin: 0.0,
              end: 1.0,
            ).chain(
              CurveTween(
                curve: animIn ? Curves.easeOutExpo : Curves.easeInOutQuint,
              ),
            ),
          ),
          child: ScaleTransition(
            scale: animation.drive(
              Tween(
                begin: animIn ? 1.2 : 1.6,
                end: 1.0,
              ).chain(
                CurveTween(
                  curve: animIn ? Curves.easeOutBack : Curves.easeOutQuint,
                ),
              ),
            ),
            child: widget,
          ),
        );
      },
    );
  } else {
    await showModalBottomSheet(
      barrierLabel: title,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      constraints: const BoxConstraints(
        maxWidth: 480,
      ),
      isScrollControlled: true,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 32,
                bottom: 24,
                left: 16,
                right: 16,
              ),
              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            ListView(
              padding: const EdgeInsets.only(
                bottom: 36,
                left: 24,
                right: 24,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: children,
            ),
          ],
        );
      },
    );
  }
}
