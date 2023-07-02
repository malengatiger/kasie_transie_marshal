import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/providers/kasie_providers.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_marshal/intro/kasie_intro.dart';
import 'package:kasie_transie_marshal/ui/scan_dispatch.dart';

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

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getData();
  }

  void _getData() async {
    pp('$mm ... get data for marshal dashboard ...');
    setState(() {
      busy = true;
    });
    try {
      user = await prefs.getUser();
      if (user != null) {
            await _getRoutes();
            await _getCars();
            await _getLandmarks();
          }
    } catch (e) {
      pp(e);
      showSnackBar(
          padding: 16,
          message: 'Error getting data', context: context);
    }
    setState(() {
      busy = false;
    });
  }

  Future _getRoutes() async {
    routes = await listApiDog
        .getRoutes(AssociationParameter(user!.associationId!, false));
    pp('$mm ... marshal dashboard; routes: ${routes.length} ...');
  }

  Future _getCars() async {
    cars = await listApiDog.getAssociationVehicles(user!.associationId!, false);
    pp('$mm ... marshal dashboard; cars: ${cars.length} ...');
  }

  Future _getLandmarks() async {
    routeLandmarks =
        await listApiDog.getAssociationRouteLandmarks(user!.associationId!, false);
    pp('$mm ... marshal dashboard; routeLandmarks: ${routeLandmarks.length} ...');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToScanDispatch() async {

    navigateWithScale(const ScanDispatch(), context);
  }
  void _navigateToManualDispatch() async {

  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        leading: const SizedBox(),
        title: Text(
          'Marshal',
          style: myTextStyleLarge(context),
        ),
        actions: [
          IconButton(
              onPressed: () {
                navigateWithScale(KasieIntro(dataApiDog: dataApiDog), context);
              },
              icon: Icon(
                Icons.info_outline,
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: busy
            ? const Center(
                child: SizedBox(height: 24, width: 24,
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
                  Text('${user!.associationName}', style: myTextStyleMediumLargeWithColor(context, Theme.of(context).primaryColor, 18),),
                  const SizedBox(height: 8,),
                  Text(user!.name, style: myTextStyleSmall(context),),
                  const SizedBox(
                    height: 24,
                  ),
                  SizedBox(width: 300,
                      child: ElevatedButton(onPressed: (){
                        _navigateToScanDispatch();
                      }, child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Dispatch with Scan'),
                      ))),
                  const SizedBox(
                    height: 24,
                  ),
                  SizedBox(width: 300,
                      child: ElevatedButton(onPressed: (){
                        _navigateToManualDispatch();
                      }, child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Manual Dispatch'),
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
                            caption: 'Vehicles',
                            number: cars.length,
                            onTapped: () {}),
                        TotalWidget(
                            caption: 'Routes',
                            number: routes.length,
                            onTapped: () {}),
                        TotalWidget(
                            caption: 'Landmarks',
                            number: routeLandmarks.length,
                            onTapped: () {}),
                        TotalWidget(
                            caption: 'Dispatches',
                            number: dispatchRecords.length,
                            onTapped: () {}),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    ));
  }
}

class TotalWidget extends StatelessWidget {
  const TotalWidget(
      {Key? key,
      required this.caption,
      required this.number,
      required this.onTapped})
      : super(key: key);
  final String caption;
  final int number;
  final Function onTapped;

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
              child: Column(
                children: [
                  Text(
                    '$number',
                    style: myNumberStyleLargest(context),
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
