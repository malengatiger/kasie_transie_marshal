
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:kasie_transie_library/bloc/theme_bloc.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/messaging/fcm_bloc.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_marshal/ui/dashboard.dart';
import 'package:page_transition/page_transition.dart';

import 'firebase_options.dart';
import 'intro/splash_page.dart';

late FirebaseApp firebaseApp;
fb.User? fbAuthedUser;
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
    pp('$mx fbAuthUser: is null. Need to authenticate the app!');
  }
  me = await prefs.getUser();

// Background message handler
  FirebaseMessaging.onBackgroundMessage(kasieFirebaseMessagingBackgroundHandler);

  runApp(const KasieTransieMarshal());
}

int themeIndex = 0;
// late Locale locale;R
lib.User? me;

class KasieTransieMarshal extends StatelessWidget {
  const KasieTransieMarshal({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    return StreamBuilder(
        stream: themeBloc.localeAndThemeStream,
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
              theme: themeBloc.getTheme(themeIndex).lightTheme,
              darkTheme: themeBloc.getTheme(themeIndex).darkTheme,
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
