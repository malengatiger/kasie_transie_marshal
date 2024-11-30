
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:kasie_transie_library/bloc/register_services.dart';
import 'package:kasie_transie_library/bloc/theme_bloc.dart';
import 'package:kasie_transie_library/data/data_schemas.dart' as lib;
import 'package:kasie_transie_library/messaging/fcm_bloc.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_marshal/ui/dashboard.dart';
import 'package:page_transition/page_transition.dart';
import 'package:get_it/get_it.dart';
import 'firebase_options.dart';
import 'intro/splash_page.dart';

late FirebaseApp firebaseApp;
fb.User? fbAuthedUser;
late KasieThemeManager kasieThemeManager;
lib.User? me;
int themeIndex = 0;

const mx = '🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵 KasieTransie Marshal : main 🔵🔵';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  firebaseApp = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
  pp('\n\n$mx '
      ' Firebase App has been initialized: ${firebaseApp.name}, checking for authed current user\n');
  fbAuthedUser = fb.FirebaseAuth.instance.currentUser;
  if (fbAuthedUser != null) {
    pp('$mx fbAuthUser: ${fbAuthedUser!.uid}');
    pp("$mx .... fbAuthUser is cool! ........ on to the party!!");
  } else {
    pp('$mx fbAuthUser: is null. will need to authenticate the app!');
  }
  try {
    await RegisterServices.register();
  } catch (e) {
  pp('$mx Houston, we have a problem! $e');
  }

  // Set up Background message handler
  FirebaseMessaging.onBackgroundMessage(kasieFirebaseMessagingBackgroundHandler);

  runApp(KasieTransieMarshal());
}

class KasieTransieMarshal extends StatelessWidget {
   KasieTransieMarshal({super.key});
  // This widget is the root of your application.
  final KasieThemeManager kasieThemeManager = GetIt.instance<KasieThemeManager>();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: kasieThemeManager.localeAndThemeStream,
        builder: (ctx, snapshot) {
          if (snapshot.hasData) {
            pp(' 🔵 🔵 🔵'
                'build: theme index has changed to ${snapshot.data!.themeIndex}'
                '  and locale is ${snapshot.data!.locale}');
            themeIndex = snapshot.data!.themeIndex;
          }

          return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Marshal',
              theme: kasieThemeManager.getTheme(themeIndex).lightTheme,
              darkTheme: kasieThemeManager.getTheme(themeIndex).darkTheme,
              themeMode: ThemeMode.system,
              // home:  const Dashboard(),
              home: AnimatedSplashScreen(
                splash: const SplashWidget(),
                animationDuration: const Duration(milliseconds: 2000),
                curve: Curves.easeInCirc,
                splashIconSize: 160.0,
                nextScreen: const Dashboard(),
                splashTransition: SplashTransition.fadeTransition,
                pageTransitionType: PageTransitionType.leftToRight,
                backgroundColor: Colors.brown.shade800,
              ),
          );
        });
  }
}
