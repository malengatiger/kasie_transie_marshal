import 'dart:async';

import 'package:kasie_transie_library/data/schemas.dart';
final DispatchHelper dispatchHelper = DispatchHelper();

class DispatchHelper {
  final StreamController<DispatchRecord> _streamController = StreamController.broadcast();
  Stream<DispatchRecord> get dispatchStream => _streamController.stream;

  void sendDispatch(DispatchRecord dispatchRecord) {
    _streamController.sink.add(dispatchRecord);
  }
}
