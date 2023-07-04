import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_marshal/ui/dashboard.dart';

class StarterPack extends StatefulWidget {
  const StarterPack({Key? key}) : super(key: key);

  @override
  StarterPackState createState() => StarterPackState();
}

class StarterPackState extends State<StarterPack> {


  @override
  void initState() {
    super.initState();
    _start();

  }

  void _start() async {
    var creds = await FirebaseAuth.instance.signInAnonymously();

    Future.delayed(const Duration(seconds: 10), () async {
      if (mounted) {
        // Navigator.of(context).pop();
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Scaffold(
      appBar: AppBar(
        title: const Text('Starter Pack'),
      ),
      body: Center(
        child: ElevatedButton(onPressed: (){
          navigateWithScale(const Dashboard(), context);

        }, child: Text('Navigate'),),
      ),
    ));
  }
}
