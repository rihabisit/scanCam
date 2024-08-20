// Cette page Flutter permet d'extraire du texte d'une image ou d'un PDF à l'aide de Google ML Kit, d'afficher ce texte, puis de l'enregistrer en tant que fichier PDF.
// Le texte extrait est affiché dans un champ de texte éditable, permettant à l'utilisateur de modifier ou de revoir le contenu avant de l'enregistrer.
// L'utilisateur peut également choisir de transcrire le texte extrait en lançant la fonction de transcription.
// Le fichier PDF est ensuite enregistré dans le répertoire de documents de l'application, avec un nom spécifié par l'utilisateur ou généré automatiquement.
// attention : supprimer la partie de google mlkit et liée avec model
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'home.dart';
import 'Translator.dart';
import 'package:http/http.dart' as http;



class ExtractTextPage extends StatefulWidget {
  late File file;
  final String extractedText;
  final String languageCode;
  ExtractTextPage({required this.file, required this.extractedText, required this.languageCode});


  @override
  State<ExtractTextPage> createState() => _ExtractTextPageState();
}
class _ExtractTextPageState extends State<ExtractTextPage> {
  //late TextRecognizer textRecognizer;
  TextEditingController textEditingController = TextEditingController();
  TextEditingController fileNameController = TextEditingController();
  bool _isLoading = true;
  String _errorMessage = "";


  @override
  void initState() {
    super.initState();
   // textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _extractText();
   // doTextRecognition();
  }

  /// resultat api

  Future<void> _extractText() async {
    final uri = Uri.parse('http://127.0.0.1:5000/ocr');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', widget.file.path))
      ..fields['language'] = widget.languageCode;

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = jsonDecode(responseData);
        final text = data[widget.languageCode]['text'] ?? '';
        setState(() {
          textEditingController.text = text;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to extract text from the image';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
        _isLoading = false;
      });
    }
  }




  @override
  void dispose() {
   // textRecognizer.close();
    super.dispose();
  }
  String results = "";

  doTextRecognition() async {
    InputImage inputImage = InputImage.fromFile(this.widget.file);
   // final RecognizedText recognizedText = await textRecognizer.processImage(
    //    inputImage);

    //results = recognizedText.text;
    print(results);
    textEditingController.text = results;
    setState(() {
      //results;
      _isLoading = false;
    });


   // for (TextBlock block in recognizedText.blocks) {
     // final Rect rect = block.boundingBox;
     // final List<Point<int>> cornerPoints = block.cornerPoints;
     // final String text = block.text;
    //  final List<String> languages = block.recognizedLanguages;

    //  for (TextLine line in block.lines) {
        // Same getters as TextBlock
     //   for (TextElement element in line.elements) {
          // Same getters as TextBlock
      //  }
     // }
  //  }
  }

  Future<void> saveAsPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Text(textEditingController.text),
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final fileName = fileNameController.text.isNotEmpty ? fileNameController.text : 'extracted_text_${DateTime.now().millisecondsSinceEpoch}';
    final file = File('${directory.path}/$fileName.pdf');
    await file.writeAsBytes(await pdf.save());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved as PDF: ${file.path}')),
    );
    Navigator.pop(context, file.path); // Navigate back and indicate that a file was saved
  }
  Future<void> _showSaveDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Save as PDF'),
          content: TextField(
            controller: fileNameController,
            decoration: InputDecoration(hintText: "Enter file name"),
          ),
          actions: [
            TextButton(
              child: Text('Cancel',
                style: TextStyle(color: Colors.lightGreen[700]),),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Save',
                style: TextStyle(color: Colors.lightGreen[700]),),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                    MaterialPageRoute(
                    builder: (context) => HomeScreen()));
                saveAsPDF();
              },
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
        title: Text('Extract Text'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : TextField(
                    controller: textEditingController,
                    maxLines: null,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Extracted text will appear here',
                    ),
                  ),
                ),
        SizedBox(height: 16),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=> TranslatorScreen()),
                    );

                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.lightGreen[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                  ),
                  child: Text('Transcription', style: TextStyle(color: Colors.white)),
                ),
                      ElevatedButton(
                        onPressed: _showSaveDialog,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.lightGreen[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                        ),
                        child: Text('Save', style: TextStyle(color: Colors.white)),
                      ),]),
              ]
             ), ),

          ),
        );


  }


}
