import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyHomePage());
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  dynamic imagePicker;
  File? img;
  dynamic objectDetector;
  var image;
  late List<DetectedObject> objects;

  @override
  void initState() {
    super.initState();
    imagePicker = ImagePicker();

    //For the base model of object_detection
    // const mode = DetectionMode.single;
    // final options = ObjectDetectorOptions(
    //     mode: mode, classifyObjects: true, multipleObjects: true);
    // objectDetector = ObjectDetector(options: options);

    //For the custom model of object_detection
    createObjectDetection();
  }

  @override
  void dispose() {
    super.dispose();
  }

  imgFromGallery() async {
    final XFile? image =
        await imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      img = File(image.path);
      doObjectDetection();
    }
  }

  imgFromCamera() async {
    final XFile? image =
        await imagePicker.pickImage(source: ImageSource.camera);
    if (image != null) {
      img = File(image.path);
      doObjectDetection();
    }
  }

  createObjectDetection() async {
    //For the mobilenet tflite model
    //final modelPath = await _getModel('assets/ml/mobilenet.tflite');

    //For the efficient tflite mode
    final modelPath = await _getModel('assets/ml/efficientnet.tflite');

    final options = LocalObjectDetectorOptions(
      modelPath: modelPath,
      classifyObjects: true,
      multipleObjects: true,
      mode: DetectionMode.single,
    );
    objectDetector = ObjectDetector(options: options);
  }

  Future<String> _getModel(String assetPath) async {
    if (Platform.isAndroid) {
      return 'flutter_assets/$assetPath';
    }
    final path = '${(await getApplicationSupportDirectory()).path}/$assetPath';
    await Directory(dirname(path)).create(recursive: true);
    final file = File(path);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(assetPath);
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
  }

  doObjectDetection() async {
    InputImage inputImage = InputImage.fromFile(img!);
    objects = await objectDetector.processImage(inputImage);
    for (DetectedObject detectedObjects in objects) {
      //final Rect rect = detectedObjects.boundingBox;
      //final trackingId = detectedObjects.trackingId;

      for (Label label in detectedObjects.labels) {
        print('${label.text}: ${label.confidence} 💥💥');
      }
    }
    setState(() {
      img;
    });
    drawRectangleAroundObject();
  }

  drawRectangleAroundObject() async {
    image = await img!.readAsBytes();
    image = await decodeImageFromList(image);
    setState(() {
      image;
      objects;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              children: [
                const SizedBox(
                  width: double.infinity,
                ),
                Container(
                  margin: const EdgeInsets.only(top: 100),
                  child: Stack(
                    alignment: AlignmentDirectional.center,
                    children: [
                      ElevatedButton(
                        onPressed: imgFromGallery,
                        onLongPress: imgFromCamera,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: Container(
                          width: 350,
                          height: 350,
                          margin: const EdgeInsets.only(
                            top: 45,
                          ),
                          child: image != null
                              ? Center(
                                  child: FittedBox(
                                    child: SizedBox(
                                      width: image.width.toDouble(),
                                      height: image.height.toDouble(),
                                      child: CustomPaint(
                                        painter: ObjectPainter(
                                            objectList: objects,
                                            imageFile: image),
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 350,
                                  height: 350,
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.black,
                                    size: 100,
                                  ),
                                ),
                        ),
                      ),
                    ],
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

class ObjectPainter extends CustomPainter {
  ObjectPainter({required this.objectList, required this.imageFile});

  List<DetectedObject> objectList;
  dynamic imageFile;

  @override
  void paint(Canvas canvas, Size size) {
    if (imageFile != null) {
      canvas.drawImage(imageFile, Offset.zero, Paint());
    }

    Paint p = Paint();
    p.color = Colors.green;
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 30;
    for (DetectedObject obj in objectList) {
      canvas.drawRect(obj.boundingBox, p);

      var list = obj.labels;
      for (Label label in list) {
        TextSpan span = TextSpan(
          text: '${label.text}: ${label.confidence.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 200,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        );
        TextPainter tp = TextPainter(
            text: span,
            textAlign: TextAlign.left,
            textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(obj.boundingBox.left, obj.boundingBox.top));
        break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
