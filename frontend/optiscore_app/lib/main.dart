import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

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
  String successMessage = "";

  // Open Camera Screen
  Future<void> _openCamera() async {
    final image = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(camera: widget.cameras.first),
      ),
    );

    if (image != null) {
      setState(() {
        _imageFile = image;
        successMessage = ""; // Reset message when a new image is captured
      });
    }
  }

  // Dummy Upload Function
  Future<void> _uploadImage() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No image to upload!")),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Image uploaded successfully!")),
    );
  }

  // Dummy Convert Function
  void _convertImage() {
    if (_imageFile != null) {
      setState(() {
        successMessage = "Image converted successfully!";
      });
    } else {
      setState(() {
        successMessage = "No image to convert!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("OptiScore")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _imageFile != null
              ? Image.file(File(_imageFile!.path), height: 250)
              : const Icon(Icons.image, size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                onPressed: _openCamera,
                child: const Icon(Icons.camera),
              ),
              const SizedBox(width: 20),
              ElevatedButton.icon(
                onPressed: _uploadImage,
                icon: const Icon(Icons.upload),
                label: const Text("Upload Image"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _convertImage,
            icon: const Icon(Icons.transform),
            label: const Text("Convert"),
          ),
          const SizedBox(height: 20),
          TextField(
            readOnly: true,
            decoration: InputDecoration(
              hintText: successMessage.isNotEmpty ? successMessage : "Success message here",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// Camera Preview Screen
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
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      if (!mounted) return;
      Navigator.pop(context, image);
    } catch (e) {
      print("Error capturing image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: FloatingActionButton(
                      onPressed: _captureImage,
                      child: const Icon(Icons.camera),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
