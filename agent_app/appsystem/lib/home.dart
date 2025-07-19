import 'package:appsystem/helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

class DashboardView extends StatefulWidget {
  final Widget? content;
  const DashboardView({super.key, this.content});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  var scaffold = GlobalKey<ScaffoldState>();

  bool forceSmall = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: Colors.transparent,
      key: scaffold,

      // drawer: Drawer(
      //   child: Padding(
      //     padding: const EdgeInsets.all(8.0),
      //     child: NavigationSidebar(
      //       mode: NavigationSidebarItemMode.full,
      //       onToggle: (value) {
      //         setState(() {
      //           forceSmall = value;
      //         });
      //       },
      //       onItemPressed: () => scaffold.currentState?.closeDrawer(),
      //     ),
      //   ),
      // ),
      body: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(color: Theme.of(context).colorScheme.surface),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 300,
              child: Image.asset(
                'assets/images/gard.jpeg',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),

          Positioned(
            child: SizedBox(
              height: 300,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.surface.withAlpha(100),
                      Theme.of(context).colorScheme.surface,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                // if (width >= kMdUp)
                AnimatedContainer(
                  // color: Theme.of(context).primaryColor,
                  duration: const Duration(milliseconds: 150),
                  // start quik and slow
                  curve: Curves.easeInOut,
                  width: forceSmall
                      ? kMinInteractiveDimension + 16
                      : forScreen(
                          width: width,
                          sm: kMinInteractiveDimension + 16,
                          md: kMinInteractiveDimension + 35,
                          lg: 200,
                        )!,
                  padding: const EdgeInsets.all(8),
                  child: NavigationSidebar(
                    mode: forceSmall
                        ? NavigationSidebarItemMode.square
                        : forScreen(
                            width: width,
                            sm: NavigationSidebarItemMode.square,
                            md: NavigationSidebarItemMode.squareWithTitle,
                            lg: NavigationSidebarItemMode.full,
                          )!,
                    onToggle: (value) {
                      setState(() {
                        forceSmall = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      AppBar(
                        leading: DrawerButton(),
                        surfaceTintColor: Colors.transparent,
                        backgroundColor: Colors.transparent,
                        title: Row(
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: const []),
                                  Text(
                                    "و  كيل عقارات محترف",
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            // if (kDebugMode)
                            //   Center(
                            //     child: Text(
                            //       GoRouterState.of(context).uri.toFilePath(),
                            //       style: const TextStyle(color: Colors.white),
                            //     ),
                            //   ),
                            IconButton(
                              icon: const Icon(
                                Icons.brightness_6,
                                color: Colors.white,
                              ),
                              onPressed: () {},
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.language,
                                color: Colors.white,
                              ),
                              onSelected: (String languageCode) {},
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(
                                      value: 'en',
                                      child: Text('English'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'ar',
                                      child: Text('العربية'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'fr',
                                      child: Text('Français'),
                                    ),
                                  ],
                            ),
                          ],
                        ),
                        automaticallyImplyLeading: false,
                        actions: const [AppBarActions(), SizedBox(width: 8)],
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadiusDirectional.only(
                              topStart: Radius.circular(17),
                            ),
                          ),
                          padding: const EdgeInsetsDirectional.only(
                            start: 1,
                            top: 1,
                          ),
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              // color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadiusDirectional.only(
                                topStart: Radius.circular(16),
                              ),
                            ),
                            child: widget.content ?? Column(children: []),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum NavigationSidebarItemMode { full, square, squareWithTitle }

class NavigationSidebar extends StatelessWidget {
  final NavigationSidebarItemMode mode;
  final Axis direction;
  final void Function(bool)? onToggle;
  final void Function()? onItemPressed;
  const NavigationSidebar({
    super.key,
    this.mode = NavigationSidebarItemMode.full,
    this.direction = Axis.vertical,
    this.onToggle,
    this.onItemPressed,
  });

  @override
  Widget build(BuildContext context) {
    var route = GoRouterState.of(context);

    return Flex(
      key: ValueKey(direction),
      direction: direction,
      children: [
        // Brand logo/title
        if (forScreen(
              width: MediaQuery.sizeOf(context).width,
              sm: false,
              md: false,
              lg: true,
            ) ==
            true)
          NavigationSidebarItem(
            leading: Icon(Iconsax.home, color: Color(0xFF1877F2)),
            title: Text(
              mode == NavigationSidebarItemMode.full
                  ? "وكيل عقارات محترف"
                  : "وكيل",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: mode == NavigationSidebarItemMode.full
                ? Text(
                    "Professional Real Estate Agent",
                    style: TextStyle(
                      fontSize: 8,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : null,
            mode: mode,
            onTap: () {
              onToggle?.call(
                mode == NavigationSidebarItemMode.full ? true : false,
              );
            },
          ),

        // Home
        NavigationSidebarItem(
          leading: route.fullPath == "/dashboard/home"
              ? Icon(Icons.home)
              : Icon(Icons.home_outlined),
          title: Text("الرئيسية"),
          selected: route.fullPath?.startsWith("/dashboard/home"),
          mode: mode,
          onTap: () {
            context.go('/dashboard/home');
            onItemPressed?.call();
          },
        ),

        // Map
        NavigationSidebarItem(
          leading: route.fullPath == "/dashboard/map"
              ? Icon(Icons.map)
              : Icon(Icons.map_outlined),
          title: Text("الخريطة"),
          selected: route.fullPath?.startsWith("/dashboard/map"),
          mode: mode,
          onTap: () {
            context.go('/dashboard/map');
            onItemPressed?.call();
          },
        ),

        // Leads/Clients
        NavigationSidebarItem(
          leading: route.fullPath == "/dashboard/leads"
              ? Icon(Icons.people)
              : Icon(Icons.people_outlined),
          title: Text("العملاء"),
          selected: route.fullPath?.startsWith("/dashboard/leads"),
          mode: mode,
          onTap: () {
            context.go('/dashboard/leads');
            onItemPressed?.call();
          },
        ),

        // Properties
        NavigationSidebarItem(
          leading: route.fullPath == "/dashboard/properties"
              ? Icon(Icons.list_alt)
              : Icon(Icons.list_alt_outlined),
          title: Text("العقارات"),
          selected: route.fullPath?.startsWith("/dashboard/properties"),
          mode: mode,
          onTap: () {
            context.go('/dashboard/properties');
            onItemPressed?.call();
          },
        ),

        // Chatbot
        NavigationSidebarItem(
          leading: route.fullPath == "/dashboard/chatbot"
              ? Icon(Icons.smart_toy)
              : Icon(Icons.smart_toy_outlined),
          title: Text("المساعد الذكي"),
          selected: route.fullPath?.startsWith("/dashboard/chatbot"),
          mode: mode,
          onTap: () {
            context.go('/dashboard/chatbot');
            onItemPressed?.call();
          },
        ),

        Spacer(),

        // Settings
        NavigationSidebarItem(
          leading: route.fullPath == "/dashboard/settings"
              ? Icon(Icons.settings)
              : Icon(Icons.settings_outlined),
          title: Text("الإعدادات"),
          selected: route.fullPath?.startsWith("/dashboard/settings"),
          mode: mode,
          onTap: () {
            context.go('/dashboard/settings');
            onItemPressed?.call();
          },
        ),

        // Logout
        NavigationSidebarItem(
          leading: Icon(Icons.logout),
          title: Text("تسجيل الخروج"),
          mode: mode,
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('تأكيد تسجيل الخروج'),
                  content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('إلغاء'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go('/auth');
                      },
                      child: const Text('تسجيل الخروج'),
                    ),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 16), // Add some padding at the bottom
      ],
    );
  }
}

class NavigationSidebarItem extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final bool? selected;
  final NavigationSidebarItemMode mode;
  final VoidCallback? onTap;
  const NavigationSidebarItem({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.selected,
    this.mode = NavigationSidebarItemMode.full,
    this.onTap,
  });
  const NavigationSidebarItem.square({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.selected,
    this.onTap,
  }) : mode = NavigationSidebarItemMode.square;
  const NavigationSidebarItem.squareWithTitle({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.selected,
    this.onTap,
  }) : mode = NavigationSidebarItemMode.squareWithTitle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        alignment: AlignmentDirectional.centerStart,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          // gradient: selected != null && selected!
          //     ? LinearGradient(
          //         begin: AlignmentDirectional.centerStart,
          //         tileMode: TileMode.clamp,
          //         end: AlignmentDirectional.centerEnd,
          //         colors: [
          //           Theme.of(context).colorScheme.onPrimary.withOpacity(0.5),
          //           Theme.of(context).colorScheme.primary,
          //         ],
          //       )
          //     : null,
        ),
        padding: mode == NavigationSidebarItemMode.squareWithTitle
            ? const EdgeInsets.all(4.0)
            : const EdgeInsets.all(0),
        child: Stack(
          children: [
            if (selected != null)
              Positioned.fill(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 4,
                    height: selected! ? 40 : 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    // color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            Align(
              alignment: mode == NavigationSidebarItemMode.squareWithTitle
                  ? AlignmentDirectional.center
                  : AlignmentDirectional.centerStart,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[
                    Column(
                      children: [
                        SizedBox.square(
                          dimension:
                              mode == NavigationSidebarItemMode.squareWithTitle
                              ? kMinInteractiveDimension * 0.8
                              : kMinInteractiveDimension,
                          child: Center(child: leading),
                        ),
                        if (mode ==
                            NavigationSidebarItemMode.squareWithTitle) ...[
                          DefaultTextStyle(
                            style: Theme.of(context).textTheme.labelSmall!
                                .copyWith(
                                  fontSize: 10,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.labelSmall?.color,
                                ),
                            child: title,
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (mode == NavigationSidebarItemMode.full) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DefaultTextStyle(
                          style: Theme.of(context).textTheme.labelLarge!
                              .copyWith(
                                color: Theme.of(
                                  context,
                                ).textTheme.labelLarge?.color,
                              ),
                          child: title,
                        ),
                        if (subtitle != null)
                          DefaultTextStyle(
                            style: Theme.of(context).textTheme.labelSmall!
                                .copyWith(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.labelSmall?.color,
                                  fontSize: 10,
                                ),
                            child: subtitle!,
                          ),
                      ],
                    ),
                    Spacer(),
                    if (trailing != null)
                      SizedBox.square(
                        dimension: kMinInteractiveDimension,
                        child: Center(child: trailing),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class LanguageSelectionButton extends StatelessWidget {
//   const LanguageSelectionButton({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<SettingsBloc, SettingsState>(
//       builder: (context, state) {
//         // Get the current language code mn bloc state
//         String currentLanguageCode = state.locale.languageCode;

//         return Row(
//           children: [
//             // Icon(Ionicons.language_outline, color: Colors.white),
//             PopupMenuButton<String>(
//               icon: Icon(Ionicons.language_outline),
//               onSelected: (String languageCode) {
//                 // Dispatch the ChangeLanguage event with the selected language code
//                 context.read<SettingsBloc>().add(
//                       SettingsEvent.changeLanguage(languageCode: languageCode),
//                     );
//               },
//               itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
//                 PopupMenuItem<String>(
//                   value: 'en',
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       CountryFlag.fromCountryCode(
//                         'GB',
//                         shape: const RoundedRectangle(6),
//                         width: 20,
//                         height: 20,
//                       ),
//                       const SizedBox(width: 10),
//                       const Text('English'),
//                     ],
//                   ),
//                 ),
//                 PopupMenuItem<String>(
//                   value: 'ar',
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       CountryFlag.fromCountryCode(
//                         'DZ',
//                         shape: const RoundedRectangle(6),
//                         width: 20,
//                         height: 20,
//                       ),
//                       const SizedBox(width: 10),
//                       const Text('Arabic'),
//                     ],
//                   ),
//                 ),
//                 PopupMenuItem<String>(
//                   value: 'fr',
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       CountryFlag.fromCountryCode(
//                         'FR',
//                         shape: const RoundedRectangle(6),
//                         width: 20,
//                         height: 20,
//                       ),
//                       const SizedBox(width: 10),
//                       const Text('French'),
//                     ],
//                   ),
//                 ),
//               ],
//             ),

//             // IconButton(
//             //   icon: Icon(Ionicons.language_outline),
//             //   onPressed: () {
//             //     // Dispatch the ChangeLanguage event with the selected language code
//             //     context.read<SettingsBloc>().add(
//             //           SettingsEvent.changeLanguage(
//             //               languageCode: currentLanguageCode == 'ar'
//             //                   ? 'en'
//             //                   : currentLanguageCode == 'en'
//             //                       ? 'fr'
//             //                       : 'ar'),
//             //         );
//             //   },
//             // ),
//             // const SizedBox(width: 1),
//             // DropdownButton<String>(
//             //   value: currentLanguageCode,
//             //   underline: const SizedBox(),
//             //   icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
//             //   style: TextStyle(color: Colors.white, fontSize: 16),
//             //   items: [
//             //     DropdownMenuItem(
//             //       value: 'en',
//             //       child: Text('EN'),
//             //     ),
//             //     DropdownMenuItem(
//             //       value: 'fr',
//             //       child: Text('FR'),
//             //     ),
//             //     DropdownMenuItem(
//             //       value: 'ar',
//             //       child: Text('AR'),
//             //     ),
//             //   ],
//             //   onChanged: (String? selectedLanguage) {
//             //     if (selectedLanguage != null &&
//             //         selectedLanguage != currentLanguageCode) {
//             //       // Dispatch the ChangeLanguage event with the selected language code
//             //       context.read<SettingsBloc>().add(
//             //             SettingsEvent.changeLanguage(
//             //                 languageCode: selectedLanguage),
//             //           );
//             //     }
//             //   },
//             // ),
//           ],
//         );
//       },
//     );
//   }
// }

class AppBarActions extends StatelessWidget {
  const AppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // lang
        // theme
        // IconButton(
        //   // icon: Icon(Ionicons.moon_outline),
        //   icon: BlocBuilder<SettingsBloc, SettingsState>(
        //     builder: (context, state) {
        //       return state.themeMode == ThemeMode.dark
        //           ? Icon(Ionicons.moon_outline)
        //           : state.themeMode == ThemeMode.light
        //               ? Icon(Ionicons.sunny_outline)
        //               : Icon(Ionicons.cloudy_night_outline);
        //     },
        //   ),
        //   onPressed: () {
        //     context.read<SettingsBloc>().add(
        //           SettingsEvent.toggleThemeMode(),
        //         );
        //   },
        // ),
        // // user
        // BlocBuilder<AuthBloc, AuthState>(
        //   builder: (context, state) {
        //     return pb.authStore.isValid
        //         ? IconButton(
        //             padding: const EdgeInsets.all(2),
        //             icon: CircleAvatar(
        //               backgroundImage: (UsersRecord.fromRecordModel(
        //                               pb.authStore.model))
        //                           .avatar !=
        //                       null
        //                   ? NetworkImage(
        //                       (UsersRecord.fromRecordModel(pb.authStore.model))
        //                           .fileUrl(
        //                               (UsersRecord.fromRecordModel(
        //                                       pb.authStore.model))
        //                                   .avatar,
        //                               thumb: Size(300, 300))!,
        //                     )
        //                   : null,
        //               // backgroundImage: state.auth?. != null ? NetworkImage(state.auth!.user.photoUrl!) : null,
        //               // child: state.auth?.user.photoUrl == null ? const Icon(Ionicons.person_outline) : null,
        //             ),
        //             onPressed: () {
        //               context.push('/profile');
        //             },
        //           )
        //         : Padding(
        //             padding: const EdgeInsets.all(8.0),
        //             child: FilledButton(
        //               // style: ButtonStyle(
        //               //   backgroundColor: MaterialStateProperty.all(
        //               //       Theme.of(context).colorScheme.primary),
        //               // ),
        //               child: Text(t.auth.signin),
        //               onPressed: () {
        //                 context.go('/auth');
        //               },
        //             ),
        //           );
      ],
    );
  }
}
