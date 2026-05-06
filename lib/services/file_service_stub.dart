import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileServiceImpl {
  static Future<void> saveOrDownload(
    Uint8List bytes,
    String filename,
  ) async {

    final dir = await getExternalStorageDirectory();

    final path = '${dir!.path}/$filename';

    final file = File(path);

    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles([XFile(path)]);
  }
}