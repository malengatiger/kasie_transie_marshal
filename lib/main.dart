
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/bloc/theme_bloc.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/providers/kasie_providers.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_marshal/ui/dashboard.dart';
import 'package:page_transition/page_transition.dart';

import 'auth/phone_auth_signin.dart';
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
  pp('$mx ... getCountries starting from LandingPage ...');

  me = await prefs.getUser();

  runApp(const ProviderScope(child: KasieTransieApp()));
}

int themeIndex = 0;
// late Locale locale;
lib.User? me;

class KasieTransieApp extends ConsumerWidget {
  const KasieTransieApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    pp('$mx ref from RiverPod Provider: ref: $ref');
    var m = ref.watch(countryProvider);
    if (m.hasValue) {
      pp('$mx value from the watch: ${m.value?.length} from RiverPod Provide');
    }

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
