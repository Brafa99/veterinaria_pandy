import 'dart:typed_data';

import 'package:veterinaria_pandy/services/filer_service_web.dart';

class FileService {
  static Future<void> saveOrDownload(
    Uint8List bytes,
    String filename,
  ) {
    return FileServiceImpl.saveOrDownload(bytes, filename);
  }
}