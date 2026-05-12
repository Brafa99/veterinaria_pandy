import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HistorialAdjuntosPreviewPage extends StatelessWidget {

  final String historialId;
  final Map<String, dynamic> data;

  const HistorialAdjuntosPreviewPage({
    super.key,
    required this.historialId,
    required this.data,
  });

  @override
Widget build(BuildContext context) {

  final radiografiaData =
      data["radiografias_laboratorios"] ?? {};

  /// ================= LEGACY (NO BORRAR AÚN) =================
/// Historiales antiguos todavía usan:
/// imagenes[] y links[]
/// Se mantiene por compatibilidad histórica.

final List imagenes =
    radiografiaData["imagenes"] ?? [];

final List legacyLinks =
    radiografiaData["links"] ?? [];

/// ================= NUEVA ESTRUCTURA =================

final List<Map<String, dynamic>> archivos =
    (radiografiaData["archivos"] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

final String url =
    (radiografiaData["url"] ?? "")
        .toString();

/// ================= LINKS UNIFICADOS =================

final List<String> links =
    legacyLinks
        .map((e) => e.toString())
        .toList();

  final width =
      MediaQuery.of(context).size.width;

  final isMobile = width < 700;

  return Scaffold(

    backgroundColor: const Color(0xFFF5F7FA),

    appBar: AppBar(

      elevation: 0,

      backgroundColor: const Color(0xFF0054A6),

      title: const Text(
        "Adjuntos Clínicos",
      ),

      actions: [

        IconButton(
          onPressed: () {

            /// PDF DOWNLOAD
          },

          icon: const Icon(
            Icons.download,
          ),
        ),

        IconButton(
          onPressed: () {

            /// PRINT PDF
          },

          icon: const Icon(
            Icons.print,
          ),
        ),
      ],
    ),

    body: Center(

      child: Container(

        constraints: const BoxConstraints(
          maxWidth: 1200,
        ),

        child: SingleChildScrollView(

          padding: EdgeInsets.all(
            isMobile ? 14 : 24,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              /// ================= HEADER CARD =================

              Container(

                width: double.infinity,

                padding: const EdgeInsets.all(22),

                decoration: BoxDecoration(

                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0054A6),
                      Color(0xFF0B6BC7),
                    ],
                  ),

                  borderRadius:
                      BorderRadius.circular(22),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Row(
                      children: [

                        Container(

                          padding:
                              const EdgeInsets.all(14),

                          decoration: BoxDecoration(
                            color: Colors.white
                                .withOpacity(0.14),

                            borderRadius:
                                BorderRadius.circular(16),
                          ),

                          child: const Icon(
                            Icons.pets,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [

                              Text(
                                data["nombre_mascota"] ?? "",

                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                "Propietario: ${data["nombre_dueno"] ?? ""}",

                                style: TextStyle(
                                  color: Colors.white
                                      .withOpacity(0.95),

                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    Wrap(
                      spacing: 12,
                      runSpacing: 12,

                      children: [

                        _infoBadge(
  Icons.picture_as_pdf,
  "${archivos.length} PDFs",
),

                        _infoBadge(
                          Icons.link,
                          "${links.length} enlaces",
                        ),

                        _infoBadge(
                          Icons.medical_services,
                          "Registro clínico",
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// ================= DESCRIPCIÓN =================

              Container(

                width: double.infinity,

                padding: const EdgeInsets.all(22),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(18),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    const Row(
                      children: [

                        Icon(
                          Icons.description,
                          color: Color(0xFF0054A6),
                        ),

                        SizedBox(width: 8),

                        Text(
                          "Descripción clínica",

                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Text(
                      data["descripcion"] ?? "",

                      style: const TextStyle(
                        fontSize: 15.5,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              /// ================= IMÁGENES =================

//               if (imagenes.isNotEmpty) ...[

//                 const SizedBox(height: 28),

//                 const Text(
//                   "Imágenes Adjuntas",

//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),

//                 const SizedBox(height: 18),

//                 GridView.builder(

//                   shrinkWrap: true,

//                   physics:
//                       const NeverScrollableScrollPhysics(),

//                   itemCount: imagenes.length,

//                   gridDelegate:
//                       SliverGridDelegateWithFixedCrossAxisCount(

//                     crossAxisCount:
//                         isMobile ? 1 : 3,

//                     crossAxisSpacing: 18,
//                     mainAxisSpacing: 18,

//                     childAspectRatio:
//                         isMobile ? 1.1 : 1.25,
//                   ),

//                   itemBuilder: (_, i) {

//                     final originalImg = imagenes[i];

// final img = originalImg.toString();

//                     return InkWell(

//                       borderRadius:
//                           BorderRadius.circular(18),

//                       onTap: () {

//                         showDialog(
//                           context: context,

//                           builder: (_) {

//                             return Dialog(

//                               backgroundColor:
//                                   Colors.black,

//                               insetPadding:
//                                   const EdgeInsets.all(20),

//                               child: Stack(

//                                 children: [

//                                   InteractiveViewer(
//                                     child: Image.network(
//   img,

//   fit: BoxFit.cover,

//   webHtmlElementStrategy:
//       WebHtmlElementStrategy.prefer,

//   loadingBuilder:
//       (context, child, loadingProgress) {

//     if (loadingProgress == null) {
//       return child;
//     }

//     return const Center(
//       child: CircularProgressIndicator(),
//     );
//   },

//   errorBuilder:
//       (context, error, stackTrace) {

//     debugPrint(
//       "ERROR IMAGE: $error",
//     );

//     return Container(

//       color: Colors.grey.shade200,

//       child: const Center(

//         child: Column(
//           mainAxisAlignment:
//               MainAxisAlignment.center,

//           children: [

//             Icon(
//               Icons.broken_image,
//               size: 45,
//               color: Colors.grey,
//             ),

//             SizedBox(height: 10),

//             Text(
//               "No se pudo cargar la imagen",
//             ),
//           ],
//         ),
//       ),
//     );
//   },
// )
// ),

//                                   Positioned(
//                                     right: 10,
//                                     top: 10,

//                                     child: IconButton(

//                                       onPressed: () {

//                                         Navigator.pop(context);
//                                       },

//                                       icon: const Icon(
//                                         Icons.close,
//                                         color: Colors.white,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                         );
//                       },

//                       child: Container(

//                         decoration: BoxDecoration(

//                           borderRadius:
//                               BorderRadius.circular(18),

//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black
//                                   .withOpacity(0.08),

//                               blurRadius: 10,
//                             ),
//                           ],
//                         ),

//                         child: ClipRRect(

//                           borderRadius:
//                               BorderRadius.circular(18),

//                           child: Stack(

//                             fit: StackFit.expand,

//                             children: [

//                               Image.network(
//   img,

//   fit: BoxFit.contain,

//   webHtmlElementStrategy:
//       WebHtmlElementStrategy.prefer,

//   loadingBuilder:
//       (context, child, loadingProgress) {

//     if (loadingProgress == null) {
//       return child;
//     }

//     return const Center(
//       child: CircularProgressIndicator(),
//     );
//   },

//   errorBuilder:
//       (context, error, stackTrace) {

//     debugPrint(
//       "ERROR DIALOG IMAGE: $error",
//     );

//     return const Center(

//       child: Column(
//         mainAxisAlignment:
//             MainAxisAlignment.center,

//         children: [

//           Icon(
//             Icons.broken_image,
//             color: Colors.white,
//             size: 60,
//           ),

//           SizedBox(height: 12),

//           Text(
//             "No se pudo visualizar la imagen",
//             style: TextStyle(
//               color: Colors.white,
//             ),
//           ),
//         ],
//       ),
//     );
//   },
// ),

//                               Positioned(

//                                 bottom: 0,
//                                 left: 0,
//                                 right: 0,

//                                 child: Container(

//                                   padding:
//                                       const EdgeInsets.all(10),

//                                   decoration: BoxDecoration(

//                                     gradient:
//                                         LinearGradient(

//                                       begin:
//                                           Alignment.topCenter,

//                                       end:
//                                           Alignment.bottomCenter,

//                                       colors: [
//                                         Colors.transparent,
//                                         Colors.black
//                                             .withOpacity(0.7),
//                                       ],
//                                     ),
//                                   ),

//                                   child: const Row(

//                                     children: [

//                                       Icon(
//                                         Icons.zoom_in,
//                                         color: Colors.white,
//                                         size: 18,
//                                       ),

//                                       SizedBox(width: 6),

//                                       Text(
//                                         "Ver imagen",

//                                         style: TextStyle(
//                                           color: Colors.white,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ],

/// ================= PDFs =================

if (archivos.isNotEmpty) ...[

  const SizedBox(height: 30),

  const Text(
    "Documentos PDF",

    style: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
  ),

  const SizedBox(height: 16),

  ...archivos.map((pdf) {

    final nombre =
        (pdf["nombre"] ?? "Documento PDF")
            .toString();

    final archivoUrl =
        (pdf["url"] ?? "")
            .toString();

    return Container(

      margin:
          const EdgeInsets.only(bottom: 14),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: Colors.grey.shade300,
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.04),

            blurRadius: 8,
          ),
        ],
      ),

      child: ListTile(

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),

        leading: Container(

          padding: const EdgeInsets.all(12),

          decoration: BoxDecoration(

            color: Colors.red
                .withOpacity(0.08),

            borderRadius:
                BorderRadius.circular(14),
          ),

          child: const Icon(
            Icons.picture_as_pdf,
            color: Colors.red,
            size: 30,
          ),
        ),

        title: Text(

          nombre,

          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),

        subtitle: const Padding(
          padding: EdgeInsets.only(top: 4),

          child: Text(
            "Abrir documento PDF",
          ),
        ),

        trailing: Container(

          padding: const EdgeInsets.all(8),

          decoration: BoxDecoration(

            color: const Color(0xFF0054A6)
                .withOpacity(0.08),

            borderRadius:
                BorderRadius.circular(10),
          ),

          child: const Icon(
            Icons.open_in_new,
            color: Color(0xFF0054A6),
          ),
        ),

        onTap: () async {

          final uri =
              Uri.parse(archivoUrl);

          await launchUrl(

            uri,

            mode:
                LaunchMode.platformDefault
          );
        },
      ),
    );
  }),
],

              /// ================= LINKS =================

              if (links.isNotEmpty) ...[

                const SizedBox(height: 30),

                const Text(
                  "Links Externos",

                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                ...links.map((link) {

                  return Container(

                    margin:
                        const EdgeInsets.only(bottom: 14),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(16),

                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                    ),

                    child: ListTile(

                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),

                      leading: Container(

                        padding:
                            const EdgeInsets.all(10),

                        decoration: BoxDecoration(
                          color: const Color(0xFF0054A6)
                              .withOpacity(0.08),

                          borderRadius:
                              BorderRadius.circular(12),
                        ),

                        child: const Icon(
                          Icons.link,
                          color: Color(0xFF0054A6),
                        ),
                      ),

                      title: Text(
                        link,

                        style: const TextStyle(
                          color: Colors.blue,
                          decoration:
                              TextDecoration.underline,
                        ),

                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      subtitle: const Padding(
                        padding: EdgeInsets.only(top: 4),

                        child: Text(
                          "Abrir enlace externo",
                        ),
                      ),

                      trailing: const Icon(
                        Icons.open_in_new,
                      ),

                      onTap: () async {

                        final uri =
                            Uri.parse(link);

                        await launchUrl(
                          uri,

                          mode: LaunchMode
                              .platformDefault
                        );
                      },
                    ),
                  );
                }),
              ],

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _infoBadge(
  IconData icon,
  String text,
) {

  return Container(

    padding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 10,
    ),

    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.12),

      borderRadius:
          BorderRadius.circular(12),
    ),

    child: Row(
      mainAxisSize: MainAxisSize.min,

      children: [

        Icon(
          icon,
          color: Colors.white,
          size: 18,
        ),

        const SizedBox(width: 8),

        Text(
          text,

          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

}