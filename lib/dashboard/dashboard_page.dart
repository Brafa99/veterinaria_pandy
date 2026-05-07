import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veterinaria_pandy/clients/client_form_view.dart';
import 'package:veterinaria_pandy/clients/clients_page.dart';
import 'package:veterinaria_pandy/configuracion/cambiar_password_view.dart';
import 'package:veterinaria_pandy/configuracion/empresa_view.dart';
import 'package:veterinaria_pandy/configuracion/frontend_view.dart';
import 'package:veterinaria_pandy/configuracion/galeria_frontend.dart';
import 'package:veterinaria_pandy/dashboard/dashboard_controller.dart';
import 'package:veterinaria_pandy/database/backup_database_page.dart';
import 'package:veterinaria_pandy/database/empty_database_page.dart';
import 'package:veterinaria_pandy/finanzas/finanzas_7_dias.dart';
import 'package:veterinaria_pandy/finanzas/finanzas_dia.dart';
import 'package:veterinaria_pandy/finanzas/finanzas_mes.dart';
import 'package:veterinaria_pandy/finanzas/finanzas_rango.dart';
import 'package:veterinaria_pandy/historial/historial_create_page.dart';
import 'package:veterinaria_pandy/historial/historial_detail_page.dart';
import 'package:veterinaria_pandy/historial/historial_form_page.dart';
import 'package:veterinaria_pandy/historial/historial_page.dart';
import 'package:veterinaria_pandy/login/login_page.dart';
import 'package:veterinaria_pandy/products/products_form_page.dart';
import 'package:veterinaria_pandy/products/products_page.dart';
import 'package:veterinaria_pandy/reportes/reportes_historial/reportes_dates_.dart';
import 'package:veterinaria_pandy/reportes/reportes_historial/reportes_day_page.dart';
import 'package:veterinaria_pandy/reportes/reportes_historial/reportes_months_page.dart';
import 'package:veterinaria_pandy/reportes/reportes_historial/reportes_page_7_days.dart';
import 'package:veterinaria_pandy/reportes/reportes_ventas/reportes_day_page.dart';
import 'package:veterinaria_pandy/reportes/reportes_ventas/reportes_months_page.dart';
import 'package:veterinaria_pandy/reportes/reportes_ventas/reportes_page_7_days.dart';
import 'package:veterinaria_pandy/reportes/reportes_ventas/reportes_range_page.dart';
import 'package:veterinaria_pandy/usuarios/usuarios_form_page.dart';
import 'package:veterinaria_pandy/usuarios/usuarios_page.dart';
import 'package:veterinaria_pandy/ventas_pos/pos_page.dart';
import 'widgets/sidebar.dart';
import 'widgets/stat_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedIndex = 0;

  List<Widget> get pages => [

  const HomeDashboard(), // 0

  const UsuariosPage(), // 1
  UsuarioFormPage(userId: null), // 2
  UsuarioFormPage(userId: DashboardController.editingUserId), // 3

  const ClientesPage(), // 4
  ClienteFormPage(clienteId: null), // 5
  ClienteFormPage(clienteId: DashboardController.editingClienteId), // 6

  const ProductosPage(), // 7

  const HistorialPage(), // 8
  HistorialDetailPage(data: DashboardController.selectedHistorial ?? {}), // 9
  HistorialCreatePage(), // 10
  HistorialFormPage(historialId: DashboardController.editingHistorialId ?? ""), // 11

  const PosPage(), // 12

  /// ================= HISTORIAL REPORTES =================
  const HistorialReportesLast7DaysPage(), // 13
  const HistorialReportesMonthPage(),     // 14
  const HistorialReportesDayPage(),       // 15
  const HistorialReportesRangePage(),     // 16

  /// ================= VENTAS REPORTES =================
  const VentasReportesLast7DaysPage(), // 17
  const VentasReportesMonthPage(),     // 18
  const VentasReportesDayPage(),       // 19
  const VentasReportesRangePage(),     // 20

  /// ================= INGRESOS/EGRESOS =================
  const FinanzasLast7DaysPage(),       // 21
  const IngresosEgresosMonthPage(), // 22
  const IngresosEgresosDayPage(),   // 23
  const IngresosEgresosRangePage(), // 24

  /// ================= CONFIG =================
  const CambiarPasswordView(), // 22
  const EmpresaView(),         // 23
  const FrontendView(),        // 24
  const GaleriaView(),         // 25

  /// ================= DB =================
  const DatabaseEmptyPage(),   // 26
  const DatabaseBackupPage(),  // 27

  //ProductoFormPage() //28

];

  @override
void initState() {
  super.initState();

  DashboardController.selectedIndex.addListener(() {
  setState(() {
    selectedIndex = DashboardController.selectedIndex.value;
  });
});
}

Future<void> _logout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool("rememberMe", false);

  await FirebaseAuth.instance.signOut();

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (route) => false,
  );
}

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      drawer: isMobile
          ? Sidebar(
  selectedIndex: selectedIndex,
  onSelect: (i) {
    DashboardController.goTo(i);
  },
)
          : null,

      body: Row(
        children: [
          // 🔥 SIDEBAR FIJO SOLO EN DESKTOP
          if (!isMobile)
            Sidebar(
  selectedIndex: selectedIndex,
  onSelect: (i) {
    DashboardController.goTo(i);
  },
),

          // 🔥 SOLO CAMBIA ESTE BODY
          Expanded(
            child: Column(
              children: [
                _topBar(isMobile),
                Expanded(
  child: KeyedSubtree(
    key: ValueKey(selectedIndex),
    child: pages[selectedIndex],
  ),
),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(bool isMobile) {
  final user = FirebaseAuth.instance.currentUser;

  return Container(
    
  height: 65,
  padding: const EdgeInsets.symmetric(horizontal: 20),
  decoration: BoxDecoration(
    boxShadow: [
      BoxShadow(
        color: Color(0xFF16161F),
        blurRadius: 2,
        offset: Offset(2, 0),
      ),
    ],
    color: const Color(0xFFF0F2F5),
    border: Border(
      bottom: BorderSide(
        color: Colors.black.withOpacity(0.08),
        width: 1,
      ),
    ),
  ),

  
    child: Row(
      children: [
        if (isMobile)
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black87),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
  Text(
    "Sistema Veterinaria Pandy",
    style: TextStyle(
  fontSize: isMobile ? 15 : 20,
  fontWeight: FontWeight.bold,
  color: Colors.black87,
),
  ),
        const Spacer(),

        // ================= USER DROPDOWN =================
        PopupMenuButton<String>(
          
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          onSelected: (value) {
            if (value == "logout") {
              _logout(context);
            }
          },

          itemBuilder: (context) => [
            const PopupMenuItem(
              value: "logout",
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18),
                  SizedBox(width: 8),
                  Text("Cerrar sesión"),
                ],
              ),
            ),
          ],

          child: Row(
            children: [
              // 🔥 AVATAR
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.person, size: 18),
              ),

              const SizedBox(width: 8),

              // 🔥 TEXTO (RESPONSIVE)
              if (!isMobile)
                Text(
                  user?.email ?? "admin",
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),

              const SizedBox(width: 4),

              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ],
    ),
  );
}
}

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // 🔥 BREAKPOINTS PRO
    int crossAxisCount;
    if (width < 600) {
      crossAxisCount = 2; // móvil
    } else if (width < 1100) {
      crossAxisCount = 3; // tablet
    } else {
      crossAxisCount = 4; // desktop
    }

    void go(int index) {
      DashboardController.goTo(index);

      // 🔥 CERRAR SIDEBAR AUTOMÁTICAMENTE EN MÓVIL
      if (Scaffold.of(context).isDrawerOpen) {
        Navigator.pop(context);
      }
    }

    final cards = [

      /// 🔵 CLIENTES (antes usuarios)
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("usuarios")
            .snapshots(),
        builder: (context, snapshot) {
          final total = snapshot.data?.docs.length ?? 0;

          return StatCard(
            title: "Clientes",
            count: total,
            color: Colors.black,
            image: "assets/img/comittee.png",
            onTap: () => go(4),
          );
        },
      ),

      /// 🔴 HISTORIAL
      StatCard(
        title: "Historial",
        count: 0,
        color: Colors.red,
        image: "assets/img/fair.png",
        onTap: () => go(8),
      ),

      /// 🔵 PRODUCTOS
      StatCard(
        title: "Productos",
        count: 0,
        color: Colors.blue,
        image: "assets/img/productos.png",
        onTap: () => go(7),
      ),

      /// 🟢 INGRESOS / EGRESOS
      StatCard(
        title: "Ingresos/Egresos",
        count: 0,
        color: Colors.green,
        image: "assets/img/cajero.png",
        onTap: () => go(21), // tu índice de finanzas 7 días
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: cards.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              childAspectRatio: width < 600 ? 0.9 : 1.05, // 🔥 clave móvil
            ),
            itemBuilder: (_, i) => cards[i],
          );
        },
      ),
    );
  }
}