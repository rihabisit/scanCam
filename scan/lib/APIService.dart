import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  final String apiUrl = 'http://127.0.0.1:5000/ocr'; // Replace with your Flask API URL

  Future<Map<String, dynamic>> uploadImage(File imageFile, String language) async {
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    request.fields['language'] = language;

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseBody = await response.stream.bytesToString();
      return jsonDecode(responseBody);
    } else {
      throw Exception('Failed to upload image');
    }
  }
}
