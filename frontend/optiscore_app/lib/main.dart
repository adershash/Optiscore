import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CaptureScreen(cameras: cameras),
    );
  }
}

class CaptureScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CaptureScreen({super.key, required this.cameras});

  @override
  _CaptureScreenState createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  XFile? _imageFile;
  String evaluatedScore = "";
  TextEditingController questionController = TextEditingController();

  final String fastApiBaseUrl = "http://192.168.55.116:8000"; // Replace with actual IP

  // Open Camera Screen
  Future<void> _openCamera() async {
    final XFile? image = await Navigator.push<XFile>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(camera: widget.cameras.first),
      ),
    );

    if (image != null) {
      setState(() {
        _imageFile = image;
        evaluatedScore = "";
      });
    }
  }

  // Send Question to FastAPI
  Future<void> _sendQuestion() async {
    if (questionController.text.isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse("$fastApiBaseUrl/question/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"question": questionController.text}),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Question sent successfully!")),
        );
      } else {
        print("Failed to send question: ${response.body}");
      }
    } catch (e) {
      print("Error sending question: $e");
    }
  }

  // Upload Image to FastAPI
  Future<void> _uploadImage() async {
    if (_imageFile == null) return;
    try {
      var request = http.MultipartRequest("POST", Uri.parse("$fastApiBaseUrl/upload/"));
      request.files.add(await http.MultipartFile.fromPath("file", _imageFile!.path));
      var response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image uploaded successfully!")),
        );
      } else {
        print("Failed to upload image.");
      }
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  // Evaluate Image and Display Score
  Future<void> _evaluateImage() async {
    try {
      final response = await http.get(Uri.parse("$fastApiBaseUrl/testeval"));
      if (response.statusCode == 200) {
        setState(() {
          evaluatedScore = jsonDecode(response.body)["score"];
        });
      } else {
        print("Failed to get evaluation.");
      }
    } catch (e) {
      print("Error getting evaluation: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          "OptiScore",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Question Input with Send Button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: questionController,
                    decoration: InputDecoration(
                      labelText: "Enter Question",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _sendQuestion,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                  ),
                  child: const Text("Send"),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Image Preview
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3))],
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                    )
                  : const Center(child: Icon(Icons.image, size: 100, color: Colors.grey)),
            ),
            const SizedBox(height: 20),

            // Capture Button
            FloatingActionButton(
              onPressed: _openCamera,
              backgroundColor: Colors.blueAccent,
              child: const Icon(Icons.camera, color: Colors.white),
            ),
            const SizedBox(height: 20),

            // Upload & Evaluate Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _uploadImage,
                  icon: const Icon(Icons.upload),
                  label: const Text("Upload"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 14),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _evaluateImage,
                  icon: const Icon(Icons.check_circle),
                  label: const Text("Evaluate"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Evaluated Score Box
            if (evaluatedScore.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  evaluatedScore,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Camera Screen (Opens Camera and Captures Image)
class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  const CameraScreen({super.key, required this.camera});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    await _initializeControllerFuture;
    final image = await _controller.takePicture();
    if (!mounted) return;
    Navigator.pop(context, image);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Capture Image")),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) =>
            snapshot.connectionState == ConnectionState.done ? CameraPreview(_controller) : const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _captureImage, child: const Icon(Icons.camera)),
    );
  }
}
