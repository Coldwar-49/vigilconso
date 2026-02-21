import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({Key? key}) : super(key: key);

  @override
  _BarcodeScannerPageState createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  String _scanResult = 'Scannez un code-barres pour vérifier les rappels';
  bool _isLoading = false;
  MobileScannerController? _scannerController;
  String? _lastScannedBarcode;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
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
      // Créer le contrôleur s'il n'existe pas encore
      _scannerController ??= MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        formats: [
          BarcodeFormat.ean8,
          BarcodeFormat.ean13,
          BarcodeFormat.qrCode
        ],
        facing: CameraFacing.back,
      );

      // Ouvrir un nouveau screen de scan
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
              controller: _scannerController!,
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
      final recallInfo = await _checkProductRecall(result);

      setState(() {
        _scanResult = recallInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _scanResult = 'Erreur lors du scan: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<String> _checkProductRecall(String barcode) async {
    try {
      // API de RappelConso en France
      final response = await http
          .get(
            Uri.parse(
                'https://data.economie.gouv.fr/api/records/1.0/search/?dataset=rappelconso0&q=$barcode&rows=5'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Vérifier si des rappels ont été trouvés
        if (data['nhits'] > 0) {
          // Construction d'un message détaillé
          final StringBuffer result = StringBuffer();
          result.writeln('⚠️ ATTENTION: Produit rappelé!');
          result.writeln('Code-barres: $barcode');

          // Parcourir les résultats (limité à 5 max)
          final int resultCount = data['nhits'] > 5 ? 5 : data['nhits'];
          for (int i = 0; i < resultCount; i++) {
            try {
              final record = data['records'][i]['fields'];
              result.writeln('\n--- Rappel ${i + 1} ---');
              result.writeln(
                  'Produit: ${record['nom_de_la_marque_du_produit'] ?? 'Non spécifié'}');
              result.writeln(
                  'Référence: ${record['reference_fiche'] ?? 'Non spécifiée'}');
              result.writeln(
                  'Raison: ${record['motif_du_rappel'] ?? 'Non spécifiée'}');
              result.writeln(
                  'Date: ${record['date_de_publication'] ?? 'Non spécifiée'}');

              // Ajouter le lien si disponible
              final lien = record['lien_vers_la_fiche_rappel'];
              if (lien != null && lien.toString().isNotEmpty) {
                result.writeln('Plus d\'infos: $lien');
              }
            } catch (e) {
              result
                  .writeln('Erreur lors de l\'analyse du rappel ${i + 1}: $e');
            }
          }

          // Indiquer s'il y a plus de résultats
          if (data['nhits'] > 5) {
            result
                .writeln('\nNB: ${data['nhits'] - 5} autres rappels trouvés.');
          }

          return result.toString();
        }
        return '✅ Aucun rappel trouvé pour ce produit (code-barres: $barcode)';
      }
      return 'Erreur lors de la vérification du produit (code HTTP: ${response.statusCode})';
    } catch (e) {
      return 'Erreur de connexion à l\'API: ${e.toString()}';
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
                  Column(
                    children: const [
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
                          ? Colors.red.withOpacity(0.1)
                          : _scanResult.contains('✅')
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
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
                              final recallInfo = await _checkProductRecall(
                                  _lastScannedBarcode!);
                              setState(() {
                                _scanResult = recallInfo;
                                _isLoading = false;
                              });
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
