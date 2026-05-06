import 'dart:typed_data';
import 'dart:html' as html;

class FileServiceImpl {
  static Future<void> saveOrDownload(
    Uint8List bytes,
    String filename,
  ) async {

    final blob = html.Blob([bytes]);

    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute("download", filename)
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}