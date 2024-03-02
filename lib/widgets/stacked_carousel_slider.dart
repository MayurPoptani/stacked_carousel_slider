import 'dart:math';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:indexed/indexed.dart';

class StackedCarouselSlider extends StatefulWidget {
  final List<Widget> items;
  final EdgeInsets padding;
  final PageController? controller;
  final void Function(int)? onTap;
  final void Function(int)? onPageChanged;
  final double pageOverlappingOffset;
  const StackedCarouselSlider({
    super.key,
    required this.items,
    this.padding = EdgeInsets.zero,
    this.controller,
    this.onTap,
    this.onPageChanged,
    this.pageOverlappingOffset = 12,
  });

  @override
  State<StackedCarouselSlider> createState() => _StackedCarouselSliderState();

  static int getInitialPageIndex(int itemCount) {
    final indexesList = List.generate(
      itemCount * 25,
      (index) => index % itemCount,
    );
    if (indexesList.isEmpty) return 0;
    int initialIndex = indexesList.length ~/ 2;
    return initialIndex - indexesList[initialIndex];
  }
}

class _StackedCarouselSliderState extends State<StackedCarouselSlider>
    with AutomaticKeepAliveClientMixin {
  late final PageController _pageController;
  late double centerIndex;
  late List<int> indexesList;
  Offset? _tapOffset;
  late double maxWidth;

  @override
  void initState() {
    indexesList = List.generate(
      widget.items.length * 100,
      (index) => index % widget.items.length,
    );
    int initialIndex = indexesList.length ~/ 2;
    initialIndex = initialIndex - indexesList[initialIndex];
    if (widget.controller != null) {
      _pageController = widget.controller!;
      centerIndex = _pageController.hasClients
          ? _pageController.page!
          : _pageController.initialPage.toDouble();
    } else {
      _pageController = PageController(
        viewportFraction: .8,
        initialPage: widget.items.isNotEmpty ? widget.items.length + 1 : 0,
      );
      centerIndex = _pageController.initialPage.toDouble();
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _pageController.jumpToPage(initialIndex);
      });
    }
    _pageController.addListener(_pageListener);
    super.initState();
  }

  void _pageListener() {
    setState(() => centerIndex = _pageController.page!);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(builder: (context, constraints) {
      assert(constraints.minWidth.isFinite);
      maxWidth = constraints.minWidth;
      return GestureDetector(
        onTapDown: (details) => _tapOffset = details.localPosition,
        onTapCancel: () => _tapOffset = null,
        onTap: () {
          if (_tapOffset == null) return;
          final dx = _tapOffset!.dx;
          _tapOffset = null;
          if (dx < widget.padding.left || dx > maxWidth - widget.padding.left) {
            return;
          }
          final basePosition =
              (maxWidth - getCardWidth(centerIndex.round())) / 2;
          final cardWidth = getCardWidth(centerIndex.round());
          if (dx >= basePosition && dx <= basePosition + cardWidth) {
            widget.onTap?.call(
              _pageController.page!.round() % widget.items.length,
            );
            return;
          }
          int newPage = centerIndex.round();
          if (dx < basePosition) {
            if (centerIndex <= 0) return;
            final double spaceOnLeft =
                (maxWidth - cardWidth) / 2 - widget.padding.left;
            newPage =
                newPage - ((dx > basePosition - (spaceOnLeft / 2)) ? 1 : 2);
            if (newPage < 0) return;
          } else {
            if (centerIndex.round() >= indexesList.length - 1) return;
            final double spaceOnRight =
                (maxWidth - cardWidth) / 2 - widget.padding.right;
            newPage = newPage +
                ((dx <= basePosition + cardWidth + (spaceOnRight / 2)) ? 1 : 2);
            if (newPage > indexesList.length - 1) return;
          }

          _pageController.animateToPage(
            newPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastLinearToSlowEaseIn,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Container(
                alignment: Alignment.center,
                width: maxWidth,
                child: Indexer(
                  alignment: Alignment.center,
                  children: getStackChildren(),
                ),
              ),
            ),
            Positioned.fill(
              child: PageView.builder(
                itemCount: indexesList.length,
                itemBuilder: (_, i) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    color: Colors.transparent,
                  );
                },
                controller: _pageController,
                onPageChanged: widget.onPageChanged,
                dragStartBehavior: DragStartBehavior.down,
                physics: const _CustomPageViewScrollPhysics(),
              ),
            ),
          ],
        ),
      );
    });
  }

  List<Widget> getStackChildren() {
    List<Widget> list = [];
    for (int i = 0; i < indexesList.length; i++) {
      double distance = i - centerIndex.roundToDouble();
      if (distance.abs() < 3) {
        list.add(Indexed(
          index: getZIndex(i),
          child: getStackChild(i),
        ));
      }
    }
    return list;
  }

  int getZIndex(int itemIndex) {
    int difference = itemIndex - centerIndex.round();
    // center item
    if (difference.round() == 0) return 5;
    // far left item
    if (difference < -1 && difference >= -2) return 1;
    // near left item
    if (difference < 0 && difference >= -1) return 2;
    // near right item
    if (difference > 0 && difference <= 1) return 4;
    // far right item
    if (difference > 1 && difference <= 2) return 3;
    return -1;
  }

  double getLeftPosition(int itemIndex) {
    final double cardWidth = getCardWidth(itemIndex);
    final double basePosition = (maxWidth - cardWidth) / 2;
    final double spaceOnLeft = (maxWidth - cardWidth) / 2 - widget.padding.left;
    final double spaceOnRight =
        (maxWidth - cardWidth) / 2 - widget.padding.right;
    final double distance = (centerIndex) - itemIndex;
    if (distance == 0) {
      return basePosition;
    } else if (distance > 0) {
      return basePosition - (spaceOnLeft / 2) * (min(2, distance.abs()));
    } else {
      return basePosition + (spaceOnRight / 2) * (min(2, distance.abs()));
    }
  }

  double getCardWidth(int itemIndex) {
    return (maxWidth - widget.padding.horizontal) * .65;
  }

  Matrix4 getTransform(int itemIndex) {
    final double realDistance = centerIndex - itemIndex;
    double rotation = getYRotation(realDistance).toDouble();
    final scaleValue = Tween<double>(begin: 1, end: 0.85).transform(
      min(realDistance.abs() * 2, 1),
    );
    Matrix4 matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.007)
      ..rotateY(rotation)
      ..scale(scaleValue, scaleValue, scaleValue);
    return matrix;
  }

  num getYRotation(num distance) {
    final direction = distance >= 0 ? 1 : -1;
    return -0.4 * (min(1, distance.abs()) * direction.toDouble());
  }

  num getYOffset(num distance) {
    // return distance.abs() * -45;
    return 0;
  }

  num getXOffset(num distance) {
    double maxOffset =
        (maxWidth - getCardWidth(0) - widget.padding.horizontal) / 4 +
            (distance.abs() > 1 ? 0 : widget.pageOverlappingOffset);
    final direction = (distance.isNegative ? -1 : 1);

    if (distance.abs() <= .5) {
      return maxOffset * (distance.abs()) * direction * 2;
    } else if (distance.abs() <= 1) {
      return maxOffset * (1 - distance.abs()) * direction * 2;
    } else if (distance.abs() <= 1.5) {
      return maxOffset * (distance.abs() - 1) * direction;
    } else if (distance.abs() <= 2) {
      return maxOffset * (2 - distance.abs()) * direction;
    }
    return 0;
  }

  double getMovingCardWidth(int itemIndex) {
    final distance = itemIndex - centerIndex;
    final generalCardWidth = getCardWidth(itemIndex);
    final extraWidth = getCardWidth(itemIndex) - (maxWidth * .5);
    if (distance.abs() <= .5) {
      return generalCardWidth - (extraWidth * distance.abs());
    }
    if (distance.abs() <= 1) {
      return generalCardWidth - (extraWidth - (extraWidth * distance.abs()));
    }
    return generalCardWidth;
  }

  Widget getStackChild(int itemIndex) {
    final distance = itemIndex - centerIndex;
    return Positioned(
      top: 0,
      bottom: 0,
      left: getLeftPosition(itemIndex),
      child: Transform.translate(
        offset: Offset(
          getXOffset(distance).toDouble(),
          getYOffset(distance).toDouble(),
        ),
        child: Transform(
          transform: getTransform(itemIndex),
          alignment: Alignment(
            min(distance.abs(), 1) * (distance >= 0 ? 1 : -1),
            0,
          ),
          child: Container(
            width: getCardWidth(itemIndex),
            alignment:
                distance <= 0 ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              foregroundDecoration: BoxDecoration(
                  color: Colors.white.withOpacity(getOpacity(itemIndex))),
              width: getMovingCardWidth(itemIndex),
              child: widget.items[itemIndex % widget.items.length],
            ),
          ),
        ),
      ),
    );
  }

  double getOpacity(int itemIndex) {
    final distance = itemIndex - centerIndex;
    const layer2Opacity = .64;
    const layer3Opacity = .32;
    if (distance.abs() <= 1) {
      return 1 - lerpDouble(1, layer2Opacity, distance.abs())!;
    }
    // return .1;
    if (distance.abs() <= 2) {
      return 1 - lerpDouble(layer2Opacity, layer3Opacity, distance.abs() - 1)!;
    }
    return 1 - layer3Opacity;
  }

  @override
  void dispose() {
    _pageController.removeListener(_pageListener);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}

class _CustomPageViewScrollPhysics extends PageScrollPhysics {
  const _CustomPageViewScrollPhysics({ScrollPhysics? parent})
      : super(parent: parent);

  @override
  _CustomPageViewScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _CustomPageViewScrollPhysics(parent: buildParent(ancestor)!);
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 50,
        stiffness: 100,
        damping: 1,
      );
}
