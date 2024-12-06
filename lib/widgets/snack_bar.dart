import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '/widgets/spinner.dart';

void showSlySnackBar(
  BuildContext context,
  String message, {
  bool loading = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      elevation: 0,
      padding: const EdgeInsets.only(bottom: 16, right: 16),
      backgroundColor: Colors.transparent,
      content: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: EdgeInsets.only(
                left: constraints.maxWidth > 600
                    ? (constraints.maxWidth - 250)
                    : 16),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(
                ui.Radius.circular(8),
              ),
              child: Container(
                color: Theme.of(context).colorScheme.secondary,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: SlySpinner(),
                            )
                          : Container(),
                      loading ? const SizedBox(width: 16) : Container(),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
