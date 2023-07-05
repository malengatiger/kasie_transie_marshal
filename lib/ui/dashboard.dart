import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/color_and_locale.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/l10n/translation_handler.dart';
import 'package:kasie_transie_library/providers/kasie_providers.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_library/widgets/language_and_color_chooser.dart';
import 'package:kasie_transie_marshal/auth/phone_auth_signin.dart';
import 'package:kasie_transie_marshal/intro/kasie_intro.dart';
import 'package:kasie_transie_library/bloc/dispatch_helper.dart';
import 'package:kasie_transie_marshal/ui/scan_dispatch.dart';
import 'package:kasie_transie_library/bloc/dispatch_helper.dart';

class Dashboard extends ConsumerStatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  ConsumerState createState() => DashboardState();
}

class DashboardState extends ConsumerState<Dashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  static const mm = '😡😡😡😡😡😡😡 Dashboard: 💪 ';

  lib.User? user;
  var cars = <lib.Vehicle>[];
  var routes = <lib.Route>[];
  var routeLandmarks = <lib.RouteLandmark>[];
  var dispatchRecords = <lib.DispatchRecord>[];
  bool busy = false;
  late ColorAndLocale colorAndLocale;
  bool authed = false;
  late StreamSubscription<lib.DispatchRecord> _streamSubscription;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _listen();
    _getAuthenticationStatus();
  }

  void _listen() async {
    _streamSubscription = dispatchHelper.dispatchStream.listen((event) {
      pp('$mm dispatchHelper.dispatchStream delivered ${event.vehicleReg}');
      dispatchRecords.insert(0, event);
      if (mounted) {
        setState(() {

        });
      }
    });
  }
  void _getAuthenticationStatus() async {
    pp('\n\n$mm _getAuthenticationStatus ....... '
        'check both Firebase user and Kasie user');
    var user = await prefs.getUser();
    var firebaseUser = FirebaseAuth.instance.currentUser;

    if (user != null && firebaseUser != null) {
      pp('$mm _getAuthenticationStatus .......  '
          '🥬🥬🥬auth is DEFINITELY authenticated and OK');
      user = await prefs.getUser();
      myPrettyJsonPrint(user!.toJson());
      authed = true;
      setState(() {});
      _getData();
    } else {
      pp('$mm _getAuthenticationStatus ....... NOT AUTHENTICATED! '
          '🌼🌼🌼 ... will clean house!!');
      authed = false;
      //todo - ensure that the right thing gets done!
      pp('$mm _getAuthenticationStatus .......  '
          '🔴🔴🔴🔴'
          'the device should be ready for sign in or registration');
    }
    pp('$mm ......... _getAuthenticationStatus ....... setting state, authed = $authed ');

    setState(() {});
  }

  Future<void> _navigateToAuth() async {
    var res = await navigateWithScale(
        CellPhoneAuthSignin(dataApiDog: dataApiDog), context);
    pp('\n\n$mm ................ back from sign in: $res');
    setState(() {
      busy = false;
    });
    user = await prefs.getUser();
    _getData();
  }

  Future _getData() async {
    pp('$mm ................... get data for marshal dashboard ...');
    user = await prefs.getUser();
    setState(() {
      busy = true;
    });
    try {
      colorAndLocale = await prefs.getColorAndLocale();
     // _setTexts();

      if (user != null) {
        await _getRoutes();
        await _getLandmarks();
        await _getCars();
        await _getDispatches();
        _setTexts();
      }
    } catch (e) {
      pp(e);
      if (mounted) {
        showSnackBar(
                  padding: 16, message: 'Error getting data', context: context);
      };
    }
    //
    setState(() {
      busy = false;
    });
  }

  String? dispatchWithScan,
      manualDispatch,
      vehiclesText,
      routesText,
      landmarksText,
      dispatchesText,
      marshalText;

  Future _setTexts() async {
    dispatchWithScan =
        await translator.translate('dispatchWithScan', colorAndLocale.locale);
    manualDispatch =
        await translator.translate('manualDispatch', colorAndLocale.locale);
    vehiclesText =
        await translator.translate('vehicles', colorAndLocale.locale);

    routesText = await translator.translate('routes', colorAndLocale.locale);
    landmarksText =
        await translator.translate('landmarks', colorAndLocale.locale);
    dispatchesText =
        await translator.translate('dispatches', colorAndLocale.locale);

    marshalText = await translator.translate('marshal', colorAndLocale.locale);
    setState(() {

    });
  }

  Future _getRoutes() async {
    pp('$mm ... marshal dashboard; getting routes: ${routes.length} ...');

    routes = await listApiDog
        .getRoutes(AssociationParameter(user!.associationId!, false));
    pp('$mm ... marshal dashboard; routes: ${routes.length} ...');
    setState(() {});

  }

  Future _getCars() async {
    pp('$mm ... marshal dashboard; getting cars: ${cars.length} ...');

    cars = await listApiDog
        .getAssociationVehicles(user!.associationId!, false);
    pp('$mm ... marshal dashboard; cars: ${cars.length} ...');
    setState(() {});

  }

  Future _getDispatches() async {
    pp('$mm ... marshal dashboard; getting dispatches: ${dispatchRecords.length} ...');

    dispatchRecords = await listApiDog
        .getMarshalDispatchRecords(user!.userId!, false);
    pp('$mm ... marshal dashboard; dispatchRecords: ${dispatchRecords.length} ...');
    setState(() {});

  }

  Future _getLandmarks() async {
    routeLandmarks = await listApiDog.getAssociationRouteLandmarks(
        user!.associationId!, false);
    pp('$mm ... marshal dashboard; routeLandmarks: ${routeLandmarks.length} ...');
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToScanDispatch() async {
    pp('$mm _navigateToScanDispatch ......');

    navigateWithScale(const ScanDispatch(), context);
  }

  void _navigateToManualDispatch() async {}

  Future _navigateToColor() async {
    pp('$mm _navigateToColor ......');
    await navigateWithScale(const LanguageAndColorChooser(), context);
    colorAndLocale = await prefs.getColorAndLocale();
    await _setTexts();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              leading: const SizedBox(),
              title: Text(
                marshalText == null ? 'Marshal' : marshalText!,
                style: myTextStyleLarge(context),
              ),
              actions: [
                IconButton(
                    onPressed: () {
                      navigateWithScale(
                          KasieIntro(dataApiDog: dataApiDog), context);
                    },
                    icon: Icon(
                      Icons.info_outline,
                      color: Theme.of(context).primaryColor,
                    )),
                IconButton(
                    onPressed: () {
                      _navigateToColor();
                    },
                    icon: Icon(
                      Icons.color_lens,
                      color: Theme.of(context).primaryColor,
                    )),
                IconButton(
                    onPressed: () {
                      //
                    },
                    icon: Icon(
                      Icons.refresh,
                      color: Theme.of(context).primaryColor,
                    )),
              ],
            ),
            body: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: busy
                      ? const Center(
                          child: SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 6,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            const SizedBox(
                              height: 64,
                            ),
                            Text(
                              user == null
                                  ? 'Association Name}'
                                  : user!.associationName!,
                              style: myTextStyleMediumLargeWithColor(
                                  context, Theme.of(context).primaryColor, 18),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            Text(
                              user == null ? 'Marshal Name' : user!.name,
                              style: myTextStyleSmall(context),
                            ),
                            const SizedBox(
                              height: 24,
                            ),
                            SizedBox(
                                width: 300,
                                child: ElevatedButton(
                                    onPressed: () {
                                      _navigateToScanDispatch();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(dispatchWithScan == null
                                          ? 'Dispatch with Scan'
                                          : dispatchWithScan!),
                                    ))),
                            const SizedBox(
                              height: 24,
                            ),
                            SizedBox(
                                width: 300,
                                child: ElevatedButton(
                                    style: ButtonStyle(
                                      backgroundColor: MaterialStatePropertyAll(Theme.of(context).unselectedWidgetColor)
                                    ),
                                    onPressed: () {
                                      _navigateToManualDispatch();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(manualDispatch == null
                                          ? 'Manual Dispatch'
                                          : manualDispatch!),
                                    ))),
                            const SizedBox(
                              height: 48,
                            ),
                            Expanded(
                              child: GridView(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisSpacing: 2,
                                  mainAxisSpacing: 2,
                                  crossAxisCount: 2,
                                ),
                                children: [
                                  TotalWidget(
                                      caption: vehiclesText == null
                                          ? 'Vehicles'
                                          : vehiclesText!,
                                      number: cars.length,
                                      color: Colors.grey.shade600,
                                      fontSize: 32,
                                      onTapped: () {}),
                                  TotalWidget(
                                      caption: routesText == null
                                          ? 'Routes'
                                          : routesText!,
                                      number: routes.length,
                                      color: Colors.grey.shade600,
                                      fontSize: 32,
                                      onTapped: () {}),
                                  TotalWidget(
                                      caption: landmarksText == null
                                          ? 'Landmarks'
                                          : landmarksText!,
                                      number: routeLandmarks.length,
                                      color: Colors.grey.shade600,
                                      fontSize: 32,
                                      onTapped: () {}),
                                  TotalWidget(
                                      caption: dispatchesText == null
                                          ? 'Dispatches'
                                          : dispatchesText!,
                                      number: dispatchRecords.length,
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 40,
                                      onTapped: () {}),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
                user == null
                    ? Positioned(
                        left: 12,
                        right: 12,
                        top: 64,
                        bottom: 64,
                        child: Center(
                          child: Card(
                            shape: getRoundedBorder(radius: 16),
                            elevation: 8,
                            child: SizedBox(
                              height: 400,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      height: 64,
                                    ),
                                    Text('Welcome!', style: myTextStyleLarge(context),),
                                    const SizedBox(
                                      height: 32,
                                    ),
                                    const Text(
                                        'Welcome! This is the first time that you have opened the app and you '
                                        'need to sign in to your Taxi Association or other organization.'),
                                    const SizedBox(
                                      height: 64,
                                    ),
                                    ElevatedButton(
                                        onPressed: () {
                                          _navigateToAuth();
                                        },
                                        child: const Text('Start Sign In')),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ))
                    : const SizedBox()
              ],
            )));
  }
}

class TotalWidget extends StatelessWidget {
  const TotalWidget(
      {Key? key,
      required this.caption,
      required this.number,
      required this.onTapped,
      required this.color,
      required this.fontSize})
      : super(key: key);
  final String caption;
  final int number;
  final Function onTapped;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      width: 120,
      child: GestureDetector(
        onTap: () {
          onTapped();
        },
        child: Card(
          shape: getRoundedBorder(radius: 16),
          elevation: 8,
          child: Center(
            child: SizedBox(
              height: 100,
              child: Column(
                children: [
                  Text(
                    '$number',
                    style:
                        myNumberStyleLargerWithColor(color, fontSize, context),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Text(
                    caption,
                    style: myTextStyleSmall(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
