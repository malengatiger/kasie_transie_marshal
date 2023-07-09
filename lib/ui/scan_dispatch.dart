import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/isolates/dispatch_isolate.dart';
import 'package:kasie_transie_library/l10n/translation_handler.dart';
import 'package:kasie_transie_library/utils/device_location_bloc.dart';
import 'package:kasie_transie_library/utils/emojis.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/local_finder.dart';
import 'package:kasie_transie_library/utils/parsers.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_library/widgets/qr_scanner.dart';
import 'package:kasie_transie_library/widgets/route_widget.dart';
import 'package:kasie_transie_library/bloc/dispatch_helper.dart';
import 'package:kasie_transie_marshal/ui/media_reminder.dart';
import 'package:realm/realm.dart';
import 'package:badges/badges.dart' as bd;

class ScanDispatch extends StatefulWidget {
  const ScanDispatch({Key? key}) : super(key: key);

  @override
  ScanDispatchState createState() => ScanDispatchState();
}

class ScanDispatchState extends State<ScanDispatch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final mm = '${E.heartOrange}${E.heartOrange}${E.heartOrange}${E.heartOrange}'
      ' ScanDispatch: ${E.heartOrange}${E.heartOrange} ';

  var cars = <lib.Vehicle>[];
  var dispatches = <lib.DispatchRecord>[];
  lib.User? user;

  // var routeLandmarks = <lib.RouteLandmark>[];
  var routes = <lib.Route>[];
  bool _showRoutes = true;
  bool _showDispatches = false;

  lib.RouteLandmark? selectedRouteLandmark;
  lib.Route? selectedRoute;
  lib.Vehicle? scannedVehicle;
  bool busy = false;
  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _setTexts();
    _getData();
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

  bool showMediaRequestMessage = false;
  void _checkVehicleMediaRequest() {
    showMediaRequestMessage = false;
      for (var value in requests) {
        if (scannedVehicle!.vehicleId! == value.vehicleId ) {
          setState(() {
            showMediaRequestMessage = true;
          });
          break;
        }
      }
  }
  Future _getData() async {
    pp('$mm ... get data ....................');
    setState(() {
      busy = true;
    });
    try {
      user = await prefs.getUser();
      selectedRoute = await prefs.getRoute();
      if (selectedRoute != null) {
        setState(() {
          busy = false;
        });
      }
      await _getAssociationVehicleMediaRequests(true);
      await _getRoutes();
    } catch (e) {
      pp(e);
    }

    setState(() {
      busy = false;
    });
  }

  Future _getRoutes() async {
    final loc = await locationBloc.getLocation();
    //
    routes = await localFinder.findNearestRoutes(
        latitude: loc.latitude,
        longitude: loc.longitude,
        radiusInMetres: 500.0);

    //check ... selected ...

    bool found = false;
    if (selectedRoute != null) {
      for (var value in routes) {
        if (value.routeId == selectedRoute!.routeId) {
          found = true;
          break;
        }
      }
    }
    if (!found) {
      selectedRoute = null;
      _showRoutes = true;
      _showDispatches = false;
    } else {
      _showRoutes = false;
      _showDispatches = true;
    }
    pp('$mm ... routes found around here: ${routes.length} ...');
  }

  int passengerCount = 0;

  Future _doDispatch() async {
    pp('$mm ... start dispatch for .... ${scannedVehicle!.vehicleReg}');
    _confirmPassengerCount();
    //await _sendTheDispatchRecord();
    setState(() {
      busy = false;
    });
  }

  Future<void> _sendTheDispatchRecord() async {
    late lib.DispatchRecord m;
    try {
      // setState(() {
      //   busy = true;
      // });
      final loc = await locationBloc.getLocation();
      lib.RouteLandmark? mark = await findNearestLandmark(loc);
      m = lib.DispatchRecord(ObjectId(),
          dispatchRecordId: Uuid.v4().toString(),
          routeName: selectedRoute!.name,
          routeId: selectedRoute!.routeId,
          created: DateTime.now().toUtc().toIso8601String(),
          vehicleId: scannedVehicle!.vehicleId,
          vehicleReg: scannedVehicle!.vehicleReg,
          associationId: scannedVehicle!.associationId,
          ownerId: scannedVehicle!.ownerId,
          marshalId: user!.userId,
          marshalName: user!.name,
          dispatched: true,
          passengers: passengerCount,
          associationName: scannedVehicle!.associationName,
          position: lib.Position(
            type: point,
            coordinates: [loc.longitude, loc.latitude],
            latitude: loc.latitude,
            longitude: loc.longitude,
          ),
          landmarkName: mark?.landmarkName,
          landmarkId: mark?.landmarkId);
      //
      pp('$mm ... _doDispatch: dispatch to be added:  ');
      dispatches.insert(0, m);
      dispatchHelper.sendDispatch(m);
      _clearFields();
      final result = await dispatchIsolate.addDispatchRecord(m);
      pp('$mm ... _doDispatch added?:  ');
      myPrettyJsonPrint(result.toJson());
    } catch (e) {
      pp(e);
      //await cacheManager.saveDispatchRecord(m);
      if (mounted) {
        showSnackBar(
            padding: 16,
            message: 'Error dispatching taxi: $e',
            context: context);
      }
    }
    // setState(() {
    //   busy = false;
    // });
  }

  Future<lib.RouteLandmark?> findNearestLandmark(Position loc) async {
    pp('$mm ... findNearestLandmark ');
    final m = await localFinder.findNearestRouteLandmark(
        latitude: loc.latitude, longitude: loc.longitude, radiusInMetres: 200);
    if (m != null) {
      pp('$mm ... findNearestLandmark found .....');
      myPrettyJsonPrint(m.toJson());
    }
    return m;
  }

  void handleScanError() {
    pp('$mm ... handle scan error ');
    if (mounted) {
      showSnackBar(message: 'Error scanning taxi', context: context);
    }
  }

  void _clearFields() {
    setState(() {
      selectedRouteLandmark = null;
      scannedVehicle = null;
      passengerCount = 0;
      _showDispatches = true;
      _showRoutes = false;
      showMediaRequestMessage = false;
    });
  }

  bool _checkIfVehicleMediaRequested() {
    if (scannedVehicle == null) {
      return false;
    }
    for (var value in requests) {
      if (value.vehicleId == scannedVehicle!.vehicleId) {
        return true;
      }
    }
    return false;
  }
  void _confirmPassengerCount() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            elevation: 16.0,
            shape: getRoundedBorder(radius: 16),
            title: Text(dispatchTaxi == null?
              'Dispatch Taxi?': dispatchTaxi! ,
              style: myTextStyleMediumLargeWithColor(
                  context, Theme.of(context).primaryColor, 24),
            ),
            content: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 420, width: 400,
                child: Column(
                  children: [
                    const SizedBox(
                      height: 24,
                    ),
                     Text(confirmDispatch == null?
                        'Please confirm YES to dispatch this taxi': confirmDispatch!),
                    const SizedBox(
                      height: 48,
                    ),
                    Text(
                      '${scannedVehicle!.vehicleReg}',
                      style: myNumberStyleLargest(context),
                    ),
                    const SizedBox(
                      height: 48,
                    ),
                    Row(
                      children: [
                        PassengerCount(
                          onCountPicked: (n) {
                            setState(() {
                              passengerCount = n;
                            });
                            Navigator.of(context).pop();
                            _sendTheDispatchRecord();
                          },
                        ),
                        const SizedBox(
                          width: 24,
                        ),
                        Text(
                          '$passengerCount',
                          style: myNumberStyleLargest(context),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 28,
                    ),
                    showMediaRequestMessage? const MediaReminder() : const SizedBox(),
                    const SizedBox(
                      height: 12,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child:  Text(no == null?
                      'No': no!)),

              const SizedBox(width: 48,),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _showRoutes = false;
                      });
                      _sendTheDispatchRecord();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(yes == null?
                          'Yes': yes!),
                    )),
              ),
            ],
          );
        });
  }

  void onRoutePicked(lib.Route route) async {
    selectedRoute = route;
    prefs.saveRoute(route);
    setState(() {
      _showRoutes = false;
      _showDispatches = true;
    });
  }

  void onCountPicked(int p1) {
    pp('$mm .... on count picked : $p1');
    setState(() {
      passengerCount = p1;
    });
  }

  void handleScannedCar(lib.Vehicle car) async {
    pp('$mm scanned car received: ${car.vehicleReg}');

    showMediaRequestMessage =
    _checkIfVehicleMediaRequested();
    setState(() {
      scannedVehicle = car;
      showScannedVehicle = true;
    });
  }

  bool showScannedVehicle = false;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? dispatchText,
      selectRouteText,
      scannerWaiting,
      cancelText, working, dispatchTaxi,
      confirmDispatch,
      no, yes, dispatchFailed,
      allPhotosVideos;
  Future _setTexts() async {
    final c = await prefs.getColorAndLocale();
    final loc = c.locale;
    dispatchText = await translator.translate('dispatch', loc);
    selectRouteText = await translator.translate('pleaseSelectRoute', loc);
    scannerWaiting = await translator.translate('scannerWaiting', loc);
    cancelText = await translator.translate('cancel', loc);
    working = await translator.translate('working', loc);
    confirmDispatch = await translator.translate('confirmDispatch', loc);
    no = await translator.translate('no', loc);
    yes = await translator.translate('yes', loc);
    dispatchTaxi = await translator.translate('dispatchTaxi', loc);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text(
          dispatchText == null ? 'Dispatch' : dispatchText!,
          style: myTextStyleLarge(context),
        ),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(520),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  selectedRoute == null
                      ? Text(selectRouteText == null
                          ? 'Please select Route'
                          : selectRouteText!)
                      : TextButton(
                          onPressed: () {
                            setState(() {
                              _showRoutes = true;
                              _showDispatches = false;
                            });
                          },
                          child: Text(
                            '${selectedRoute!.name}',
                            style: myTextStyleMediumLargeWithColor(
                                context, Theme.of(context).primaryColorLight, 20),
                          )),
                  const SizedBox(
                    height: 32,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      scannedVehicle == null
                          ? const SizedBox()
                          : Text(
                              '${scannedVehicle!.vehicleReg}',
                              style: myTextStyleMediumLargeWithColor(context,
                                  Theme.of(context).primaryColorLight, 36),
                            ),
                      const SizedBox(
                        width: 16,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  SizedBox(
                    width: 300,
                    height: 300,
                    child: selectedRoute == null
                        ? SizedBox(
                            height: 120,
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 48,
                                ),
                                Text(
                                  scannerWaiting == null
                                      ? 'Scanner waiting for Route selection'
                                      : scannerWaiting!,
                                  style: myTextStyleSmallBold(context),
                                ),
                              ],
                            ))
                        : QRScanner(
                            onCarScanned: (car) {
                              handleScannedCar(car);
                            },
                            onUserScanned: (user) {},
                            onError: () {
                              handleScanError();
                            },
                            quitAfterScan: false,
                          ),
                  ),
                  const SizedBox(
                    height: 28,
                  ),
                ],
              ),
            )),
      ),
      body: Stack(
        children: [
          busy
              ?  Center(
                  child: SizedBox(
                    width: 300,
                    height: 200,
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 48,
                        ),
                        const CircularProgressIndicator(
                          strokeWidth: 6,
                          backgroundColor: Colors.purple,
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Text(working == null?
                            'Working ... hang on a few seconds ...': working!),
                      ],
                    ),
                  ),
                )
              : _showDispatches
                  ? GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 1,
                              crossAxisSpacing: 1),
                      itemCount: dispatches.length,
                      itemBuilder: (ctx, index) {
                        final car = dispatches.elementAt(index);
                        return DispatchCarPlate(dispatchRecord: car);
                      })
                  : const SizedBox(),
          showScannedVehicle
              ? Positioned(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Card(
                  shape: getRoundedBorder(radius: 16),
                  elevation: 8,
                  child: scannedVehicle == null
                      ? const SizedBox()
                      : Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 160,
                        width: 300,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton(

                                  onPressed: () {
                                    _clearFields();
                                  },
                                  child: Text(cancelText == null
                                      ? 'Cancel'
                                      : cancelText!)),
                              SizedBox(
                                  width: 240,
                                  child: ElevatedButton(
                                      onPressed: () {
                                        _doDispatch();
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Text(dispatchText == null
                                            ? 'Dispatch'
                                            : dispatchText!),
                                      ))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ))
              : const SizedBox(),
          _showRoutes
              ? Positioned(
                  child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: RouteWidgetList(
                    routes: routes,
                    onRouteSelected: (r) {
                      onRoutePicked(r);
                    },
                  ),
                ))
              : const SizedBox(),



          // _showDispatches
          //     ? Positioned(
          //         child: DispatchWidgetList(
          //         dispatchRecords: dispatches,
          //         onDispatchRecordSelected: (dr) {},
          //       ))
          //     : const SizedBox(),
        ],
      ),
    ));
  }
}

class DispatchCarPlate extends StatelessWidget {
  const DispatchCarPlate({Key? key, required this.dispatchRecord})
      : super(key: key);
  final lib.DispatchRecord dispatchRecord;

  @override
  Widget build(BuildContext context) {
    var color = Colors.red.shade700;
    if (dispatchRecord.passengers! < 6) {
      color = Colors.amber.shade900;
    }
    if (dispatchRecord.passengers! >= 6) {
      color = Colors.teal.shade700;
    }
    if (dispatchRecord.passengers! > 16) {
      color = Colors.pink.shade700;
    }
    if (dispatchRecord.passengers! == 0) {
      color = Colors.grey;
    }
    final fmt = DateFormat('HH:mm:ss');
    final date = fmt.format(DateTime.parse(dispatchRecord.created!));
    return SizedBox(
      height: 80,
      width: 80,
      child: bd.Badge(
        badgeContent: Text(
          '${dispatchRecord.passengers}',
          style: myTextStyleSmall(context),
        ),
        position: bd.BadgePosition.topEnd(top: 2, end: -2),
        badgeStyle: bd.BadgeStyle(
          badgeColor: color,
          elevation: 8,
          padding: const EdgeInsets.all(6),
        ),
        child: Card(
          shape: getRoundedBorder(radius: 8),
          elevation: 8,
          child: Center(
            child: Column(
              children: [
                const SizedBox(
                  height: 48,
                ),
                Text(
                  '${dispatchRecord.vehicleReg}',
                  style: myTextStyleMediumLarge(context, 16),
                ),
                Text(date, style: myTextStyleSmall(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PassengerCount extends StatelessWidget {
  const PassengerCount({Key? key, required this.onCountPicked})
      : super(key: key);
  final Function(int) onCountPicked;

  @override
  Widget build(BuildContext context) {
    final items = <DropdownMenuItem<int>>[];
    for (int index = 0; index < 48; index++) {
      items.add(DropdownMenuItem<int>(value: index, child: Text('$index')));
    }
    return DropdownButton(
        hint: const Text('Passengers'), items: items, onChanged: onChanged);
  }

  void onChanged(int? value) {
    value ??= 0;
    onCountPicked(value);
  }
}
