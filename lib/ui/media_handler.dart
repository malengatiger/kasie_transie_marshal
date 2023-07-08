import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/utils/emojis.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/widgets/photo_handler.dart';
import 'package:kasie_transie_library/widgets/video_recorder.dart';
import 'package:badges/badges.dart' as bd;

class VehicleMediaHandler extends StatefulWidget {
  const VehicleMediaHandler({Key? key, required this.vehicle})
      : super(key: key);

  final lib.Vehicle vehicle;

  @override
  VehicleMediaHandlerState createState() => VehicleMediaHandlerState();
}

class VehicleMediaHandlerState extends State<VehicleMediaHandler>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const mm = ' 🔷🔷🔷🔷🔷🔷 VehicleMediaHandler 🔷';
  var vehiclePhotos = <lib.VehiclePhoto>[];
  final videoFiles = <File>[];

  final photoThumbFiles = <File>[];
  bool busy = false;
  bool showAllPhotos = false;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getVehiclePhotos(false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _getVehiclePhotos(bool refresh) async {
    pp('$mm ... get prior photos ...');
    try {
      setState(() {
        busy = true;
      });
      vehiclePhotos =
          await listApiDog.getVehiclePhotos(widget.vehicle.vehicleId!, refresh);
      vehiclePhotos.sort((a, b) => b.created!.compareTo(a.created!));
      pp('$mm ... received prior photos ...${E.appleRed} ${vehiclePhotos.length}');
    } catch (e) {
      pp(e);
    }
    setState(() {
      busy = false;
      showAllPhotos = true;
    });
  }

  Future<void> _navigateToPhotoHandler() async {
    await navigateWithScale(
        PhotoHandler(
            vehicle: widget.vehicle,
            onPhotoTaken: (file, tFile) {
              pp('$mm photo files received ${tFile.path}');

              setState(() {
                photoThumbFiles.insert(0, tFile);
              });
            }),
        context);
    pp('$mm back from PhotoHandler ... set state ...');
    setState(() {
      showAllPhotos = false;
    });
  }

  void _navigateToVideoRecorder() {
    navigateWithScale(
        VideoRecorder(
            vehicle: widget.vehicle,
            onVideoMade: (file, tFile) {
              pp('$mm video files received ${tFile.path}');
              setState(() {
                videoFiles.add(file);
                photoThumbFiles.add(tFile);
              });
            }),
        context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Media'),
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  showAllPhotos = !showAllPhotos;
                });
                if (showAllPhotos) {
                  _getVehiclePhotos(true);
                }
              },
              icon: const Icon(Icons.list)),
          IconButton(
              onPressed: () {
                _getVehiclePhotos(true);
              },
              icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Stack(
        children: [
          Card(
            child: Column(
              children: [
                const SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${widget.vehicle.vehicleReg}',
                      style: myTextStyleMediumLargeWithColor(
                          context, Theme.of(context).primaryColor, 32),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 4,
                ),
                showAllPhotos
                    ? Text(
                        'All Vehicle Photos and Videos',
                        style: myTextStyleMediumBoldWithColor(
                            context: context,
                            color: Theme.of(context).primaryColor,
                            fontSize: 16),
                      )
                    : Text(
                        'Photos and Videos taken now',
                        style: myTextStyleMediumBoldWithColor(
                            context: context,
                            color: Colors.grey.shade700,
                            fontSize: 16),
                      ),
                const SizedBox(
                  height: 12,
                ),
                Expanded(
                  child: showAllPhotos
                      ? bd.Badge(
                          onTap: () {
                            pp('$mm badge tapped ... toggle?');
                            setState(() {
                              showAllPhotos = !showAllPhotos;
                            });
                          },
                          badgeContent: Text('${vehiclePhotos.length}'),
                          badgeStyle: bd.BadgeStyle(
                            badgeColor: Colors.blue.shade700,
                            padding: const EdgeInsets.all(12.0),
                          ),
                          child: GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2),
                              itemCount: vehiclePhotos.length,
                              itemBuilder: (ctx, index) {
                                final photo = vehiclePhotos.elementAt(index);
                                return Card(
                                  elevation: 8,
                                  shape: getRoundedBorder(radius: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.network(
                                      photo.thumbNailUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              }),
                        )
                      : bd.Badge(
                          onTap: () {
                            pp('$mm badge tapped ... toggle?');
                            setState(() {
                              showAllPhotos = !showAllPhotos;
                            });
                          },
                          badgeContent: Text('${photoThumbFiles.length}'),
                          badgeStyle: bd.BadgeStyle(
                            badgeColor: Colors.red.shade700,
                            padding: const EdgeInsets.all(12.0),
                          ),
                          child: GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2),
                              itemCount: photoThumbFiles.length,
                              itemBuilder: (ctx, index) {
                                var file = photoThumbFiles.elementAt(index);
                                return Card(
                                  elevation: 8,
                                  shape: getRoundedBorder(radius: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.file(
                                      file,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              }),
                        ),
                )
              ],
            ),
          ),
          Positioned(
              bottom: 16,
              left: 20,
              right: 20,
              child: MediaChooser(
                  onPhoto: _navigateToPhotoHandler,
                  onVideo: _navigateToVideoRecorder)),
          busy
              ? const Positioned(
                  child: Center(
                  child: SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 6,
                      backgroundColor: Colors.pink,
                    ),
                  ),
                ))
              : const SizedBox(),
        ],
      ),
    ));
  }
}

class MediaChooser extends StatelessWidget {
  const MediaChooser({Key? key, required this.onPhoto, required this.onVideo})
      : super(key: key);
  final Function onPhoto;
  final Function onVideo;

  @override
  Widget build(BuildContext context) {
    var type = -1;
    return SizedBox(
      height: 120,
      width: 300,
      child: Card(
        color: Colors.black26,
        shape: getRoundedBorder(radius: 16),
        elevation: 8,
        child: Column(
          children: [
            RadioListTile(
              title: const Text("Take Photos"),
              value: 0,
              groupValue: type,
              onChanged: (value) {
                onPhoto();
              },
            ),
            RadioListTile(
              title: const Text("Make Videos"),
              value: 1,
              groupValue: type,
              onChanged: (value) {
                onVideo();
              },
            ),
          ],
        ),
      ),
    );
  }
}
