import 'package:flutter/material.dart';
import 'package:veterinaria_pandy/dashboard/dashboard_controller.dart';
import 'package:veterinaria_pandy/dashboard/widgets/routes.dart';

class Sidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onSelect;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool usuariosOpen = false;
  bool clienteOpen = false;
  bool reportesOpen = false;
  bool ventasOpen = false;
  bool configOpen = false;
  bool ingresosOpen = false;
  bool dbOpen = false;

  // Definición de colores corporativos para fácil mantenimiento
  final Color azulPandy = const Color(0xFF0054A6);
  final Color azulActivoTexto = const Color(0xFF64B5F6); // Azul cielo suave (excelente contraste)
  final Color fondoSidebar = const Color(0xFF131921);   // Fondo oscuro premium para que resalte el azul

  void _handleNavigation(int index) {
    widget.onSelect(index);

    // 🔥 cerrar drawer SOLO si es móvil
    if (MediaQuery.of(context).size.width < 800) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1100;

    double sidebarWidth;

    if (isMobile) {
      sidebarWidth = 240; // 📱 compacto
    } else if (isTablet) {
      sidebarWidth = 260; // 📲 intermedio
    } else {
      sidebarWidth = 270; // 💻 completo
    }

    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: fondoSidebar, // 🔥 Añadido fondo oscuro para unificar el diseño
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF16161F),
            blurRadius: 5, // Un poco más difuminado para suavizar los bordes
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(height: isMobile ? 20 : 40),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: azulPandy, width: 2.5), // 🔥 Ajustado con el color corporativo
                ),
                child: CircleAvatar(
                  radius: isMobile ? 34 : 42,
                  backgroundImage: const AssetImage("assets/img/pandy.jpeg"),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Administración",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 13 : 16,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Veterinaria Pandy",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: isMobile ? 11 : 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(
            color: Colors.white10, // Más sutil para no "cortar" el diseño agresivamente
            thickness: 1,
            indent: 20,
            endIndent: 20,
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(), // Scroll más agradable visualmente
              children: [
                _item(Icons.home_rounded, "Inicio", 0), // Iconos redondeados lucen más modernos

                /// ================= USUARIOS =================
                _expandable(
                  icon: Icons.people_rounded,
                  title: "Usuarios",
                  open: usuariosOpen,
                  onTap: () => setState(() => usuariosOpen = !usuariosOpen),
                  children: [
                    _subItem("Lista usuarios", 1),
                    _subItem("Agregar usuario", 2),
                  ],
                ),

                /// ================= CLIENTES =================
                _expandable(
                  icon: Icons.pets_rounded,
                  title: "Mascota / Cliente",
                  open: clienteOpen,
                  onTap: () => setState(() => clienteOpen = !clienteOpen),
                  children: [
                    _subItem("Lista clientes", 4),
                    _subItem("Agregar cliente", 5),
                  ],
                ),

                _item(Icons.shopping_bag_rounded, "Productos", 7),
                _item(Icons.history_rounded, "Historial", 8),
                _item(Icons.point_of_sale_rounded, "Ventas POS", 12),

                /// ================= REPORTES HISTORIAL =================
                _expandable(
                  icon: Icons.bar_chart_rounded,
                  title: "Reportes Historial",
                  open: reportesOpen,
                  onTap: () => setState(() => reportesOpen = !reportesOpen),
                  children: [
                    _subItem("Entre fechas", 16),
                    _subItem("Por día", 15),
                    _subItem("Por mes", 14),
                    _subItem("Últimos 7 días", 13),
                  ],
                ),

                /// ================= REPORTES VENTAS =================
                _expandable(
                  icon: Icons.analytics_rounded,
                  title: "Reportes Ventas",
                  open: ventasOpen,
                  onTap: () => setState(() => ventasOpen = !ventasOpen),
                  children: [
                    _subItem("Entre fechas", 20),
                    _subItem("Por día", 19),
                    _subItem("Por mes", 18),
                    _subItem("Últimos 7 días", 17),
                  ],
                ),

                /// ================= INGRESOS / EGRESOS =================
                _expandable(
                  icon: Icons.calculate_rounded,
                  title: "Ingresos/Egresos",
                  open: ingresosOpen,
                  onTap: () => setState(() => ingresosOpen = !ingresosOpen),
                  children: [
                    _subItem("Entre fechas", 24),
                    _subItem("Por día", 23),
                    _subItem("Por mes", 22),
                    _subItem("Últimos 7 días", 21),
                  ],
                ),

                /// ================= CONFIG =================
                _expandable(
                  icon: Icons.settings_rounded,
                  title: "Configuración",
                  open: configOpen,
                  onTap: () => setState(() => configOpen = !configOpen),
                  children: [
                    _subItem("Cambiar contraseña", 25),
                    _subItem("Empresa", 26),
                    _subItem("Frontend", 27),
                    _subItem("Galería", 28),
                  ],
                ),

                /// ================= DB =================
                _expandable(
                  icon: Icons.storage_rounded,
                  title: "Base de datos",
                  open: dbOpen,
                  onTap: () => setState(() => dbOpen = !dbOpen),
                  children: [
                    _subItem("Vaciar base de datos", 29),
                    _subItem("Respaldo", 30),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String title, int index) {
    final active = widget.selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        // 🔥 Reemplazado Cyan con Azul Pandy al 15% de opacidad para el fondo activo
        color: active ? azulPandy.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Icon(
          icon,
          // 🔥 Texto activo pasa a un azul claro súper elegante, inactivo blanco70
          color: active ? azulActivoTexto : Colors.white70,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: active ? Colors.white : Colors.white70, // Resalta en blanco cuando está seleccionado
            fontWeight: active ? FontWeight.w200 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: () => _handleNavigation(index),
      ),
    );
  }

  Widget _subItem(String title, int index) {
    final active = widget.selectedIndex == index;

    return InkWell(
      onTap: () => _handleNavigation(index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(left: 24, right: 12, top: 2, bottom: 2),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          // 🔥 Fondo sutil para el sub-ítem seleccionado
          color: active ? azulPandy.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.circle,
              size: 6,
              // 🔥 El indicador circular ahora se enciende en azul corporativo brillante
              color: active ? azulActivoTexto : Colors.white30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white54,
                  fontWeight: active ? FontWeight.w200 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= EXPANDABLE =================
  Widget _expandable({
    required IconData icon,
    required String title,
    required bool open,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            leading: Icon(icon, color: Colors.white70, size: 22),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white70, 
                fontSize: 14,
              ),
            ),
            trailing: Icon(
              open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: Colors.white38,
            ),
            onTap: onTap,
          ),
        ),
        if (open) ...children,
      ],
    );
  }
}