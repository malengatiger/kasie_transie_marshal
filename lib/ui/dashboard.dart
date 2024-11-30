import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/color_and_locale.dart';
import 'package:kasie_transie_library/data/data_schemas.dart' as lib;
import 'package:kasie_transie_library/l10n/translation_handler.dart';
import 'package:kasie_transie_library/maps/association_route_maps.dart';
import 'package:kasie_transie_library/messaging/fcm_bloc.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils_old.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_library/widgets/days_drop_down.dart';
import 'package:kasie_transie_library/widgets/language_and_color_chooser.dart';
import 'package:kasie_transie_library/widgets/scanners/dispatch_helper.dart';
import 'package:kasie_transie_library/widgets/scanners/dispatch_via_scan.dart';
import 'package:kasie_transie_library/widgets/scanners/scan_vehicle_for_media.dart';
import 'package:kasie_transie_library/widgets/timer_widget.dart';
import 'package:kasie_transie_library/auth/phone_auth_signin2.dart';

import 'package:get_it/get_it.dart';
class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  DashboardState createState() => DashboardState();
}

class DashboardState extends State<Dashboard>
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
  var totalPassengers = 0;
  lib.VehicleMediaRequest? vehicleMediaRequest;
  ListApiDog listApiDog = GetIt.instance<ListApiDog>();
  Prefs prefs = GetIt.instance<Prefs>();

  late StreamSubscription<lib.DispatchRecord> _dispatchStreamSubscription;
  late StreamSubscription<lib.VehicleMediaRequest> _mediaRequestSubscription;
  late StreamSubscription<lib.RouteUpdateRequest> _routeUpdateSubscription;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _listen();
    _setTexts();
    _getAuthenticationStatus();
  }

  void _listen() async {
    _dispatchStreamSubscription = dispatchHelper.dispatchStream.listen((event) {
      pp('$mm dispatchHelper.dispatchStream delivered ${event.vehicleReg}');
      dispatchRecords.insert(0, event);
      _aggregatePassengers();
      if (mounted) {
        setState(() {});
      }
    });
    //
    _mediaRequestSubscription =
        fcmBloc.vehicleMediaRequestStream.listen((event) {
      pp('$mm fcmBloc.vehicleMediaRequestStream delivered ${event.vehicleReg}');
      if (mounted) {
        _confirmNavigationToPhotos(event);
      }
    });
    //
    _routeUpdateSubscription = fcmBloc.routeUpdateRequestStream.listen((event) {
      pp('$mm fcmBloc.routeUpdateRequestStream delivered: ${event.routeName}');
      _startRouteUpdate(event);
    });
  }

  void _aggregatePassengers() {
    totalPassengers = 0;
    for (var value in dispatchRecords) {
      totalPassengers += value.passengers!;
    }
  }

  void _confirmNavigationToPhotos(lib.VehicleMediaRequest request) {
    pp('$mm confirm dialog for navigation to vehicle media control ');

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (ctx) {
          return AlertDialog(
            content: Column(
              children: [
                const Text(
                    'You have been requested to take pictures and or video of the vehicle.\n'
                    'Please tap YES to start the photos or do that at the earliest opportunity.'),
                const SizedBox(
                  height: 48,
                ),
                Row(
                  children: [
                    const Text('Vehicle: '),
                    Text(
                      '${request.vehicleReg}',
                      style: myTextStyleMediumLargeWithColor(
                          context, Theme.of(context).primaryColor, 32),
                    )
                  ],
                ),
                const SizedBox(
                  height: 48,
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: () {
                    _navigateToScanVehicleForMedia();
                  },
                  child: const Text("Start the Camera")),
            ],
          );
        });
  }

  void _startRouteUpdate(lib.RouteUpdateRequest request) async {
    pp('$mm start route update in isolate for ${request.routeName} ...  ');
    //routesIsolate.getRoute(user!.associationId!, request.routeId!);

    if (mounted) {
      showSnackBar(
          duration: const Duration(seconds: 10),
          message: 'Route ${request.routeName} has been refreshed! Thanks',
          context: context);
    }
  }

  void _getAuthenticationStatus() async {
    pp('\n\n$mm _getAuthenticationStatus ....... '
        'check both Firebase user and Kasie user');
    user = await prefs.getUser();
    var firebaseUser = FirebaseAuth.instance.currentUser;

    if (user != null && firebaseUser != null) {
      pp('$mm _getAuthenticationStatus .......  '
          '🥬🥬🥬auth is DEFINITELY authenticated and OK');
      authed = true;
      fcmBloc.subscribeToTopics('MarshallApp');
      _getData();
    } else {
      pp('$mm _getAuthenticationStatus ....... NOT AUTHENTICATED! '
          '🌼🌼🌼 ... will clean house!!');
      authed = false;
      _navigateToPhoneAuth();
    }
  }

  Future _navigateToPhoneAuth() async {
    pp('$mm ... _navigateToPhoneAuth ....');
    user = await navigateWithScale(
        PhoneAuthSignin(
          onGoodSignIn: (){},
          onSignInError: (){},
        ),
        context);

    if (user != null) {
      pp('$mm ... back from _navigateToPhoneAuth  with user: ${user!.name}');
      _getData();
    }
  }

  var requests = <lib.VehicleMediaRequest>[];

  Future _getAssociationVehicleMediaRequests(bool refresh) async {
    final startDate = DateTime.now()
        .toUtc()
        .subtract(const Duration(days: 30))
        .toIso8601String();
    requests = await listApiDog.getAssociationVehicleMediaRequests(
        user!.associationId!, startDate, refresh);
  }

  void _navigateToScanVehicleForMedia() {
    pp('$mm navigate to ScanVehicleForMedia ...  ');
    navigateWithScale(const ScanVehicleForMedia(), context);
  }

  Future _getData() async {
    pp('$mm ................... get data for marshal dashboard ...');
    user =  prefs.getUser();
    setState(() {
      busy = true;
    });
    try {
      colorAndLocale =  prefs.getColorAndLocale();
      // _setTexts();

      if (user != null) {
        await _getRoutes();
        await _getLandmarks();
        await _getCars();
        await _getDispatches(false);
        await _getAssociationVehicleMediaRequests(false);
      }
    } catch (e) {
      pp(e);
      if (mounted) {
        showSnackBar(
            padding: 16, message: 'Error getting data', context: context);
      }
      ;
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
      days,
      dispatchesText,
      passengers,
      marshalText;
  String welcome = '', startSignIn = ' ', firstTime = '';

  Future _setTexts() async {
    colorAndLocale = await prefs.getColorAndLocale();
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

    passengers =
        await translator.translate('passengers', colorAndLocale.locale);
    days = await translator.translate('days', colorAndLocale.locale);

    welcome = await translator.translate('welcome', colorAndLocale.locale);
    startSignIn =
        await translator.translate('signInWithPhone', colorAndLocale.locale);
    firstTime = await translator.translate('firstTime', colorAndLocale.locale);

    setState(() {});
  }

  int daysForData = 7;

  Future _getRoutes() async {
    pp('$mm ... marshal dashboard; getting routes: ${routes.length} ...');

    routes = await listApiDog.getAssociationRoutes(user!.associationId!, false);
    pp('$mm ... marshal dashboard; routes: ${routes.length} ...');
    setState(() {});
  }

  Future _getCars() async {
    pp('$mm ... marshal dashboard; getting cars: ${cars.length} ...');

    cars = await listApiDog.getAssociationCars(user!.associationId!, false);
    pp('$mm ... marshal dashboard; cars: ${cars.length} ...');
    setState(() {});
  }

  Future _getDispatches(bool refresh) async {
    pp('$mm ... marshal dashboard; getting dispatches: ${dispatchRecords.length} ...');
    setState(() {
      busy = true;
    });
    try {
      dispatchRecords = await listApiDog.getMarshalDispatchRecords(
          userId: user!.userId!, refresh: refresh, days: daysForData);
      _aggregatePassengers();
      pp('$mm ... marshal dashboard; dispatchRecords: ${dispatchRecords.length} ...');
    } catch (e) {
      pp(e);
    }
    setState(() {
      busy = false;
    });
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
    _dispatchStreamSubscription.cancel();
    _routeUpdateSubscription.cancel();
    _mediaRequestSubscription.cancel();
    super.dispose();
  }

  void _navigateToScanDispatch() async {
    pp('$mm _navigateToScanDispatch ......');

    navigateWithScale(const DispatchViaScan(), context);
  }

  Future _navigateToColor() async {
    pp('$mm _navigateToColor ......');
    await navigateWithScale(
        LanguageAndColorChooser(
          onLanguageChosen: () {},
        ),
        context);
    colorAndLocale = await prefs.getColorAndLocale();
    await _setTexts();
  }
  void _navigateToMap() {
    navigateWithScale(const AssociationRouteMaps(), context);
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
                  _navigateToMap();
                },
                icon: Icon(
                  Icons.map,
                  color: Theme.of(context).primaryColor,
                )),
            IconButton(
                onPressed: () {
                  _navigateToScanVehicleForMedia();
                },
                icon: Icon(
                  Icons.camera_alt,
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
          ],
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                shape: getRoundedBorder(radius: 16),
                elevation: 4,
                child: Column(
                  children: [
                    const SizedBox(
                      height: 32,
                    ),
                    Text(
                      user == null
                          ? 'Association Name'
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
                            style: ButtonStyle(
                                elevation: const WidgetStatePropertyAll(8.0)),
                            onPressed: () {
                              _navigateToScanDispatch();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(dispatchWithScan == null
                                  ? 'Dispatch with Scan'
                                  : dispatchWithScan!),
                            ))),
                    gapH32,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            DaysDropDown(
                                onDaysPicked: (days) {
                                  daysForData = days;
                                  setState(() {});
                                  _getDispatches(true);
                                },
                                hint: days == null ? 'Days' : days!),
                            const SizedBox(
                              width: 20,
                            ),
                            Text(
                              '$daysForData',
                              style: myTextStyleMediumLargeWithColor(context,
                                  Theme.of(context).primaryColorLight, 24),
                            )
                          ],
                        ),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: GridView(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 2,
                            crossAxisCount: 2,
                          ),
                          children: [
                            TotalWidget(
                                caption: dispatchesText == null
                                    ? 'Dispatches'
                                    : dispatchesText!,
                                number: dispatchRecords.length,
                                color: Theme.of(context).primaryColor,
                                fontSize: 32,
                                onTapped: () {}),
                            TotalWidget(
                                caption: passengers == null
                                    ? 'Passengers'
                                    : passengers!,
                                number: totalPassengers,
                                color: Theme.of(context).primaryColor,
                                fontSize: 32,
                                onTapped: () {}),
                            TotalWidget(
                                caption: vehiclesText == null
                                    ? 'Vehicles'
                                    : vehiclesText!,
                                number: cars.length,
                                color: Colors.grey.shade600,
                                fontSize: 32,
                                onTapped: () {}),
                            TotalWidget(
                                caption:
                                    routesText == null ? 'Routes' : routesText!,
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
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            busy
                ? const Positioned(
                    child: Center(
                        child: TimerWidget(
                            title: 'Loading data ...', isSmallSize: false)))
                : gapH32,
          ],
        ),
      ),
    );
  }
}

class Welcome extends StatelessWidget {
  const Welcome(
      {super.key,
      required this.welcome,
      required this.onAuthRequested,
      required this.firstTime,
      required this.startSignIn});

  final String welcome, firstTime, startSignIn;
  final Function onAuthRequested;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        // appBar: AppBar(
        //   leading: const SizedBox(),
        //   title: Text(
        //     welcome,
        //     style: myTextStyleMediumLargeWithColor(
        //         context, Theme.of(context).primaryColor, 24),
        //   ),
        // ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            shape: getRoundedBorder(radius: 16),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 64,
                  ),
                  Text(
                    welcome,
                    style: myTextStyleLarge(context),
                  ),
                  const SizedBox(
                    height: 32,
                  ),
                  Text(firstTime),
                  const SizedBox(
                    height: 64,
                  ),
                  SizedBox(
                    width: 320,
                    child: ElevatedButton(
                        onPressed: () {
                          onAuthRequested();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(startSignIn),
                        )),
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

class TotalWidget extends StatelessWidget {
  const TotalWidget(
      {super.key,
      required this.caption,
      required this.number,
      required this.onTapped,
      required this.color,
      required this.fontSize});
  final String caption;
  final int number;
  final Function onTapped;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
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
              height: 80,
              child: NumberAndCaption(
                  caption: caption,
                  number: number,
                  color: color,
                  fontSize: fontSize),
            ),
          ),
        ),
      ),
    );
  }
}

class NumberAndCaption extends StatelessWidget {
  const NumberAndCaption(
      {super.key,
      required this.caption,
      required this.number,
      required this.color,
      required this.fontSize});
  final String caption;
  final int number;
  final Color color;
  final double fontSize;
  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.decimalPattern();
    return SizedBox(
      height: 64,
      child: Column(
        children: [
          Text(
            fmt.format(number),
            style: myNumberStyleLargerWithColor(color, fontSize, context),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            caption,
            style: myTextStyleSmall(context),
          ),
        ],
      ),
    );
  }
}
