// Cette interface Flutter permet à l'utilisateur d'importer des fichiers images ou PDF, de les recadrer, de détecter la langue du texte qu'ils contiennent, et d'extraire ce texte pour un traitement ultérieur.
// Le texte extrait peut être affiché, analysé ou utilisé pour d'autres applications, comme la traduction ou la transcription.
// L'interface prend en charge les images prises avec la caméra, sélectionnées depuis la galerie, ou importées en tant que fichiers PDF.
// Elle utilise Google ML Kit pour la reconnaissance de texte et le package flutter_langdetect pour la détection de la langue.
// Attention :supprimer l'utilisation de google ML Kit car l'app est liée avec le model pour detecter le lang
// lorsque appuie sur le button import pdf


import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
//import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'Translator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'ExtractTextPage.dart';
import 'package:image_cropper/image_cropper.dart';

// recommend to import 'as langdetect' because this package shows a simple function name 'detect'
import 'package:flutter_langdetect/flutter_langdetect.dart' as langdetect;

class ImportPage extends StatefulWidget {
  final File file;


  ImportPage({required this.file});

  @override
  _ImportPageState createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  String _detectedLanguage = '';
  late File _croppedFile;
  late TextRecognizer textRecognizer;

  @override
  void initState() {
    super.initState();
    _croppedFile = widget.file;
    _detectLanguage(widget.file);
    _cropImage(_croppedFile);
    textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    //_detectLanguage(widget.file);
    doTextRecognition();
  }

  String results = "";

  doTextRecognition() async {
    InputImage inputImage = InputImage.fromFile(this.widget.file);
    final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage);

    results = recognizedText.text;
    print(results);
    setState(() {
      results;
    });

    for (TextBlock block in recognizedText.blocks) {
      final Rect rect = block.boundingBox;
      final List<Point<int>> cornerPoints = block.cornerPoints;
      final String text = block.text;
      final List<String> languages = block.recognizedLanguages;

      for (TextLine line in block.lines) {
        // Same getters as TextBlock
        for (TextElement element in line.elements) {
          // Same getters as TextBlock
        }
      }
    }
  }

  Future<void> _cropImage(File file) async {
    CroppedFile? cropped = await ImageCropper().cropImage(
      sourcePath: file.path,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9,
      ],
      uiSettings:[ AndroidUiSettings(
        toolbarTitle: 'Recadrer l\'image',
        backgroundColor: Colors.white,
        toolbarWidgetColor: Colors.lightGreen[700],
        initAspectRatio: CropAspectRatioPreset.original,
        lockAspectRatio: false,
      ),
      IOSUiSettings(
        minimumAspectRatio: 1.0,
      ),]
    );

    if (cropped != null) {
      setState(() {
        _croppedFile = File(cropped.path);

      });
      _detectLanguage(_croppedFile);
    }
  }
  String detectedLanguage ='';
  void _detectLanguage(XFile) async {
    WidgetsFlutterBinding.ensureInitialized();

    await langdetect.initLangDetect();  // This is needed once in your application after ensureInitialized()

    String text = results;

    final language = langdetect.detect(text);
   // print('Detected language: $language'); // -> "en"
    detectedLanguage = language;
    final probs = langdetect.detectLangs(text);
    for (final p in probs) {
      print("Language: ${p.lang}");  // -> "en"
      print("Probability: ${p.prob}");  // -> 0.9999964132193504
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Traitement', style: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: widget.file.path.endsWith('.pdf')
                  ? Text('Fichier PDF : ${_croppedFile}')
                  : Image.file(_croppedFile)
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Appel de la fonction pour extraire le texte du fichier
                Navigator.push(context, MaterialPageRoute(builder: (context)=> ExtractTextPage(file: _croppedFile)),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.lightGreen[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 28),
              ),
              child: Text('Extraire Tx.', style: TextStyle(color: Colors.white)),
            ),
            SizedBox(height: 20),
            Text(
              'Langue détectée : $detectedLanguage',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPDFViewerPage(File file) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PDFViewerPage(file: file),
      ),
    );
  }
}




class PDFViewerPage extends StatelessWidget {
  final File file;

  PDFViewerPage({required this.file});

  @override

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Viewer'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PDFView(
              filePath: file.path,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> ImportPage(file: file)),
                  );


                },
                child: Text('Extraire TXT'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> TranslatorScreen()),
                  );

                },
                child: Text('Transcription'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

