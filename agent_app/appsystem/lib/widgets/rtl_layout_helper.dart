import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

/// RTL Layout Helper for proper Right-to-Left support
/// 
/// Provides utilities and widgets for handling RTL layouts,
/// text alignment, and positioning throughout the app.
class RTLLayoutHelper {
  /// Get current text direction
  static TextDirection getTextDirection(BuildContext context) {
    return Provider.of<LanguageProvider>(context, listen: false).textDirection;
  }

  /// Check if current language is RTL
  static bool isRTL(BuildContext context) {
    return Provider.of<LanguageProvider>(context, listen: false).isRTL;
  }

  /// Get RTL-aware alignment
  static Alignment getAlignment(BuildContext context, {Alignment? defaultAlignment}) {
    final isRTL = RTLLayoutHelper.isRTL(context);
    if (defaultAlignment == null) {
      return isRTL ? Alignment.centerRight : Alignment.centerLeft;
    }
    
    // Handle common alignment cases
    if (defaultAlignment == Alignment.centerLeft) {
      return isRTL ? Alignment.centerRight : Alignment.centerLeft;
    }
    if (defaultAlignment == Alignment.centerRight) {
      return isRTL ? Alignment.centerLeft : Alignment.centerRight;
    }
    if (defaultAlignment == Alignment.topLeft) {
      return isRTL ? Alignment.topRight : Alignment.topLeft;
    }
    if (defaultAlignment == Alignment.topRight) {
      return isRTL ? Alignment.topLeft : Alignment.topRight;
    }
    if (defaultAlignment == Alignment.bottomLeft) {
      return isRTL ? Alignment.bottomRight : Alignment.bottomLeft;
    }
    if (defaultAlignment == Alignment.bottomRight) {
      return isRTL ? Alignment.bottomLeft : Alignment.bottomRight;
    }
    
    return defaultAlignment;
  }

  /// Get RTL-aware text alignment
  static TextAlign getTextAlign(BuildContext context, {TextAlign? defaultAlign}) {
    final isRTL = RTLLayoutHelper.isRTL(context);
    if (defaultAlign == null) {
      return isRTL ? TextAlign.right : TextAlign.left;
    }
    
    if (defaultAlign == TextAlign.left) {
      return isRTL ? TextAlign.right : TextAlign.left;
    }
    if (defaultAlign == TextAlign.right) {
      return isRTL ? TextAlign.left : TextAlign.right;
    }
    
    return defaultAlign;
  }

  /// Get RTL-aware start alignment
  static Alignment getStartAlignment(BuildContext context) {
    return RTLLayoutHelper.isRTL(context) ? Alignment.centerRight : Alignment.centerLeft;
  }

  /// Get RTL-aware end alignment
  static Alignment getEndAlignment(BuildContext context) {
    return RTLLayoutHelper.isRTL(context) ? Alignment.centerLeft : Alignment.centerRight;
  }

  /// Get RTL-aware start text alignment
  static TextAlign getStartTextAlign(BuildContext context) {
    return RTLLayoutHelper.isRTL(context) ? TextAlign.right : TextAlign.left;
  }

  /// Get RTL-aware end text alignment
  static TextAlign getEndTextAlign(BuildContext context) {
    return RTLLayoutHelper.isRTL(context) ? TextAlign.left : TextAlign.right;
  }

  /// Get RTL-aware padding
  static EdgeInsets getRTLPadding({
    double? start,
    double? end,
    double? top,
    double? bottom,
    double? horizontal,
    double? vertical,
    double? all,
  }) {
    if (all != null) {
      return EdgeInsets.all(all);
    }
    
    if (horizontal != null || vertical != null) {
      return EdgeInsets.symmetric(
        horizontal: horizontal ?? 0,
        vertical: vertical ?? 0,
      );
    }
    
    return EdgeInsets.only(
      left: start ?? 0,
      right: end ?? 0,
      top: top ?? 0,
      bottom: bottom ?? 0,
    );
  }

  /// Get RTL-aware margin
  static EdgeInsets getRTLMargin({
    double? start,
    double? end,
    double? top,
    double? bottom,
    double? horizontal,
    double? vertical,
    double? all,
  }) {
    return getRTLPadding(
      start: start,
      end: end,
      top: top,
      bottom: bottom,
      horizontal: horizontal,
      vertical: vertical,
      all: all,
    );
  }

  /// Get RTL-aware border radius
  static BorderRadius getRTLBorderRadius({
    double? topStart,
    double? topEnd,
    double? bottomStart,
    double? bottomEnd,
    double? all,
  }) {
    if (all != null) {
      return BorderRadius.circular(all);
    }
    
    return BorderRadius.only(
      topLeft: Radius.circular(topStart ?? 0),
      topRight: Radius.circular(topEnd ?? 0),
      bottomLeft: Radius.circular(bottomStart ?? 0),
      bottomRight: Radius.circular(bottomEnd ?? 0),
    );
  }
}

/// RTL-aware container widget
class RTLContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Decoration? decoration;
  final Alignment? alignment;
  final double? width;
  final double? height;
  final Clip? clipBehavior;

  const RTLContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.decoration,
    this.alignment,
    this.width,
    this.height,
    this.clipBehavior,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      margin: margin,
      decoration: decoration,
      alignment: alignment != null 
          ? RTLLayoutHelper.getAlignment(context, defaultAlignment: alignment)
          : null,
      width: width,
      height: height,
      clipBehavior: clipBehavior ?? Clip.none,
      child: child,
    );
  }
}

/// RTL-aware text widget
class RTLText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  const RTLText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      textAlign: RTLLayoutHelper.getTextAlign(context, defaultAlign: textAlign),
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}

/// RTL-aware row widget
class RTLRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment? mainAxisAlignment;
  final CrossAxisAlignment? crossAxisAlignment;
  final MainAxisSize? mainAxisSize;

  const RTLRow({
    super.key,
    required this.children,
    this.mainAxisAlignment,
    this.crossAxisAlignment,
    this.mainAxisSize,
  });

  @override
  Widget build(BuildContext context) {
    final isRTL = RTLLayoutHelper.isRTL(context);
    final rtlChildren = isRTL ? children.reversed.toList() : children;
    
    return Row(
      children: rtlChildren,
      mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
      crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
      mainAxisSize: mainAxisSize ?? MainAxisSize.max,
    );
  }
}

/// RTL-aware column widget
class RTLColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment? mainAxisAlignment;
  final CrossAxisAlignment? crossAxisAlignment;
  final MainAxisSize? mainAxisSize;

  const RTLColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment,
    this.crossAxisAlignment,
    this.mainAxisSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: children,
      mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
      crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
      mainAxisSize: mainAxisSize ?? MainAxisSize.max,
    );
  }
}

/// RTL-aware positioned widget
class RTLPositioned extends StatelessWidget {
  final Widget child;
  final double? start;
  final double? end;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double? width;
  final double? height;

  const RTLPositioned({
    super.key,
    required this.child,
    this.start,
    this.end,
    this.top,
    this.bottom,
    this.left,
    this.right,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isRTL = RTLLayoutHelper.isRTL(context);
    
    return Positioned(
      left: isRTL ? end : (left ?? start),
      right: isRTL ? (left ?? start) : end,
      top: top,
      bottom: bottom,
      width: width,
      height: height,
      child: child,
    );
  }
}

/// RTL-aware alignment widget
class RTLAlign extends StatelessWidget {
  final Widget child;
  final Alignment? alignment;
  final double? widthFactor;
  final double? heightFactor;

  const RTLAlign({
    super.key,
    required this.child,
    this.alignment,
    this.widthFactor,
    this.heightFactor,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: RTLLayoutHelper.getAlignment(context, defaultAlignment: alignment),
      widthFactor: widthFactor,
      heightFactor: heightFactor,
      child: child,
    );
  }
} 