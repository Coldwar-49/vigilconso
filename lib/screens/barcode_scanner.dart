import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _BarcodeScannerPageState createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage>
    with WidgetsBindingObserver {
  String _scanResult = 'Scannez un code-barres pour vérifier les rappels';
  bool _isLoading = false;
  late MobileScannerController _controller;
  String? _lastScannedBarcode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.normal,
      formats: [
        BarcodeFormat.ean8,
        BarcodeFormat.ean13,
        BarcodeFormat.qrCode,
      ],
      facing: CameraFacing.back,
    );
    _requestCameraPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.start();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller.stop();
    }
  }

  Future<void> _requestCameraPermission() async {
    // Vérifier la permission de la caméra au démarrage
    var status = await Permission.camera.status;
    if (status.isDenied) {
      // Demander la permission
      await Permission.camera.request();
    }
  }

  Future<void> _scanBarcode() async {
    // Vérifier à nouveau la permission de la caméra
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      // Demander la permission si elle n'est pas accordée
      status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _scanResult =
              'Permission de la caméra refusée. Veuillez activer la caméra dans les paramètres de l\'application.';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _scanResult = 'Scan en cours...';
    });

    try {
      // Démarrer le scanner et ouvrir un nouvel écran de scan
      await _controller.start();

      if (!mounted) return;
      final result = await Navigator.push<String?>(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Scanner le code-barres'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context, null),
              ),
            ),
            body: MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                final barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                  Navigator.pop(context, barcodes.first.rawValue);
                }
              },
            ),
          ),
        ),
      );

      // Arrêter le scanner quand on quitte l'écran de scan
      await _controller.stop();

      // Gérer le cas où l'utilisateur annule le scan
      if (result == null) {
        setState(() {
          _scanResult = 'Scan annulé';
          _isLoading = false;
        });
        return;
      }

      _lastScannedBarcode = result;

      // Vérifier le rappel via l'API
      await _checkProductRecall(result);
    } catch (e) {
      setState(() {
        _scanResult = 'Erreur lors du scan: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkProductRecall(String barcode) async {
    try {
      // API RappelConso v2.1 — dataset GTIN trie pour recherche exacte par code-barres
      const String gtinDataset = 'rappelconso-v2-gtin-trie';
      final encodedWhere = Uri.encodeQueryComponent('gtin="$barcode"');
      final apiUrl =
          'https://data.economie.gouv.fr/api/explore/v2.1/catalog/datasets/$gtinDataset/records'
          '?where=$encodedWhere&limit=5';

      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = List<dynamic>.from(data['results'] ?? []);

        if (results.isEmpty) {
          setState(() {
            _scanResult =
                '✅ Aucun rappel trouvé pour ce produit (code-barres: $barcode)';
            _isLoading = false;
          });
          return;
        }

        // Construction du message détaillé à partir des champs v2.1
        final StringBuffer result = StringBuffer();
        result.writeln('⚠️ ATTENTION: Produit rappelé!');
        result.writeln('Code-barres: $barcode');

        for (int i = 0; i < results.length; i++) {
          final item = results[i] as Map<String, dynamic>;
          result.writeln('\n--- Rappel ${i + 1} ---');
          result.writeln(
              'Produit: ${item['libelle'] ?? item['modeles_ou_references'] ?? 'Non spécifié'}');
          result.writeln(
              'Marque: ${item['marque_produit'] ?? 'Non spécifiée'}');
          result.writeln(
              'Raison: ${item['motif_rappel'] ?? 'Non spécifiée'}');
          result.writeln(
              'Date: ${item['date_publication'] ?? 'Non spécifiée'}');

          // Utiliser directement l'URL complète v2.1 (lien_vers_la_fiche_rappel)
          final officialUrl =
              item['lien_vers_la_fiche_rappel']?.toString() ?? '';
          if (officialUrl.isNotEmpty) {
            result.writeln('Plus d\'infos: $officialUrl');
          }
        }

        // Indiquer s'il y a potentiellement plus de résultats
        final totalCount = data['total_count'] as int? ?? results.length;
        if (totalCount > 5) {
          result.writeln('\nNB: ${totalCount - 5} autres rappels trouvés.');
        }

        setState(() {
          _scanResult = result.toString();
          _isLoading = false;
        });
      } else {
        setState(() {
          _scanResult =
              'Erreur API (${response.statusCode}). Réessayez.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _scanResult = 'Erreur de connexion: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification des rappels'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 20),
                Icon(
                  _scanResult.contains('ATTENTION')
                      ? Icons.warning_amber_rounded
                      : Icons.qr_code_scanner,
                  size: 80,
                  color: _scanResult.contains('ATTENTION')
                      ? Colors.red
                      : Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 30),
                if (_isLoading)
                  const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text('Consultation de la base de rappels...'),
                    ],
                  ),
                if (!_isLoading)
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _scanResult.contains('ATTENTION')
                          ? Colors.red.withValues(alpha: 0.1)
                          : _scanResult.contains('✅')
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _scanResult.contains('ATTENTION')
                            ? Colors.red
                            : _scanResult.contains('✅')
                                ? Colors.green
                                : Colors.grey,
                      ),
                    ),
                    child: Text(
                      _scanResult,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: _scanResult.contains('ATTENTION')
                            ? Colors.red
                            : null,
                      ),
                    ),
                  ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scanner un produit'),
                  onPressed: _isLoading ? null : _scanBarcode,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    minimumSize: const Size(250, 50),
                  ),
                ),
                if (_lastScannedBarcode != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Vérifier à nouveau'),
                      onPressed: _isLoading
                          ? null
                          : () async {
                              setState(() {
                                _isLoading = true;
                                _scanResult = 'Vérification en cours...';
                              });
                              await _checkProductRecall(_lastScannedBarcode!);
                            },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
