import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/estacion.dart';

void main() => runApp(const SMATApp());

class SMATApp extends StatelessWidget {
  const SMATApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Estacion>> futureEstaciones;

  @override
  void initState() {
    super.initState();
    futureEstaciones = ApiService().fetchEstaciones();
  }

  void refresh() {
    setState(() {
      futureEstaciones = ApiService().fetchEstaciones();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SMAT - Monitoreo')),

      body: FutureBuilder<List<Estacion>>(
        future: futureEstaciones,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('❌ Error de conexión'));
          } else {
            final data = snapshot.data!;
            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, i) {
                final est = data[i];
                return ListTile(
                  leading: const Icon(Icons.satellite_alt),
                  title: Text(est.nombre),
                  subtitle: Text(est.ubicacion),
                );
              },
            );
          }
        },
      ),

      // boton de labo
      floatingActionButton: FloatingActionButton(
        onPressed: refresh,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
