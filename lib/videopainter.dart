import 'dart:io';
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_widgets/flutter_widgets.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

import 'landscape_player_controls.dart';
import 'flutter_signature_pad.dart';

class VideoPainter extends StatefulWidget {
  VideoPainter({Key key}) : super(key: key);

  @override
  _VideoPainterState createState() => _VideoPainterState();
}

class _VideoPainterState extends State<VideoPainter> {
  ByteData _img = ByteData(0);
  Color selectedColor = Colors.red;
  Color pickerColor = Colors.red;
  double strokeWidth = 4.0;
  List<DrawingPoints> points = List();
  bool showBottomList = false;
  double opacity = 1.0;
  StrokeCap strokeCap = (Platform.isAndroid) ? StrokeCap.butt : StrokeCap.round;
  SelectedMode selectedMode = SelectedMode.StrokeWidth;
  List<Color> colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.amber,
    Colors.black
  ];
  final _sign = GlobalKey<SignatureState>();
  Directory _downloadsDirectory;
  FlickManager flickManager;

  @override
  void initState() {
    super.initState();
    initDownloadsDirectoryState();
    flickManager = FlickManager(
      videoPlayerController: VideoPlayerController.network(
          'https://github.com/GeekyAnts/flick-video-player-demo-videos/blob/master/example/the_valley_compressed.mp4?raw=true'),
    );
  }

// Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initDownloadsDirectoryState() async {
    Directory downloadsDirectory;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      downloadsDirectory = await getApplicationDocumentsDirectory();
    } on PlatformException {
      print('Could not get the downloads directory');
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _downloadsDirectory = downloadsDirectory;
    });
  }

  @override
  void dispose() {
    flickManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var color = Colors.red;
    var strokeWidth = 5.0;
    return Scaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50.0),
                color: Colors.blueGrey),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      IconButton(
                          icon: Icon(Icons.album),
                          onPressed: () {
                            setState(() {
                              if (selectedMode == SelectedMode.StrokeWidth)
                                showBottomList = !showBottomList;
                              selectedMode = SelectedMode.StrokeWidth;
                            });
                          }),
                      IconButton(
                          icon: Icon(Icons.opacity),
                          onPressed: () {
                            setState(() {
                              if (selectedMode == SelectedMode.Opacity)
                                showBottomList = !showBottomList;
                              selectedMode = SelectedMode.Opacity;
                            });
                          }),
                      IconButton(
                          icon: Icon(Icons.color_lens),
                          onPressed: () {
                            setState(() {
                              if (selectedMode == SelectedMode.Color)
                                showBottomList = !showBottomList;
                              selectedMode = SelectedMode.Color;
                            });
                          }),
                      IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            final sign = _sign.currentState;
                            sign.clear();
                            setState(() {
                              _img = ByteData(0);
                            });
                            debugPrint("cleared");
                          }),
                      IconButton(
                          icon: Icon(Icons.save),
                          onPressed: () async {
                            final sign = _sign.currentState;
                            //retrieve image data, do whatever you want with it (send to server, save locally...)
                            final _image = await sign.getData();

                            var pngBytes = await _image.toByteData(
                                format: ui.ImageByteFormat.png);

                            sign.clear();
                            final encoded =
                                base64.encode(pngBytes.buffer.asUint8List());
                            showImage(context, pngBytes);

                            setState(() {
                              _img = pngBytes;
                              debugPrint("onPressed " + encoded);
                            });
                          }),
                    ],
                  ),
                  Visibility(
                    child: (selectedMode == SelectedMode.Color)
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: getColorList(),
                          )
                        : Slider(
                            value: (selectedMode == SelectedMode.StrokeWidth)
                                ? strokeWidth
                                : opacity,
                            max: (selectedMode == SelectedMode.StrokeWidth)
                                ? 50.0
                                : 1.0,
                            min: 0.0,
                            onChanged: (val) {
                              setState(() {
                                if (selectedMode == SelectedMode.StrokeWidth)
                                  strokeWidth = val;
                                else
                                  opacity = val;
                              });
                            }),
                    visible: showBottomList,
                  ),
                ],
              ),
            )),
      ),
      body: Stack(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(5.0),
            alignment: Alignment.bottomCenter,
            child: VisibilityDetector(
              key: ObjectKey(flickManager),
              onVisibilityChanged: (visibility) {
                if (visibility.visibleFraction == 0 && this.mounted) {
                  flickManager.flickControlManager.autoPause();
                } else if (visibility.visibleFraction == 1) {
                  flickManager.flickControlManager.autoResume();
                }
              },
              child: Center(
                child: FlickVideoPlayer(
                  flickManager: flickManager,
                  preferredDeviceOrientation: [
                    DeviceOrientation.landscapeRight,
                    DeviceOrientation.landscapeLeft
                  ],
                  systemUIOverlay: [],
                  flickVideoWithControls: FlickVideoWithControls(
                    controls: LandscapePlayerControls(),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(5.0),
            height: 300,
            alignment: Alignment.topCenter,
            child: Signature(
              color: color,
              key: _sign,
              onSign: () {
                final sign = _sign.currentState;
                debugPrint('${sign.points.length} points in the signature');
              },
              backgroundPainter:
                  DrawingPainter(pointsList: this.points, watermark: "2.0"),
              strokeWidth: strokeWidth,
            ),
          ),
        ],
      ),
    );
  }

  Future<Null> showImage(BuildContext context, ByteData pngBytes) async {
    //var pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);
    // Use plugin [path_provider] to export image to storage

    if (await Permission.storage.request().isGranted) {
      String path = _downloadsDirectory.path;

      await Directory('$path/videopainter').create(recursive: true);
      File('$path/videopainter/${formattedDate()}.png')
          .writeAsBytesSync(pngBytes.buffer.asInt8List());
      debugPrint('ruta: $path/videopainter/${formattedDate()}.png');
      return showDialog<Null>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'Imagen guardada',
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w300,
                    color: Theme.of(context).primaryColor,
                    letterSpacing: 1.1),
              ),
              content: Image.memory(Uint8List.view(pngBytes.buffer)),
            );
          });
    }
  }

  String formattedDate() {
    DateTime dateTime = DateTime.now();
    String dateTimeString = 'Signature_' +
        dateTime.year.toString() +
        dateTime.month.toString() +
        dateTime.day.toString() +
        dateTime.hour.toString() +
        ':' +
        dateTime.minute.toString() +
        ':' +
        dateTime.second.toString() +
        ':' +
        dateTime.millisecond.toString() +
        ':' +
        dateTime.microsecond.toString();
    return dateTimeString;
  }

  getColorList() {
    List<Widget> listWidget = List();
    for (Color color in colors) {
      listWidget.add(colorCircle(color));
    }
    Widget colorPicker = GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          child: AlertDialog(
            title: const Text('Pick a color!'),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: pickerColor,
                onColorChanged: (color) {
                  pickerColor = color;
                },
                pickerAreaHeightPercent: 0.8,
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: const Text('Save'),
                onPressed: () {
                  setState(() => selectedColor = pickerColor);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
      child: ClipOval(
        child: Container(
          padding: const EdgeInsets.only(bottom: 16.0),
          height: 36,
          width: 36,
          decoration: BoxDecoration(
              gradient: LinearGradient(
            colors: [Colors.red, Colors.green, Colors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )),
        ),
      ),
    );
    listWidget.add(colorPicker);
    return listWidget;
  }

  Widget colorCircle(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = color;
        });
      },
      child: ClipOval(
        child: Container(
          padding: const EdgeInsets.only(bottom: 16.0),
          height: 36,
          width: 36,
          color: color,
        ),
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final String watermark;

  DrawingPainter({this.pointsList, this.watermark});

  List<DrawingPoints> pointsList;
  List<Offset> offsetPoints = List();
  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < pointsList.length - 1; i++) {
      if (pointsList[i] != null && pointsList[i + 1] != null) {
        canvas.drawLine(pointsList[i].points, pointsList[i + 1].points,
            pointsList[i].paint);
      } else if (pointsList[i] != null && pointsList[i + 1] == null) {
        offsetPoints.clear();
        offsetPoints.add(pointsList[i].points);
        offsetPoints.add(Offset(
            pointsList[i].points.dx + 0.1, pointsList[i].points.dy + 0.1));
        canvas.drawPoints(
            ui.PointMode.points, offsetPoints, pointsList[i].paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawingPainter &&
          runtimeType == other.runtimeType &&
          pointsList == other.pointsList &&
          watermark == other.watermark;

  @override
  int get hashCode => pointsList.hashCode ^ watermark.hashCode;
}

class DrawingPoints {
  Paint paint;
  Offset points;
  DrawingPoints({this.points, this.paint});
}

enum SelectedMode { StrokeWidth, Opacity, Color }
