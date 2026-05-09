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

  final List imagenes =
      radiografiaData["imagenes"] ?? [];

  final List links =
      radiografiaData["links"] ?? [];

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
                          Icons.image,
                          "${imagenes.length} imágenes",
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

              if (imagenes.isNotEmpty) ...[

                const SizedBox(height: 28),

                const Text(
                  "Imágenes Adjuntas",

                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 18),

                GridView.builder(

                  shrinkWrap: true,

                  physics:
                      const NeverScrollableScrollPhysics(),

                  itemCount: imagenes.length,

                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(

                    crossAxisCount:
                        isMobile ? 1 : 3,

                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,

                    childAspectRatio:
                        isMobile ? 1.1 : 1.25,
                  ),

                  itemBuilder: (_, i) {

                    final img = imagenes[i];

                    return InkWell(

                      borderRadius:
                          BorderRadius.circular(18),

                      onTap: () {

                        showDialog(
                          context: context,

                          builder: (_) {

                            return Dialog(

                              backgroundColor:
                                  Colors.black,

                              insetPadding:
                                  const EdgeInsets.all(20),

                              child: Stack(

                                children: [

                                  InteractiveViewer(
                                    child: Image.network(
                                      img,
                                      fit: BoxFit.contain,
                                    ),
                                  ),

                                  Positioned(
                                    right: 10,
                                    top: 10,

                                    child: IconButton(

                                      onPressed: () {

                                        Navigator.pop(context);
                                      },

                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },

                      child: Container(

                        decoration: BoxDecoration(

                          borderRadius:
                              BorderRadius.circular(18),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(0.08),

                              blurRadius: 10,
                            ),
                          ],
                        ),

                        child: ClipRRect(

                          borderRadius:
                              BorderRadius.circular(18),

                          child: Stack(

                            fit: StackFit.expand,

                            children: [

                              Image.network(
                                img,
                                fit: BoxFit.cover,
                              ),

                              Positioned(

                                bottom: 0,
                                left: 0,
                                right: 0,

                                child: Container(

                                  padding:
                                      const EdgeInsets.all(10),

                                  decoration: BoxDecoration(

                                    gradient:
                                        LinearGradient(

                                      begin:
                                          Alignment.topCenter,

                                      end:
                                          Alignment.bottomCenter,

                                      colors: [
                                        Colors.transparent,
                                        Colors.black
                                            .withOpacity(0.7),
                                      ],
                                    ),
                                  ),

                                  child: const Row(

                                    children: [

                                      Icon(
                                        Icons.zoom_in,
                                        color: Colors.white,
                                        size: 18,
                                      ),

                                      SizedBox(width: 6),

                                      Text(
                                        "Ver imagen",

                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
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
                              .externalApplication,
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