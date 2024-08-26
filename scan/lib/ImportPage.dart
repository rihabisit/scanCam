import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_langdetect/flutter_langdetect.dart' as langdetect;
import 'ExtractTextPage.dart';
import 'Translator.dart'; // Ensure this import is correct

class ImportPage extends StatefulWidget {
  final File file;

  ImportPage({required this.file});

  @override
  _ImportPageState createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  String _detectedLanguage = '';
  late File _croppedFile;
  String results = "";
  bool _isPdf = true;

  @override
  void initState() {
    super.initState();
    _croppedFile = widget.file;
    _isPdf = widget.file.path.endsWith('.pdf');
    _cropImage(_croppedFile);
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
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recadrer l\'image',
          backgroundColor: Colors.white,
          toolbarWidgetColor: Colors.purple.shade100,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          minimumAspectRatio: 1.0,
        ),
      ],
    );

    if (cropped != null) {
      setState(() {
        _croppedFile = File(cropped.path);
      });
      await _uploadFile(_croppedFile, _isPdf);
    }
  }

Future<void> _uploadFile(File file, bool isPdf) async {
    final uri = Uri.parse('http://192.168.1.65:5000/${isPdf ? 'ocr_pdf' : 'ocr'}');
    var request = http.MultipartRequest('POST', uri);

    request.files.add(await http.MultipartFile.fromPath(
      isPdf ? 'pdf' : 'image',
      file.path,
    ));

    request.fields['language[]'] = 'eng'; // Anglais
    request.fields['language[]'] = 'ara'; // Arabe
    request.fields['language[]'] = 'fra'; // Français

    print('Uploading file: ${file.path} to $uri'); // Ligne de débogage

    try {
      var response = await request.send();
      print('Response status code: ${response.statusCode}'); // Ligne de débogage

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        print('Response data: $responseData'); // Ligne de débogage

        final Map<String, dynamic> responseJson = json.decode(responseData);
        setState(() {
          // Récupérer les résultats pour chaque langue
          results = responseJson['eng']['text'] ?? '';
          results += '\n' + (responseJson['ara']['text'] ?? '');
          results += '\n' + (responseJson['fra']['text'] ?? '');
          _detectLanguage(results);
        });
      } else {
        print('Failed to upload file. Status code: ${response.statusCode}'); // Ligne de débogage
      }
    } catch (e) {
      print('Error uploading file: $e'); // Ligne de débogage
    }
  }



  void _detectLanguage(String text) async {
    WidgetsFlutterBinding.ensureInitialized();
    await langdetect.initLangDetect(); // Initialize language detection

    final language = langdetect.detect(text);
    setState(() {
      _detectedLanguage = language;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        title: Text('Traitment', style: TextStyle(fontSize: 24)),
        backgroundColor: Colors.purple.shade100,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isPdf
                  ? Container(
                height: 600,
                child: PDFView(
                  filePath: _croppedFile.path,
                ),
              )
                  : Image.file(_croppedFile),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_croppedFile != null) {
                  await _uploadFile(_croppedFile, _isPdf);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExtractTextPage(
                        file: _croppedFile,
                        extractedText: results, // Pass the extracted text here
                        languageCode: _detectedLanguage.isNotEmpty ? _detectedLanguage : 'eng',
                      ),
                    ),
                  );
                } else {
                  print('No file selected.');
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.purple.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 28),
              ),
              child: Text('Extracted Text', style: TextStyle(color: Colors.white)),
            ),

            SizedBox(height: 20),
            // Text(
            //   'Langue détectée : $_detectedLanguage',
            //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            // ),
          ],
        ),
      ),
    );
  }
}
