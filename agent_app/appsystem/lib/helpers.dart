import 'package:flutter/material.dart';

// consts
const kSmDown = 500.0;
const kMdDown = 960.0;
const kLgDown = 1280.0;
const kXlDown = 1920.0;
const kXxlDown = double.infinity;
// uo
const kSmUp = 0.0;
const kMdUp = 600.0;
const kLgUp = 960.0;
const kXlUp = 1280.0;
const kXxlUp = 1920.0;

/// Checks if the screen width is small (less than 600px).
bool isSm(double width) => width < kSmDown;

/// Checks if the screen width is medium (less than 960px and greater than or equal to 600px).
/// If [orLess] is true, it checks if the width is less than 960px.
bool isMd(double width, {bool orLess = true}) {
  return orLess ? width < kMdDown : width >= kMdUp && width < kMdDown;
}

/// Checks if the screen width is large (less than 1280px and greater than or equal to 960px).
/// If [orLess] is true, it checks if the width is less than 1280px.
bool isLg(double width, {bool orLess = true}) {
  return orLess ? width < kLgDown : width >= kLgUp && width < kLgDown;
}

/// Checks if the screen width is extra large (less than 1920px and greater than or equal to 1280px).
/// If [orLess] is true, it checks if the width is less than 1920px.
bool isXl(double width, {bool orLess = true}) {
  return orLess ? width < kXlDown : width >= kXlUp && width < kXlDown;
}

/// Checks if the screen width is extra extra large (less than 2560px and greater than or equal to 1920px).
bool isXxl(double width) => width >= kXxlUp;

/// Returns a value based on the screen size.
///
/// [sm], [md], [lg], [xl], and [xxl] represent the values to return for different screen sizes.
/// If [orLess] is true, it checks if the width is less than the respective screen size.
///
/// At least one value must be provided.
T? forScreen<T>({
  required double width,
  T? sm,
  T? md,
  T? lg,
  T? xl,
  T? xxl,
  bool orLess = true,
}) {
  assert(
    sm != null || md != null || lg != null || xl != null,
    'At least one value must be provided',
  );
  // return the value in current screen size, if value is missing, return the value of the closest screen size
  if (isSm(width)) return sm ?? md ?? lg ?? xl ?? xxl;
  if (isMd(width, orLess: orLess)) return md ?? lg ?? xl ?? xxl ?? sm;
  if (isLg(width, orLess: orLess)) return lg ?? xl ?? xxl ?? md ?? sm;
  if (isXl(width, orLess: orLess)) return xl ?? xxl ?? lg ?? md ?? sm;
  if (isXxl(width)) return xxl ?? xl ?? lg ?? md ?? sm;
  return sm;
}

// Future<List<T>> loadRecords<T extends BaseRecord>(
//   String collectionName,
//   T Function(RecordModel) fromRecordModel, {
//   String? expand,
//   String? filter,
//   String? sort,
// }) async {
//   return (await pb.collection(collectionName).getFullList(
//             expand: expand,
//             filter: filter,
//             sort: sort,
//           ))
//       .map((e) {
//     return fromRecordModel(e);
//   }).toList();
// }

enum ForScreenWidthOf { mediaQuery, layoutBuilder }

class ForScreen extends StatelessWidget {
  final Widget? sm;
  final Widget? md;
  final Widget? lg;
  final Widget? xl;
  final Widget? xxl;
  final bool orLess;
  final ForScreenWidthOf widthOf;
  const ForScreen({
    super.key,
    this.sm,
    this.md,
    this.lg,
    this.xl,
    this.xxl,
    this.orLess = true,
    this.widthOf = ForScreenWidthOf.layoutBuilder,
  }) : assert(
         sm != null || md != null || lg != null || xl != null,
         'At least one value must be provided',
       );

  @override
  Widget build(BuildContext context) {
    if (widthOf == ForScreenWidthOf.mediaQuery) {
      return forScreen<Widget>(
        width: MediaQuery.sizeOf(context).width,
        sm: sm,
        md: md,
        lg: lg,
        xl: xl,
        xxl: xxl,
      )!;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return forScreen<Widget>(
          width: constraints.maxWidth,
          sm: sm,
          md: md,
          lg: lg,
          xl: xl,
          xxl: xxl,
        )!;
      },
    );
  }
}

/// Shows a SnackBar with the provided [content] and [actionLabel].
///
/// The [actionLabel] is optional. If provided, it will show a button with the label that hides the SnackBar when pressed.
/// The [width] is also optional and defaults to 400.0.
void showSnackBar(
  BuildContext context,
  Widget content, {
  String? actionLabel,
  double width = 400.0,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      width: width,
      content: content,
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            )
          : null,
    ),
  );
}

// ImageProvider? pbImageProvider(
//     {String? name, required RecordModel record, Size? thumb}) {
//   if (name == null) return null;
//   var baseUrl = pb.baseUrl;
//   var collectionName = record.collectionName;
//   var id = record.id;
//   var thumbStr = thumb != null ? "?thumb=${thumb.width}x${thumb.height}" : "";
//   return NetworkImage("$baseUrl/api/files/$collectionName/$id/$name$thumbStr");
// }

// // extension to [RecordModel] to get file Url
// extension RecordModelFileUrl on BaseRecord {
//   /// Returns the file URL of the record.
//   String? fileUrl(String? name, {Size? thumb}) {
//     if (name == null) return null;
//     var baseUrl = pb.baseUrl;
//     var collectionName = this.collectionName;
//     var id = this.id;
//     var thumbStr = thumb != null ? "?thumb=${thumb.width}x${thumb.height}" : "";
//     return "$baseUrl/api/files/$collectionName/$id/$name$thumbStr";
//   }
// }

extension SnackbarContextX on BuildContext {
  /// Shows a SnackBar with the provided [content] and [actionLabel].
  ///
  /// The [actionLabel] is optional. If provided, it will show a button with the label that hides the SnackBar when pressed.
  /// The [width] is also optional and defaults to 400.0.
  void showSnackBar(
    Widget content, {
    SnackBarAction? action,
    double? width,
    duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(this).clearSnackBars();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        width: width,
        content: content,
        action: action,
        // margin: EdgeInsets.all(20),
        duration: duration,
      ),
    );
  }

  // error snack bar
  void showErrorSnackBar(
    Widget content, {
    SnackBarAction? action,
    double? width,
    Duration duration = const Duration(seconds: 3),
  }) {
    showSnackBar(
      Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 16),
          Expanded(
            child: DefaultTextStyle(
              style: Theme.of(
                this,
              ).textTheme.labelMedium!.copyWith(color: Colors.red),
              child: content,
            ),
          ),
        ],
      ),
      action: action,
      width: width,
      duration: duration,
    );
  }

  // success snack bar
  void showSuccessSnackBar(
    Widget content, {
    SnackBarAction? action,
    double? width,
    Duration duration = const Duration(seconds: 3),
  }) {
    showSnackBar(
      Row(
        children: [
          const Icon(Icons.check, color: Colors.green),
          const SizedBox(width: 16),
          Expanded(
            child: DefaultTextStyle(
              style: Theme.of(
                this,
              ).textTheme.labelMedium!.copyWith(color: Colors.green),
              child: content,
            ),
          ),
        ],
      ),
      action: action,
      width: width,
      duration: duration,
    );
  }

  // info snack bar
  void showInfoSnackBar(
    Widget content, {
    SnackBarAction? action,
    double? width,
    Duration duration = const Duration(seconds: 3),
  }) {
    showSnackBar(
      Row(
        children: [
          const Icon(Icons.info, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: DefaultTextStyle(
              style: Theme.of(
                this,
              ).textTheme.labelMedium!.copyWith(color: Colors.blue),
              child: content,
            ),
          ),
        ],
      ),
      action: action,
      width: width,
      duration: duration,
    );
  }

  // warning snack bar
  void showWarningSnackBar(
    Widget content, {
    SnackBarAction? action,
    double? width,
    Duration duration = const Duration(seconds: 3),
  }) {
    showSnackBar(
      Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange),
          const SizedBox(width: 16),
          Expanded(
            child: DefaultTextStyle(
              style: Theme.of(
                this,
              ).textTheme.labelMedium!.copyWith(color: Colors.orange),
              child: content,
            ),
          ),
        ],
      ),
      action: action,
      width: width,
      duration: duration,
    );
  }

  // loading snack bar
  void showLoadingSnackBar(
    Widget content, {
    SnackBarAction? action,
    double? width,
    Duration duration = const Duration(seconds: 3),
  }) {
    showSnackBar(
      Row(
        children: [
          const SizedBox.square(
            dimension: 25,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 16),
          content,
        ],
      ),
      action: action,
      width: width,
      duration: duration,
    );
  }

  // dailogs

  // void showPreviewDialog({
  //   String? url,
  //   Widget? icon,
  //   Widget? title,
  //   Widget? content,
  //   List<Widget>? actions,
  //   Color? backgroundColor,
  //   Color? textColor,
  //   EdgeInsetsGeometry padding = const EdgeInsets.all(9),
  //   CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  // }) {
  //   showDialog(
  //     context: this,
  //     useRootNavigator: false,
  //     builder: (context) {
  //       // return Dialog(elevation: 0, backgroundColor: Colors.transparent, child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 300), child: AlertCard.error(title: Text("regerger"))));
  //       return Dialog(
  //         backgroundColor: backgroundColor,
  //         // title: title,
  //         // content: content,
  //         // actions: [
  //         //   ...?actions,
  //         // ],
  //         child: Padding(
  //           padding: padding,
  //           child: DefaultTextStyle(
  //             style: Theme.of(this)
  //                 .textTheme
  //                 .labelMedium!
  //                 .copyWith(color: textColor),
  //             child: SizedBox(
  //               width: 450,
  //               child: SingleChildScrollView(
  //                 child: Column(
  //                   mainAxisSize: MainAxisSize.min,
  //                   crossAxisAlignment: crossAxisAlignment,
  //                   children: [
  //                     if (icon != null) ...[
  //                       IconTheme(
  //                           data: IconThemeData(
  //                               color: textColor ??
  //                                   Theme.of(context).colorScheme.onBackground,
  //                               size: 40),
  //                           child: icon),
  //                       const SizedBox(height: 8),
  //                     ],
  //                     if (title != null)
  //                       DefaultTextStyle(
  //                         style: Theme.of(this)
  //                             .textTheme
  //                             .displayLarge!
  //                             .copyWith(color: textColor, fontSize: 22),
  //                         child: title,
  //                       ),
  //                     VideoPlayer(
  //                       videoUrl: url!,
  //                     ),
  //                     if (content != null) content,
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
}

  // void showIconDialog({
  //   Widget? icon,
  //   Widget? title,
  //   Widget? content,
  //   List<Widget>? actions,
  //   Color? backgroundColor,
  //   Color? textColor,
  //   EdgeInsetsGeometry padding = const EdgeInsets.all(24),
  //   CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  // }) {
  //   showDialog(
  //     context: this,
  //     useRootNavigator: false,
  //     builder: (context) {
  //       // return Dialog(elevation: 0, backgroundColor: Colors.transparent, child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 300), child: AlertCard.error(title: Text("regerger"))));
  //       return Dialog(
  //         backgroundColor: backgroundColor,
  //         // title: title,
  //         // content: content,
  //         // actions: [
  //         //   ...?actions,
  //         // ],
  //         child: Padding(
  //           padding: padding,
  //           child: DefaultTextStyle(
  //             style: Theme.of(this)
  //                 .textTheme
  //                 .labelMedium!
  //                 .copyWith(color: textColor),
  //             child: IntrinsicWidth(
  //               child: Column(
  //                 mainAxisSize: MainAxisSize.min,
  //                 crossAxisAlignment: crossAxisAlignment,
  //                 children: [
  //                   if (icon != null) ...[
  //                     IconTheme(
  //                         data: IconThemeData(
  //                             color: textColor ??
  //                                 Theme.of(context).colorScheme.onBackground,
  //                             size: 40),
  //                         child: icon),
  //                     const SizedBox(height: 8),
  //                   ],
  //                   if (title != null)
  //                     DefaultTextStyle(
  //                       style: Theme.of(this)
  //                           .textTheme
  //                           .displayLarge!
  //                           .copyWith(color: textColor, fontSize: 22),
  //                       child: title,
  //                     ),
  //                   if (content != null) content,
  //                   if (actions != null) ...[
  //                     const SizedBox(height: 24),
  //                     OverflowBar(
  //                       alignment: MainAxisAlignment.end,
  //                       overflowAlignment: OverflowBarAlignment.end,
  //                       overflowDirection: VerticalDirection.down,
  //                       overflowSpacing: 0,
  //                       children: [
  //                         ...actions,
  //                       ],
  //                     )
  //                   ]
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  // void showErrorAlertDialog({
  //   required Widget content,
  //   List<Widget>? actions,
  // }) {
  //   showIconDialog(
  //     title: Row(
  //       children: [
  //         const Icon(Icons.error, color: Colors.red),
  //         const SizedBox(width: 16),
  //         Text('Error',
  //             style: Theme.of(this)
  //                 .textTheme
  //                 .headlineMedium!
  //                 .copyWith(color: Colors.red)),
  //       ],
  //     ),
  //     content: content,
  //     actions: actions,
  //   );
  // }

  // /// showConfirmDialog
  // void showConfirmDialog({
  //   required Widget content,
  //   required VoidCallback onConfirm,
  //   VoidCallback? onCancel,
  //   Widget? label,
  // }) {
  //   showIconDialog(
  //     title: Row(
  //       children: [
  //         const Icon(Icons.warning, color: Colors.orange),
  //         const SizedBox(width: 16),
  //         Text(t.general.confirm,
  //             style: Theme.of(this)
  //                 .textTheme
  //                 .headlineMedium!
  //                 .copyWith(color: Colors.orange)),
  //       ],
  //     ),
  //     content: content,
  //     actions: [
  //       TextButton(
  //         onPressed: () {
  //           Navigator.of(this).pop();
  //           if (onCancel != null) onCancel();
  //         },
  //         child: Text(t.general.cancel),
  //       ),
  //       FilledButton(
  //         onPressed: () {
  //           Navigator.of(this).pop();
  //           onConfirm();
  //         },
  //         child: label ?? Text(t.general.confirm),
  //       ),
  //     ],
  //   );
  // }

  // void showConfirmPurchaseDialog(
  //     {required UnitsRecord unit,
  //     required String title,
  //     required String price,
  //     VoidCallback? onConfirm,
  //     required String imageUrl}) {
  //   showDialog(
  //       context: this,
  //       useRootNavigator: false,
  //       builder: (context) {
  //         return ListenableBuilder(
  //             listenable: UnitsController.instance,
  //             builder: (context, _) {
  //               return Stack(
  //                 children: [
  //                   Column(
  //                     crossAxisAlignment: CrossAxisAlignment.center,
  //                     mainAxisAlignment: MainAxisAlignment.center,
  //                     children: [
  //                       Container(
  //                         constraints: const BoxConstraints(maxWidth: 400),
  //                         decoration: BoxDecoration(
  //                           borderRadius: BorderRadius.circular(10),
  //                           color: Theme.of(this).colorScheme.surface,
  //                         ),
  //                         child: Column(
  //                           children: [
  //                             Stack(
  //                               children: [
  //                                 Container(
  //                                   margin: const EdgeInsets.only(
  //                                       bottom: 3,
  //                                       top: 10,
  //                                       left: 10,
  //                                       right: 10),
  //                                   height: 120,
  //                                   decoration: BoxDecoration(
  //                                       color: Theme.of(context)
  //                                           .colorScheme
  //                                           .surface,
  //                                       borderRadius: const BorderRadius.only(
  //                                           topLeft: Radius.circular(10),
  //                                           topRight: Radius.circular(10),
  //                                           bottomLeft: Radius.circular(10),
  //                                           bottomRight: Radius.circular(10)),
  //                                       image: DecorationImage(
  //                                         image: NetworkImage(
  //                                           unit.fileUrl(unit.image,
  //                                               thumb: Size(400, 400))!,
  //                                         ),
  //                                         fit: BoxFit.cover,
  //                                       )),
  //                                 ),
  //                                 Positioned.fill(
  //                                   child: Container(
  //                                     margin: const EdgeInsets.only(
  //                                         bottom: 3,
  //                                         top: 10,
  //                                         left: 10,
  //                                         right: 10),
  //                                     decoration: BoxDecoration(
  //                                       borderRadius: const BorderRadius.only(
  //                                           topLeft: Radius.circular(10),
  //                                           topRight: Radius.circular(10),
  //                                           bottomLeft: Radius.circular(10),
  //                                           bottomRight: Radius.circular(10)),
  //                                       gradient: LinearGradient(
  //                                         begin: Alignment.topCenter,
  //                                         end: Alignment.bottomCenter,
  //                                         colors: [
  //                                           Colors.black.withOpacity(0.5),
  //                                           Colors.transparent,
  //                                           Colors.transparent,
  //                                           Colors.black.withOpacity(0.5),
  //                                         ],
  //                                       ),
  //                                     ),
  //                                   ),
  //                                 ),
  //                               ],
  //                             ),

  //                             ListTile(
  //                               leading: const Icon(Iconsax.book),
  //                               // contentPadding: const EdgeInsets.only(left: 0),
  //                               title: Padding(
  //                                 padding: const EdgeInsets.only(
  //                                   top: 3,
  //                                 ),
  //                                 child: Row(
  //                                   children: [
  //                                     Text(unit.name ?? "",
  //                                         style: Theme.of(this)
  //                                             .textTheme
  //                                             .titleLarge!
  //                                             .copyWith()),
  //                                     Spacer(),
  //                                     Badge(
  //                                       label: Padding(
  //                                         padding: const EdgeInsets.all(1.0),
  //                                         child: Text(
  //                                           ((unit.discount! * 100) /
  //                                                       unit.price!)
  //                                                   .toInt()
  //                                                   .toString() +
  //                                               "%",
  //                                           style: Theme.of(this)
  //                                               .textTheme
  //                                               .labelMedium
  //                                               ?.copyWith(color: Colors.white),
  //                                         ),
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ),
  //                               subtitle: Text(
  //                                 unit.price.toString() + "Da",
  //                                 style: Theme.of(this)
  //                                     .textTheme
  //                                     .titleLarge!
  //                                     .copyWith(
  //                                         color: Theme.of(this)
  //                                             .colorScheme
  //                                             .secondary),
  //                               ),
  //                             )
  //                             // ListTile(
  //                             //   contentPadding: const EdgeInsets.only(left: 0),
  //                             //   leading:
  //                             //   title: Padding(
  //                             //     padding: const EdgeInsets.only(top: 3),
  //                             //     child: Text(unit.name ?? "",
  //                             //         style: Theme.of(this)
  //                             //             .textTheme
  //                             //             .titleLarge!
  //                             //             .copyWith()),
  //                             //   ),
  //                             //   subtitle: const Row(
  //                             //     children: [
  //                             //       Text("4.5", style: TextStyle()),
  //                             //       Icon(
  //                             //         Icons.star,
  //                             //         color: Colors.amber,
  //                             //         size: 14,
  //                             //       ),
  //                             //     ],
  //                             //   ),
  //                             // ),
  //                           ],
  //                         ),
  //                       ),
  //                       Dialog(
  //                         // content: content,
  //                         // actions: [
  //                         //   ...?actions,
  //                         // ],
  //                         child: Padding(
  //                           padding: EdgeInsets.all(10),
  //                           child: DefaultTextStyle(
  //                             style: Theme.of(this).textTheme.labelMedium!,
  //                             child: IntrinsicWidth(
  //                               child: Column(
  //                                   mainAxisSize: MainAxisSize.min,
  //                                   children: [
  //                                     ListTile(
  //                                       leading: const Icon(
  //                                         Iconsax.information,
  //                                         color: Colors.green,
  //                                       ),
  //                                       title: Text("Confirm Purchase",
  //                                           style: Theme.of(this)
  //                                               .textTheme
  //                                               .titleLarge!
  //                                               .copyWith()),
  //                                     ),

  //                                     ListTile(
  //                                       title: Text(
  //                                           "Are you sure you want to buy the course of ${title} "),
  //                                     ),
  //                                     //TODO TRANSLATE

  //                                     // if (actions != null) ...[
  //                                     const SizedBox(height: 24),
  //                                     OverflowBar(
  //                                       alignment: MainAxisAlignment.end,
  //                                       overflowAlignment:
  //                                           OverflowBarAlignment.end,
  //                                       overflowDirection:
  //                                           VerticalDirection.down,
  //                                       overflowSpacing: 0,
  //                                       children: [
  //                                         TextButton(
  //                                           onPressed: () {
  //                                             Navigator.of(this).pop();
  //                                           },
  //                                           child: Text(t.general.cancel),
  //                                         ),
  //                                         FilledButton(
  //                                           onPressed: onConfirm,
  //                                           child: Text(
  //                                             "Buy with  ${unit.price} Da",
  //                                           ),
  //                                         ),
  //                                       ],
  //                                     )
  //                                   ]
  //                                   // ],
  //                                   ),
  //                             ),
  //                           ),
  //                         ),
  //                       )
  //                     ],
  //                   ),
  //                   UnitsController.instance.buying == true
  //                       ? Positioned.fill(
  //                           child: Container(
  //                             color: Colors.black.withOpacity(0.5),
  //                             child: Center(
  //                               child: CircularProgressIndicator(),
  //                             ),
  //                           ),
  //                         )
  //                       : Container(),
  //                 ],
  //               );
  //             });
  //       });
  // }

//   void showCustomDialog({
//     required Widget content,
//     required VoidCallback onConfirm,
//     VoidCallback? onCancel,
//     String? confirmText,
//     Widget? leadingTitleWidget,
//     String? label,
//   }) {
//     showIconDialog(
//       title: Row(
//         children: [
//           leadingTitleWidget != null
//               ? leadingTitleWidget
//               : const Icon(Icons.warning, color: Colors.orange),
//           const SizedBox(width: 16),
//           Text(label ?? "Confirm",
//               style: Theme.of(this).textTheme.headlineSmall!.copyWith()),
//         ],
//       ),
//       content: Padding(
//         padding: const EdgeInsets.only(top: 16),
//         child: Column(
//           children: [
//             content,
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () {
//             Navigator.of(this).pop();
//             if (onCancel != null) onCancel();
//           },
//           child: Text(t.general.cancel),
//         ),
//         FilledButton(
//           onPressed: () {
//             Navigator.of(this).pop();
//             onConfirm();
//           },
//           child: Text(confirmText ?? "تسجيل الدخول"),
//         ),
//       ],
//     );
//   }
// }

// pocketbase utils
// 1. generate file url
// String pbFileUrl(String collectionName, String id, String name, {Size? thumb}) {
//   var baseUrl = pb.baseUrl;
//   var thumbStr = thumb != null ? "?thumb=${thumb.width}x${thumb.height}" : "";
//   return "$baseUrl/api/files/$collectionName/$id/$name$thumbStr";
// }
