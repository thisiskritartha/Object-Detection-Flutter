import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image_picker/image_picker.dart';

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

    const mode = DetectionMode.single;
    final options = ObjectDetectorOptions(
        mode: mode, classifyObjects: true, multipleObjects: true);
    objectDetector = ObjectDetector(options: options);
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

  doObjectDetection() async {
    InputImage inputImage = InputImage.fromFile(img!);
    objects = await objectDetector.processImage(inputImage);
    for (DetectedObject detectedObjects in objects) {
      final Rect rect = detectedObjects.boundingBox;
      final trackingId = detectedObjects.trackingId;

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
                          primary: Colors.transparent,
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
