import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: ImageUploadScreen(),
    );
  }
}

class ImageUploadScreen extends StatefulWidget {
  @override
  _ImageUploadScreenState createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  final String apiUrl = "http://192.168.55.116:8000"; // Replace with your FastAPI server IP
  final TextEditingController _maxScoreController = TextEditingController();
  final TextEditingController _questionNumberController = TextEditingController();
  final TextEditingController _resultController = TextEditingController(); // Result field as text box

  File? _questionImage;
  File? _answerImage;
  final ImagePicker _picker = ImagePicker();
  
  bool _clear_flag=false;
  bool _showResult = false;

  /// **📸 Pick Image from Gallery**
  Future<void> _pickImage(bool isQuestion) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isQuestion) {
          _questionImage = File(pickedFile.path);
        } else {
          _answerImage = File(pickedFile.path);
        }
      });
    }
  }

  /// **📷 Capture Image from Camera**
  Future<void> _captureImage(bool isQuestion) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        if (isQuestion) {
          _questionImage = File(pickedFile.path);
        } else {
          _answerImage = File(pickedFile.path);
        }
      });
    }
  }

  /// **📤 Upload Image to FastAPI**
  Future<void> _uploadImage(File? image, String route, String imageType) async {
    if (image == null) {
      _showSnackbar("Please select an image to upload.", false);
      return;
    }

    var request = http.MultipartRequest("POST", Uri.parse("$apiUrl$route"));
    request.files.add(await http.MultipartFile.fromPath('file', image.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      _showSnackbar("$imageType uploaded successfully!", true);
    } else {
      _showSnackbar("Failed to upload $imageType. Try again!", false);
    }
  }

  /// **📨 Send Question Number**
  Future<void> _sendQuestionNumber() async {
    String questionNumber = _questionNumberController.text.trim();
    if (questionNumber.isEmpty) {
      _showSnackbar("Enter a question number before sending.", false);
      return;
    }

    var response = await http.post(
      Uri.parse("$apiUrl/question_no/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"question": _questionNumberController.text}),
    );

    if (response.statusCode == 200) {
      _showSnackbar("Question number sent successfully!", true);
    } else {
      _showSnackbar("Failed to send question number!", false);
    }
  }

  /// **📨 Send Max Score**
  Future<void> _sendMaxScore() async {
    String maxScore = _maxScoreController.text.trim();
    if (maxScore.isEmpty) {
      _showSnackbar("Enter a max score before sending.", false);
      return;
    }

    try {
      var response = await http.post(
        Uri.parse("$apiUrl/max_score/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"max_score": int.parse(_maxScoreController.text)}),
      );

      if (response.statusCode == 200) {
        _showSnackbar("Max score sent successfully!", true);
      } else {
        _showSnackbar("Failed to send max score!", false);
      }
    } catch (e) {
      _showSnackbar("Invalid max score value!", false);
    }
  }

  /// **📊 Evaluate and Fetch Result**
  Future<void> _evaluate() async {
    var response = await http.get(Uri.parse("$apiUrl/testeval/"));

    if (response.statusCode == 200) {
      setState(() {
        _showResult = true;
        _resultController.text = jsonDecode(response.body)["result"];
      });
      _showSnackbar("Evaluation successful!", true);
    } else {
      _showSnackbar("Failed to fetch evaluation result!", false);
    }
  }
  ///clear data
  Future<void> _clear() async {
    
    setState(() {
    _questionNumberController.clear();
    _maxScoreController.clear();
    _resultController.clear();
    _questionImage = null;
    _answerImage = null;
    _showResult = false;
    _clear_flag=true;
  });
  var response = await http.post(
        Uri.parse("$apiUrl/clear/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"clear": _clear_flag}));
  

  _showSnackbar("All data cleared!", true);
  }

  /// **📢 Show Snackbar**
  void _showSnackbar(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: 16, color: Colors.white)),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// **🖼️ UI Elements**
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OptiScore', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: SingleChildScrollView(
          child: Column(
            children: [
              buildImageSection("Upload Question", _questionImage, true),
              buildUploadButton("Upload Question", () => _uploadImage(_questionImage, "/question/", "Question")),

              const SizedBox(height: 20),

              buildImageSection("Upload Answer", _answerImage, false),
              buildUploadButton("Upload Answer", () => _uploadImage(_answerImage, "/upload/", "Answer")),

              const SizedBox(height: 20),

              buildTextFieldWithSendButton("Enter Question Number", _questionNumberController, _sendQuestionNumber),
              const SizedBox(height: 20),
              buildTextFieldWithSendButton("Enter Max Score", _maxScoreController, _sendMaxScore),

              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildEvaluateButton(),
                  const SizedBox(width: 20),
                  buildClearButton()


                ],
              ),
              

              if (_showResult) ...[
                const SizedBox(height: 25),
                buildResultTextField(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget buildImageSection(String title, File? image, bool isQuestion) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[700])),
        const SizedBox(height: 10),
        image != null
            ? Image.file(image, width: 160, height: 160, fit: BoxFit.cover)
            : Container(width: 160, height: 160, color: Colors.grey[300], child: Icon(Icons.image, size: 50, color: Colors.grey[600])),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildUploadButton("Capture", () => _captureImage(isQuestion)),
            const SizedBox(width: 20),
            buildUploadButton("Gallery", () => _pickImage(isQuestion)),
          ],
        ),
      ],
    );
  }

  Widget buildUploadButton(String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      child: Text(label, style: TextStyle(fontSize: 16, color: Colors.white)),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
    );
  }

  Widget buildTextFieldWithSendButton(String hint, TextEditingController controller, VoidCallback onTap) {
    return Row(
      children: [
        Expanded(child: TextField(controller: controller, decoration: InputDecoration(labelText: hint, border: OutlineInputBorder()))),
        IconButton(icon: Icon(Icons.send, color: Colors.teal), onPressed: onTap),
      ],
    );
  }

  Widget buildEvaluateButton() {
    return buildUploadButton("Evaluate", _evaluate);
  }
  Widget buildClearButton(){
    return buildUploadButton("Clear", _clear);
  }

  Widget buildResultTextField() {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Evaluation Result",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal[700]),
          ),
          const SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.teal[50], // Light teal background
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.teal, width: 1.5),
            ),
            child: TextField(
              controller: _resultController,
              readOnly: true,
              maxLines: 3,
              style: TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                border: InputBorder.none, // Remove default border
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
