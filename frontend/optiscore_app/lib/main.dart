import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OptiScore',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[200],
      ),
      home: ImageCaptureScreen(),
    );
  }
}

class ImageCaptureScreen extends StatefulWidget {
  @override
  _ImageCaptureScreenState createState() => _ImageCaptureScreenState();
}

class _ImageCaptureScreenState extends State<ImageCaptureScreen> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _maxScoreController = TextEditingController();
  File? _image;
  String _evaluationResult = "";
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _captureImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _sendQuestion() async {
    final String apiUrl = "http://192.168.55.116:8000/question/";

    if (_questionController.text.isEmpty) {
      _showSnackBar("Please enter a question");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"question": _questionController.text}),
      );

      if (response.statusCode == 200) {
        _showSnackBar("Question sent successfully!");
      } else {
        _showSnackBar("Failed to send question");
      }
    } catch (e) {
      _showSnackBar("Error: $e");
    }
  }

  Future<void> _sendMaxScore() async {
    final String maxScoreUrl = "http://192.168.55.116:8000/max_score/";

    if (_maxScoreController.text.isEmpty) {
      _showSnackBar("Please enter a max score");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(maxScoreUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"max_score": int.parse(_maxScoreController.text)}),
      );

      if (response.statusCode == 200) {
        _showSnackBar("Max Score sent successfully!");
      } else {
        _showSnackBar("Failed to send max score");
      }
    } catch (e) {
      _showSnackBar("Error: $e");
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    final String uploadUrl = "http://192.168.55.116:8000/upload/";
    var request = http.MultipartRequest("POST", Uri.parse(uploadUrl));
    request.files.add(await http.MultipartFile.fromPath("file", _image!.path));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        _showSnackBar("Image uploaded successfully!");
      } else {
        _showSnackBar("Failed to upload image.");
      }
    } catch (e) {
      _showSnackBar("Error uploading image: $e");
    }
  }

  Future<void> _evaluate() async {
    final String evalUrl = "http://192.168.55.116:8000/testeval/";

    try {
      final response = await http.get(Uri.parse(evalUrl));

      if (response.statusCode == 200) {
        setState(() {
          _evaluationResult = jsonDecode(response.body)["result"];
        });
      } else {
        _showSnackBar("Error in evaluation");
      }
    } catch (e) {
      _showSnackBar("Failed to evaluate: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'OptiScore',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextFieldWithButton("Enter Question", _questionController, _sendQuestion),
              const SizedBox(height: 15),
              _buildTextFieldWithButton("Enter Max Score", _maxScoreController, _sendMaxScore),
              const SizedBox(height: 25),
              _buildImageButtons(),
              const SizedBox(height: 20),
              _image != null ? Image.file(_image!, width: 250, height: 250, fit: BoxFit.cover) : _buildPlaceholderImage(),
              const SizedBox(height: 20),
              _buildActionButton("Upload Image", Icons.upload, _uploadImage),
              const SizedBox(height: 20),
              _buildActionButton("Evaluate", Icons.assessment, _evaluate),
              const SizedBox(height: 20),
              _evaluationResult.isNotEmpty ? _buildResultBox(_evaluationResult) : SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFieldWithButton(String hint, TextEditingController controller, VoidCallback onPressed) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: hint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text("Send"),
        ),
      ],
    );
  }

  Widget _buildImageButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton("Capture", Icons.camera_alt, _captureImage),
        const SizedBox(width: 20),
        _buildActionButton("Gallery", Icons.image, _pickImage),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      label: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 5,
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
      child: Center(child: Icon(Icons.image, size: 50, color: Colors.grey[600])),
    );
  }

  Widget _buildResultBox(String result) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: Colors.green[50],
      ),
      child: Text(result, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[800])),
    );
  }
}
