import 'package:flutter/material.dart';
// Realizar un ferry
// - Establecer la capacidad máxima de pasajeros.
// - Contar manualmente a las personas que van entrando o saliendo.
// - Mostrar el nivel de ocupación con un semáforo visual (verde, amarillo y rojo).
// - Registrar un historial de eventos (entradas/salidas).
void main() {
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ferry App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Iniciar directamente en el panel de control
      home: const ControlAforePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Control de Aforo del Ferry', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ControlAforePage()),
                  );
                },
                icon: const Icon(Icons.directions_boat),
                label: const Text('Abrir panel de control'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(220, 56)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ControlAforePage extends StatefulWidget {
  const ControlAforePage({super.key});

  @override
  State<ControlAforePage> createState() => _ControlAforePageState();
}

class _ControlAforePageState extends State<ControlAforePage> {
  int _currentPassengers = 0;
  int _maxCapacity = 100;
  final TextEditingController _capacityController = TextEditingController();
  bool _capacityLocked = false;
  final List<String> _eventHistory = [];

  // Centraliza la actualización del número de pasajeros.
  // delta > 0 -> entradas, delta < 0 -> salidas
  void _updatePassengers(int delta) {
    if (delta == 0) return;
    if (delta > 0) {
      final available = _maxCapacity - _currentPassengers;
      final toAdd = delta <= available ? delta : available;
      if (toAdd <= 0) return; // no hay espacio
      setState(() {
        _currentPassengers += toAdd;
        _eventHistory.insert(0, '${DateTime.now().toLocal().toIso8601String()} - Entrada +$toAdd. Total: $_currentPassengers');
      });
    } else {
      final canRemove = _currentPassengers;
      final wantRemove = -delta;
      final toRemove = wantRemove <= canRemove ? wantRemove : canRemove;
      if (toRemove <= 0) return; // no hay pasajeros
      setState(() {
        _currentPassengers -= toRemove;
        _eventHistory.insert(0, '${DateTime.now().toLocal().toIso8601String()} - Salida -$toRemove. Total: $_currentPassengers');
      });
    }
  }

  bool _canAdd(int n) => _currentPassengers + n <= _maxCapacity && n > 0;
  bool _canRemove(int n) => _currentPassengers - n >= 0 && n > 0;

  Color _getOccupancyColor() {
    double occupancyRate = _currentPassengers / _maxCapacity;
    if (occupancyRate < 0.5) {
      return Colors.green;
    } else if (occupancyRate < 0.8) {
      return Colors.yellow;
    } else {
      return Colors.red;
    }
  }

  String _occupancyLabel() {
    final rate = _currentPassengers / _maxCapacity;
    if (rate < 0.5) return 'Libre';
    if (rate < 0.8) return 'Medio';
    return 'Lleno';
  }

  void _reset() {
    setState(() {
      _currentPassengers = 0;
      _eventHistory.insert(0, '${DateTime.now().toLocal().toIso8601String()} - Reset. Total: $_currentPassengers');
    });
  }

  Future<void> _changeCapacityDialog() async {
    final controller = TextEditingController(text: '$_maxCapacity');
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cambiar capacidad máxima'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Capacidad máxima'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Introduce un número';
                final v = int.tryParse(value);
                if (v == null || v <= 0) return 'Número inválido';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final v = int.parse(controller.text);
                  Navigator.pop(context, v);
                }
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _maxCapacity = result;
        if (_currentPassengers > _maxCapacity) {
          _currentPassengers = _maxCapacity;
        }
        _eventHistory.insert(0, '${DateTime.now().toLocal().toIso8601String()} - Capacidad cambiada a $_maxCapacity');
      });
    }
  }

  @override
  void dispose() {
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ferry Control'),
        actions: [
          IconButton(onPressed: _reset, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: _capacityLocked ? null : _changeCapacityDialog,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Imagen ilustrativa redondeada
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
'https://cdn.pixabay.com/photo/2013/06/08/04/17/ferry-boat-123059_1280.jpg',
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(
                    height: 140,
                    child: Center(child: CircularProgressIndicator(value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1) : null)),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 140,
                  color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Campo para establecer capacidad y botón aplicar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _capacityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Capacidad máxima',
                      hintText: 'Ej: 100',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    enabled: !_capacityLocked,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _capacityLocked
                      ? null
                      : () {
                          final text = _capacityController.text;
                          final v = int.tryParse(text);
                          if (v == null || v <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Introduce un número válido (>0)')));
                            return;
                          }
                          setState(() {
                            _maxCapacity = v;
                            if (_currentPassengers > _maxCapacity) _currentPassengers = _maxCapacity;
                            _capacityLocked = true;
                            _eventHistory.insert(0, '${DateTime.now().toLocal().toIso8601String()} - Capacidad fijada a $_maxCapacity');
                          });
                        },
                  child: const Text('Aplicar'),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pasajeros: $_currentPassengers / $_maxCapacity', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinearProgressIndicator(
                          value: _maxCapacity == 0 ? 0 : _currentPassengers / _maxCapacity,
                          minHeight: 12,
                          color: _getOccupancyColor(),
                          backgroundColor: Colors.grey.shade300,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Estado: ${_occupancyLabel()}', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      // Botonera: entradas +1 +2 +5
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.blue.shade50,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed: _canAdd(1) ? () => _updatePassengers(1) : null,
                                    child: const Text('+1'),
                                  ),
                                  ElevatedButton(
                                    onPressed: _canAdd(2) ? () => _updatePassengers(2) : null,
                                    child: const Text('+2'),
                                  ),
                                  ElevatedButton(
                                    onPressed: _canAdd(5) ? () => _updatePassengers(5) : null,
                                    child: const Text('+5'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red),
                                    onPressed: _canRemove(1) ? () => _updatePassengers(-1) : null,
                                    child: const Text('-1'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red),
                                    onPressed: _canRemove(2) ? () => _updatePassengers(-2) : null,
                                    child: const Text('-2'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red),
                                    onPressed: _canRemove(5) ? () => _updatePassengers(-5) : null,
                                    child: const Text('-5'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Semaforo visual
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TrafficLight(color: Colors.green, active: _getOccupancyColor() == Colors.green, label: 'Bajo'),
                      const SizedBox(height: 8),
                      _TrafficLight(color: Colors.yellow, active: _getOccupancyColor() == Colors.yellow, label: 'Medio'),
                      const SizedBox(height: 8),
                      _TrafficLight(color: Colors.red, active: _getOccupancyColor() == Colors.red, label: 'Alto'),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            // Encabezado del historial con contador y botón para limpiar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Historial de eventos (${_eventHistory.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _eventHistory.isEmpty
                      ? null
                      : () {
                          setState(() {
                            _eventHistory.clear();
                          });
                        },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Borrar historial'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Card(
                  elevation: 2,
                  margin: EdgeInsets.zero,
                  child: _eventHistory.isEmpty
                      ? const Center(child: Text('Sin eventos aún'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(8),
                          itemCount: _eventHistory.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: const Icon(Icons.event_note),
                              title: Text(_eventHistory[index], style: const TextStyle(fontSize: 14)),
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrafficLight extends StatelessWidget {
  const _TrafficLight({required this.color, required this.active, required this.label});
  final Color color;
  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: active ? 56 : 40,
          height: active ? 56 : 40,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: active ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 8, spreadRadius: 1)] : []),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

