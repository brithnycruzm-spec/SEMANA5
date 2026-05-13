import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/estacion.dart';
import 'login_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});


  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
late Future<List<Estacion>> futureEstaciones;
  // Dentro de class _HomePageState extends State<HomePage>

void _mostrarDialogoEdicion(Estacion estacion) {
  final nombreCtrl = TextEditingController(text: estacion.nombre);
  final ubicacionCtrl = TextEditingController(text: estacion.ubicacion);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Editar Estación"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nombreCtrl, 
            decoration: const InputDecoration(labelText: "Nombre")
          ),
          TextField(
            controller: ubicacionCtrl, 
            decoration: const InputDecoration(labelText: "Ubicación")
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text("Cancelar")
        ),
        ElevatedButton(
          onPressed: () async {
            // Importante: Asegúrate de que 'apiService' esté instanciado en tu clase
            bool ok = await ApiService().editarEstacion(
              estacion.id, 
              nombreCtrl.text, 
              ubicacionCtrl.text
            );
            
            if (ok) {
              Navigator.pop(context);
              setState(() {
                futureEstaciones = ApiService().fetchEstaciones();
              }); 
            }
          }, 
          child: const Text("Guardar"),
        ),
      ],
    ),
  );
}

  final ApiService apiService = ApiService();

  List<Estacion> estaciones = [];

  @override
  void initState() {
    super.initState();
    cargarEstaciones();
  }

  Future<void> cargarEstaciones() async {

    final data = await apiService.fetchEstaciones();

    setState(() {
      estaciones = data;
    });
  }

  // FUTURO: editar estación
  void _mostrarDialogo1Edicion(Estacion estacion) {

    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(

          title: const Text('Editar estación'),

          content: Text(
            'Aquí irá la edición de ${estacion.nombre}',
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text('Estaciones SMAT'),

        actions: [

          IconButton(

            icon: const Icon(Icons.logout),

            onPressed: () async {

              // Eliminar token
              await AuthService().logout();

              // Reiniciar navegación
              Navigator.pushAndRemoveUntil(

                context,

                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),

                (route) => false,
              );
            },
          ),
        ],
      ),

      body: ListView.builder(

        itemCount: estaciones.length,

        itemBuilder: (context, index) {

          final estacion = estaciones[index];

          return Dismissible(

            key: Key(estacion.id.toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),

            onDismissed: (direction) async {

              bool ok = await apiService.eliminarEstacion(
                estacion.id,
              );
              if (ok) {
                setState(() {
                  estaciones.removeAt(index);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "${estacion.nombre} eliminada",
                    ),
                  ),
                );
              }
            },
            child: ListTile(
              title: Text(estacion.nombre),
              subtitle: Text(estacion.ubicacion),
              onTap: () =>
                  _mostrarDialogoEdicion(estacion),
            ),
          );
        },
      ),
    );
  }
}