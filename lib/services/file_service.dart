import 'dart:typed_data';

import 'file_service_stub.dart'
    if (dart.library.html) 'filer_service_web.dart';

class FileService {
  static Future<void> saveOrDownload(
    Uint8List bytes,
    String filename,
  ) {
    return FileServiceImpl.saveOrDownload(bytes, filename);
  }
}