import 'package:flutter/material.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/widgets/qr_scanner.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_marshal/ui/media_handler.dart';

class ScanVehicleForMedia extends StatefulWidget {
  const ScanVehicleForMedia({Key? key}) : super(key: key);

  @override
  ScanVehicleForMediaState createState() => ScanVehicleForMediaState();
}

class ScanVehicleForMediaState extends State<ScanVehicleForMedia>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final mm = '☕️☕️☕️☕️☕️☕️☕️☕️☕️ ScanVehicleForMedia: 🍎🍎';

  lib.Vehicle? vehicle;
  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void navigateToMediaHandler() async {
    pp('$mm ... navigate to VehicleMediaHandler ... for car: ${vehicle!.vehicleReg}');
    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) {
      return VehicleMediaHandler(
        vehicle: vehicle!,
      );
    }));
  }

  void onCarScanned(lib.Vehicle car) async {
    pp('$mm ... onCarScanned; scanner returned ${vehicle!.vehicleReg} ...');
    setState(() {
      vehicle = car;
    });
  }

  void onError() {}
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Media'),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(400),
            child: Column(
              children: [
                const SizedBox(
                  height: 24,
                ),
                Text(
                  'Scan Vehicle',
                  style: myTextStyleMediumLargeWithColor(
                      context, Theme.of(context).primaryColor, 28),
                ),
                Text(
                  'Scan the vehicle that you want to work with',
                  style: myTextStyleSmall(context),
                ),
                const SizedBox(
                  height: 24,
                ),
                GestureDetector(
                  onTap: (){
                    pp('$mm .... will try to restart a scan ...');
                  },
                  child: QRScanner(
                    onCarScanned: (car) {
                      setState(() {
                        vehicle = car;
                      });
                      onCarScanned(car);
                    },
                    onUserScanned: (u) {},
                    onError: onError, quitAfterScan: true,
                  ),
                )
              ],
            )),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(
                  height: 8,
                ),
                vehicle != null
                    ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${vehicle!.vehicleReg}',
                            style: myTextStyleMediumLargeWithColor(
                                context, Theme.of(context).primaryColor, 32),
                          ),
                          // const SizedBox(
                          //   width: 24,
                          // ),
                          ElevatedButton(
                            style: const ButtonStyle(
                              elevation: MaterialStatePropertyAll(8.0)
                            ),
                              onPressed: () {
                                navigateToMediaHandler();
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Text('Camera!'),
                              )),
                        ],
                      )
                    : Text(
                        'No Vehicle Scanned yet',
                        style: myTextStyleMediumLargeWithColor(
                            context, Colors.grey.shade700, 20),
                      ),
              ],
            ),
          )
        ],
      ),
    ));
  }
}
