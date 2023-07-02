import 'package:dots_indicator/dots_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:kasie_transie_library/auth/phone_auth_signin.dart';
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/providers/kasie_providers.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/auth/email_auth_signin.dart';

import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_marshal/ui/dashboard.dart';

import 'intro_page_one.dart';

class KasieIntro extends StatefulWidget {
  const KasieIntro({
    Key? key,
    // required this.listApiDog,
    required this.dataApiDog,
  }) : super(key: key);

  // final ListApiDog listApiDog;
  final DataApiDog dataApiDog;

  // final Prefs prefs;

  @override
  KasieIntroState createState() => KasieIntroState();
}

class KasieIntroState extends State<KasieIntro>
    with SingleTickerProviderStateMixin {
  final mm = '🍎🍎 KasieIntro 🍎🍎🍎🍎';
  late AnimationController _controller;
  bool authed = false;
  int currentIndexPage = 0;
  final PageController _pageController = PageController();
  fb.FirebaseAuth firebaseAuth = fb.FirebaseAuth.instance;

  // mrm.User? user;
  String? signInFailed;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getAuthenticationStatus();
  }

  void _getAuthenticationStatus() async {
    pp('\n\n$mm _getAuthenticationStatus ....... '
        'check both Firebase user and Kasie user');
    var user = await prefs.getUser();
    var firebaseUser = firebaseAuth.currentUser;

    if (user != null && firebaseUser != null) {
      pp('$mm _getAuthenticationStatus .......  '
          '🥬🥬🥬auth is DEFINITELY authenticated and OK');
      authed = true;
    } else {
      pp('$mm _getAuthenticationStatus ....... NOT AUTHENTICATED! '
          '🌼🌼🌼 ... will clean house!!');
      authed = false;
      //todo - ensure that the right thing gets done!
      // prefs.deleteUser();
      firebaseAuth.signOut();
      pp('$mm _getAuthenticationStatus .......  '
          '🔴🔴🔴🔴'
          'the device should be ready for sign in or registration');
    }
    pp('$mm ......... _getAuthenticationStatus ....... setting state, authed = $authed ');
    setState(() {});
  }

  onSignInWithEmail() async {
    pp('$mm ...  onSignInWithEmail');

    var res = await Navigator.of(context).push(MaterialPageRoute(
        builder: (ctx) => const EmailAuthSignin()));
    pp('$mm ... returned from sign in .... $res');
    if (res is lib.User) {
      pp('$mm ... returned from sign in .... $res');
      pp('$mm ... User is fine to this point');

      onSuccessfulSignIn(res);
    }
  }

  onSignInWithPhone() async {
    pp('$mm ... onSignInWithPhone ....');

    var res = await Navigator.of(context).push(MaterialPageRoute(
        builder: (ctx) => PhoneAuthSignin(
            dataApiDog: widget.dataApiDog,
            onSuccessfulSignIn: onSuccessfulSignIn)));
    pp('$mm ... returned from sign in .... $res');
    if (res is lib.User) {
      pp('$mm ... returned from sign in .... $res');
      pp('$mm ... User is fine to this point');
      onSuccessfulSignIn(res);
    }
  }

  onRegister() {
    pp('$mm ... onRegister ....');
  }

  void onSignIn() async {

  }

  void onSuccessfulSignIn(lib.User p1) {
    pp('$mm ... onSuccessfulSignIn .... ${p1.name}');
    //Navigator.of(context).pop(p1);
    navigateWithScale(
        const Dashboard(),
        context);
  }

  void _onPageChanged(int value) {}

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;
    var color = getTextColorForBackground(Theme.of(context).primaryColor);

    if (isDarkMode) {
      color = Theme.of(context).primaryColor;
    }
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text(
          'KasieTransie',
          style: myTextStyleLargeWithColor(context, color),
        ),
        bottom: PreferredSize(
            preferredSize: Size.fromHeight(authed ? 80 : 124),
            child: Column(
              children: [
                Header(onSignInWithEmail: onSignInWithEmail, onSignInWithPhone: onSignInWithPhone, onRegister: onRegister),
                const SizedBox(
                  height: 12,
                ),
              ],
            )),
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: const [
              IntroPage(
                title: 'KasieTransie',
                assetPath: 'assets/intro/pic2.jpg',
                text: lorem,
              ),
              IntroPage(
                  title: 'Organizations',
                  assetPath: 'assets/intro/pic5.jpg',
                  text: lorem),
              IntroPage(
                  title: 'People',
                  assetPath: 'assets/intro/pic1.jpg',
                  text: lorem),
              IntroPage(
                title: 'Field Monitors',
                assetPath: 'assets/intro/pic5.jpg',
                text: lorem,
              ),
              IntroPage(
                title: 'Thank You',
                assetPath: 'assets/intro/pic3.webp',
                text: lorem,
              ),
            ],
          ),
          Positioned(
            bottom: 2,
            left: 48,
            right: 40,
            child: SizedBox(
              width: 200,
              height: 48,
              child: Card(
                color: Colors.black12,
                shape: getRoundedBorder(radius: 8),
                child: DotsIndicator(
                  dotsCount: 5,
                  position: currentIndexPage,
                  decorator: const DotsDecorator(
                    colors: [
                      Colors.grey,
                      Colors.grey,
                      Colors.grey,
                      Colors.grey,
                      Colors.grey,
                    ], // Inactive dot colors
                    activeColors: [
                      Colors.pink,
                      Colors.blue,
                      Colors.teal,
                      Colors.indigo,
                      Colors.deepOrange,
                    ], // Àctive dot colors
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }


}

class Header extends StatelessWidget {
  const Header({Key? key, required this.onSignInWithEmail, required this.onSignInWithPhone, required this.onRegister}) : super(key: key);

  final Function onSignInWithEmail, onSignInWithPhone, onRegister;
  @override
  Widget build(BuildContext context) {
    return  Card(
      shape: getRoundedBorder(radius: 16),
      elevation: 8,
      child: DropdownButton<int>(
        hint: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Please select the kind of sign in', style: myTextStyleMedium(context),),
        ),
        items: const [
          DropdownMenuItem(
              value: 0,
              child: Row(children: [
            Icon(Icons.phone),
            SizedBox(width: 20,),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Sign in with your phone'),
            ),

          ],)),
          DropdownMenuItem(
              value: 1,
              child: Row(children: [
            Icon(Icons.email),
            SizedBox(width: 20,),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Sign in with your email address'),
            ),

          ],)),
          DropdownMenuItem(
              value: 2,
              child: Row(children: [
            Icon(Icons.edit),
            SizedBox(width: 20,),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Register Your Association'),
            ),

          ],)),
        ],
        onChanged: (index) {
          switch(index) {
            case 0:
              onSignInWithPhone();
              break;
            case 1:
              onSignInWithEmail();
              break;
            case 2:
              onRegister();
              break;

          }
        },
      ),
    );
  }
}

