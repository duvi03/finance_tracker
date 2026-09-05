import 'package:flutter/material.dart';

/// Clean, unified responsive utility for Artha Finance Tracker.
/// Breakpoints:
/// - Mobile Small: < 360px (e.g. iPhone SE 1st gen, older/compact Android)
/// - Mobile Narrow: < 425px (Mobile S & M)
/// - Mobile Standard: 360px - 599px (e.g. standard iPhones, Samsung Galaxy, Pixel)
/// - Tablet: 600px - 899px (iPad Mini, Android Tablets)
/// - Desktop / Web: >= 900px
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  /// True if device width is less than 360px (e.g. 320px screens)
  bool get isMobileSmall => screenWidth < 360;

  /// True if device width is less than 425px (Mobile S & M)
  bool get isMobileNarrow => screenWidth < 425;

  /// True if device width is less than 600px
  bool get isMobile => screenWidth < 600;

  /// True if device is tablet (600px <= width < 900px)
  bool get isTablet => screenWidth >= 600 && screenWidth < 900;

  /// True if device is desktop or wide web (>= 900px)
  bool get isDesktop => screenWidth >= 900;

  /// Returns a responsive value depending on the current viewport width
  T responsiveValue<T>({
    required T mobile,
    T? mobileSmall,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    if (isMobileSmall && mobileSmall != null) return mobileSmall;
    return mobile;
  }

  /// Responsive horizontal page padding
  EdgeInsets get pagePadding {
    if (isMobileSmall) return const EdgeInsets.symmetric(horizontal: 10, vertical: 8);
    if (isMobileNarrow) return const EdgeInsets.symmetric(horizontal: 12, vertical: 10);
    if (isMobile) return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    if (isTablet) return const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
  }

  /// Responsive card internal padding
  EdgeInsets get cardPadding {
    if (isMobileSmall) return const EdgeInsets.all(10);
    if (isMobileNarrow) return const EdgeInsets.all(12);
    return const EdgeInsets.all(16);
  }
}
