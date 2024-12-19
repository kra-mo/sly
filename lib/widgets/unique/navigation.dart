import 'package:flutter/material.dart';

import '/widgets/tooltip.dart';

class SlyNavigationRail extends StatelessWidget {
  final Function getSelectedPageIndex;
  final Function(int)? onDestinationSelected;

  const SlyNavigationRail({
    super.key,
    required this.getSelectedPageIndex,
    this.onDestinationSelected,
  });

  NavigationRailDestination _getDestination(String label, String asset) {
    return NavigationRailDestination(
      icon: SlyTooltip(
        message: label,
        child: ImageIcon(AssetImage(asset)),
      ),
      selectedIcon: ImageIcon(AssetImage(asset)),
      label: Text(label),
      padding: const EdgeInsets.only(bottom: 4),
    );
  }

  @override
  Widget build(BuildContext context) => NavigationRail(
        backgroundColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        selectedIndex: getSelectedPageIndex(),
        labelType: NavigationRailLabelType.selected,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(8),
          ),
        ),
        onDestinationSelected: onDestinationSelected,
        destinations: <NavigationRailDestination>[
          _getDestination('Light', 'assets/icons/light.webp'),
          _getDestination('Color', 'assets/icons/color.webp'),
          _getDestination('Effects', 'assets/icons/effects.webp'),
          _getDestination('Crop', 'assets/icons/crop.webp'),
          _getDestination('Export', 'assets/icons/export.webp'),
        ],
      );
}

class SlyNavigationBar extends StatelessWidget {
  final Function getSelectedPageIndex;
  final Function getShowCarousel;
  final VoidCallback? toggleCarousel;
  final Function(int)? onDestinationSelected;

  const SlyNavigationBar({
    super.key,
    required this.getSelectedPageIndex,
    required this.getShowCarousel,
    this.toggleCarousel,
    this.onDestinationSelected,
  });

  NavigationDestination _getDestination(String label, String asset) {
    return NavigationDestination(
      icon: ImageIcon(AssetImage(asset)),
      label: label,
    );
  }

  @override
  Widget build(BuildContext context) => NavigationBar(
        backgroundColor: Theme.of(context).hoverColor,
        indicatorColor: Colors.transparent,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(8),
          ),
        ),
        selectedIndex: getSelectedPageIndex(),
        onDestinationSelected: onDestinationSelected,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: <Widget>[
          _getDestination('Light', 'assets/icons/light.webp'),
          _getDestination('Color', 'assets/icons/color.webp'),
          _getDestination('Effects', 'assets/icons/effects.webp'),
          _getDestination('Crop', 'assets/icons/crop.webp'),
          _getDestination('Export', 'assets/icons/export.webp'),
          Semantics(
            label: 'More Images',
            child: FloatingActionButton.small(
              shape: const CircleBorder(),
              splashColor: Colors.transparent,
              elevation: 0,
              hoverElevation: 0,
              focusElevation: 0,
              disabledElevation: 0,
              highlightElevation: 0,
              onPressed: toggleCarousel,
              child: AnimatedRotation(
                turns: getShowCarousel() ? 1 / 8 : 0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                child: const ImageIcon(AssetImage('assets/icons/add.webp')),
              ),
            ),
          ),
        ],
      );
}
