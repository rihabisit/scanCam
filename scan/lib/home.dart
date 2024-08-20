// Cette interface Flutter permet à l'utilisateur de scanner, importer, et gérer des fichiers PDF ou des images.
// Elle offre des fonctionnalités telles que la capture d'image via la caméra ou la galerie, la sélection de fichiers PDF, et la gestion des fichiers importés (renommer, supprimer).
// L'utilisateur peut également visualiser les fichiers PDF, extraire du texte des PDF, et accéder à un outil de transcription.

import 'dart:io';

import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:scan/ExtractTextPage.dart';
import 'Translator.dart';

import 'ImportPage.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //File? _selectedImage;
  //File? _selectedPdf;
  File? _selectedFile;
  List<FileSystemEntity> savedFiles = [];

  @override
  void initState() {
    super.initState();
    fetchSavedFiles();
  }

  Future<void> fetchSavedFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync().where((file) => file.path.endsWith('.pdf'));
    setState(() {
      savedFiles = files.toList();
    });
  }

  Future<void> _refresh() async {
    await fetchSavedFiles();
  }


  Future<void> renameFile(File file) async {
    final directory = await getApplicationDocumentsDirectory();
    final newNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename File'),
        content: TextField(
          controller: newNameController,
          decoration: InputDecoration(hintText: 'Enter new file name'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newName = newNameController.text;
              if (newName.isNotEmpty) {
                final newFilePath = '${directory.path}/$newName.pdf';
                await file.rename(newFilePath);
                fetchSavedFiles();
                Navigator.of(context).pop();
              }
            },
            child: Text('Rename'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteFile(File file) async {
    await file.delete();
    fetchSavedFiles();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File deleted')),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(10),
          ),
        ),
        elevation: 4,
       //backgroundColor: Colors.transparent,
        // backgroundColor: Colors.tealAccent[400],
        title: Text(
          'Home',
          style: GoogleFonts.roboto(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
    body: RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child:
              Image.asset(
                'assets/images/200w.gif',
                width: 350,
                height: 250,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _pickImageFromCamera();
                // Action to take when the first button is pressed
                // (e.g., open camera)
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.lightGreen[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Bordure arrondie
                ),// Définir la couleur de fond du bouton
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 40),
              ),
              child: Text('Scan',
                style: TextStyle(
                    color: Colors.white
                ),),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
        
                ElevatedButton(
        
                  onPressed: () {
                    _pickImageFromGallery();
                    // Action to take when the second button is pressed
                    // (e.g., open gallery to select photo)
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.lightGreen[700], // Définir la couleur de fond du bouton
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Bordure arrondie
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                  ),
                  child: Text('Import Photo',
                  style: TextStyle(
                    color: Colors.white
                  ),
                  ),
        
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _pickFilePdf();

                    //_pickPdfFromGallery();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.lightGreen[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Bordure arrondie
                    ),// Définir la couleur de fond du bouton
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                  ),
                  child: Text('Import PDF',
                    style: TextStyle(
                        color: Colors.white
                    ),),
                ),
              ],
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Placeholder for recent history',
                ),
              ),
            ),
            SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: savedFiles.length,
              itemBuilder: (context, index) {
                final file = savedFiles[index];
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.picture_as_pdf, color: Colors.green), // PDF icon

                    title: Text(
                      file.path.split('/').last,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => renameFile(File(file.path)),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => deleteFile(File(file.path)),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (file.path.endsWith('.pdf')) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PDFViewerPage(file: File(file.path)),
                          ),
                        );
                      }
                      // Handle file tap if needed (e.g., open the file)
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
    );
  }


  Future _pickImageFromGallery() async {
    final pickedImage =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedFile = File(pickedImage.path);
        _navigateToImportPage();
      });
    }
  }
  Future _pickImageFromCamera() async {
    final pickedImage =
    await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      setState(() {
        _selectedFile = File(pickedImage.path);
        _navigateToImportPage();
      });
    }
  }
  Future<void> _pickFilePdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf','doc', 'docx'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _navigateToPDFViewerPage(_selectedFile!);
        });
        // Vous pouvez maintenant utiliser _selectedFile
        print('Fichier PDF sélectionné : ${_selectedFile!}');
      } else {
        // L'utilisateur a annulé le picker
        print('File selection canceled');
      }
    } catch (e) {
      print('An error occurred: $e');
    }
  }
  void _navigateToImportPage() {
    if (_selectedFile != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ImportPage(file: _selectedFile!),
        ),
      );
    }
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


















