import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const SubnetCalculatorApp());
}

class SubnetCalculatorApp extends StatelessWidget {
  const SubnetCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora de Subredes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const SubnetCalculatorHome(title: 'Calculadora de Subredes'),
    );
  }
}

class SubnetCalculatorHome extends StatefulWidget {
  const SubnetCalculatorHome({super.key, required this.title});
  final String title;

  @override
  State<SubnetCalculatorHome> createState() => _SubnetCalculatorHomeState();
}

class _SubnetCalculatorHomeState extends State<SubnetCalculatorHome> {
  // TextEditingController para la dirección IP.
  final TextEditingController _ipController = TextEditingController(
    text: "181.196.12.51",
  );

  // Lista de máscaras disponibles para seleccionar (representadas en número de bits)
  final List<int> _maskOptions = [8, 16, 24];
  int _selectedMask = 16; // valor por defecto

  // Lista de botones para la cantidad de subredes (se llenará dinámicamente)
  List<int> _subnetOptions = [];
  int? _selectedSubnets; // número de subredes escogido

  // Resultado del cálculo en forma de String
  String _resultado = "";

  /// Función auxiliar: convierte un octeto a binario con 8 dígitos
  String _toBinary(int octet) => octet.toRadixString(2).padLeft(8, '0');

  /// Función auxiliar: convierte un octeto a hexadecimal con 2 dígitos
  String _toHex(int octet) =>
      octet.toRadixString(16).padLeft(2, '0').toUpperCase();

  /// Calcula la cantidad de bits disponibles para el subneteo a partir de la máscara principal.
  int get availableBits => 32 - _selectedMask;

  /// Genera opciones de subredes en forma de potencias de 2 (p.ej. 2, 4, 8, ...) siempre
  /// que no se supere el límite dado por [availableBits].
  void _generateSubnetOptions() {
    _subnetOptions.clear();
    // Es decir, el número máximo de subredes es 2^(availableBits).
    int maxSubnets = 1 << availableBits;
    // Generamos opciones desde 2^1 hasta 2^(availableBits) (podrías filtrar solo algunas si lo deseas)
    for (int bits = 1; bits <= availableBits; bits++) {
      int n = 1 << bits;
      if (n <= maxSubnets) {
        _subnetOptions.add(n);
      }
    }
    // Resetear el seleccionado
    _selectedSubnets = _subnetOptions.isNotEmpty ? _subnetOptions.first : null;
  }

  /// Método que realiza el cálculo de subredes:
  /// Se valida que el número de bits adicionales (k) para obtener el número de subredes
  /// requerido no supere los bits disponibles.
  void _calcularSubredes() {
    String ipInput = _ipController.text.trim();
    List<String> partes = ipInput.split(".");
    if (partes.length != 4) {
      setState(() {
        _resultado = "La dirección IP debe contener 4 octetos.";
      });
      return;
    }

    try {
      List<int> octetos = partes.map((p) => int.parse(p)).toList();
      if (octetos.any((o) => o < 0 || o > 255)) {
        setState(() {
          _resultado = "Cada octeto debe estar entre 0 y 255.";
        });
        return;
      }

      // Convertir la IP a un entero de 32 bits
      int ipValue =
          (octetos[0] << 24) |
          (octetos[1] << 16) |
          (octetos[2] << 8) |
          octetos[3];

      // Validación: se usa la cantidad de subredes seleccionada
      if (_selectedSubnets == null) {
        setState(() {
          _resultado = "Por favor selecciona la cantidad de subredes.";
        });
        return;
      }

      // Se calcula la cantidad de bits necesarios para el número de subredes
      int k = (log(_selectedSubnets!) / log(2)).ceil();
      // Validamos que se disponga de suficientes bits para el subneteo
      if (k > availableBits) {
        setState(() {
          _resultado =
              "No es posible dividir en $_selectedSubnets subredes, ya que se requieren $k bits, pero solo hay $availableBits disponibles.";
        });
        return;
      }

      // Nueva máscara para cada subred
      int newMaskBits = _selectedMask + k;
      if (newMaskBits > 32) {
        setState(() {
          _resultado =
              "El resultado excede el límite de 32 bits (nueva máscara: $newMaskBits).";
        });
        return;
      }
      int newMask = 0xFFFFFFFF << (32 - newMaskBits) & 0xFFFFFFFF;
      String newMaskStr =
          "${(newMask >> 24) & 0xFF}.${(newMask >> 16) & 0xFF}.${(newMask >> 8) & 0xFF}.${newMask & 0xFF}";

      // Tamaño de cada subred (número de direcciones)
      int subnetSize = 1 << (32 - newMaskBits);
      int hostsPerSubnet = subnetSize - 2; // sin contar red y broadcast

      // Calculamos la dirección de red principal (a partir de la máscara principal)
      int mainMask = 0xFFFFFFFF << (32 - _selectedMask) & 0xFFFFFFFF;
      int networkBase = ipValue & mainMask;

      // Construir el resultado para cada subred
      StringBuffer buffer = StringBuffer();
      buffer.writeln("IP principal: $ipInput");
      buffer.writeln(
        "Máscara principal (/$_selectedMask): "
        "${(mainMask >> 24) & 0xFF}.${(mainMask >> 16) & 0xFF}.${(mainMask >> 8) & 0xFF}.${mainMask & 0xFF}",
      );
      buffer.writeln(
        "División en $_selectedSubnets subredes usando $k bits adicionales.",
      );
      buffer.writeln("Nueva máscara: $newMaskStr (/ $newMaskBits)");
      buffer.writeln(
        "Tamaño de cada subred: $subnetSize direcciones, $hostsPerSubnet hosts válidos\n",
      );

      for (int i = 0; i < _selectedSubnets!; i++) {
        int subnetNetwork = networkBase + (i * subnetSize);
        int subnetBroadcast = subnetNetwork + subnetSize - 1;

        // Convertir a notación decimal
        String red =
            "${(subnetNetwork >> 24) & 0xFF}."
            "${(subnetNetwork >> 16) & 0xFF}."
            "${(subnetNetwork >> 8) & 0xFF}."
            "${subnetNetwork & 0xFF}";
        String broadcast =
            "${(subnetBroadcast >> 24) & 0xFF}."
            "${(subnetBroadcast >> 16) & 0xFF}."
            "${(subnetBroadcast >> 8) & 0xFF}."
            "${subnetBroadcast & 0xFF}";

        buffer.writeln("Subred ${i + 1}:");
        buffer.writeln("  Red: $red / $newMaskBits");
        buffer.writeln("  Broadcast: $broadcast");
        buffer.writeln("  Hosts válidos: $hostsPerSubnet\n");
      }

      setState(() {
        _resultado = buffer.toString();
      });
    } catch (e) {
      setState(() {
        _resultado = "Error al procesar la entrada: $e";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _generateSubnetOptions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sección para ingresar la dirección IP
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: "Dirección IP",
                hintText: "Ej: 181.196.12.51",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.computer),
              ),
            ),
            const SizedBox(height: 16),
            // Selección de la máscara principal mediante un DropdownButton
            Row(
              children: [
                const Text("Máscara principal:  /"),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _selectedMask,
                  items:
                      _maskOptions
                          .map(
                            (mask) => DropdownMenuItem(
                              value: mask,
                              child: Text(mask.toString()),
                            ),
                          )
                          .toList(),
                  onChanged: (nuevoMask) {
                    if (nuevoMask != null) {
                      setState(() {
                        _selectedMask = nuevoMask;
                        _generateSubnetOptions(); // actualizamos las opciones disponibles
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Botones dinámicos para seleccionar la cantidad de subredes
            Text(
              "Selecciona la cantidad de subredes:",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  _subnetOptions
                      .map(
                        (subn) => ChoiceChip(
                          label: Text(subn.toString()),
                          selected: _selectedSubnets == subn,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedSubnets = subn;
                              });
                            }
                          },
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 24),
            // Botón para calcular
            ElevatedButton.icon(
              onPressed: _calcularSubredes,
              icon: const Icon(Icons.calculate),
              label: const Text("Calcular Subredes"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 20,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Sección para mostrar el resultado
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _resultado.isNotEmpty
                      ? _resultado
                      : "Selecciona y confirma los parámetros, luego presiona Calcular Subredes.",
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Indicamos la URL del repositorio GIT (ficticio en este ejemplo)
            Center(
              child: GestureDetector(
                onTap: () {
                  // Aquí podrías abrir la URL usando un paquete como url_launcher
                },
                child: Text(
                  "Repositorio GIT: https://github.com/RELIC7663/Calculadora_VLSM.git",
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.deepPurple.shade600,
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
