import 'dart:io';
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:typed_data';

import 'package:animated_floatactionbuttons/animated_floatactionbuttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_widgets/flutter_widgets.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

import 'flutter_signature_pad.dart';

class VideoPainter extends StatefulWidget {
  VideoPainter({Key key}) : super(key: key);

  @override
  _VideoPainterState createState() => _VideoPainterState();
}

class _VideoPainterState extends State<VideoPainter> {
  Color colorPincel = Colors.lightBlue;
  ByteData _img = ByteData(0);
  int _pos = 0;

  List<DrawingPoints> points = List();
  bool showBottomList = false;
  double opacity = 1.0;
  StrokeCap strokeCap = (Platform.isAndroid) ? StrokeCap.butt : StrokeCap.round;
  SelectedMode selectedMode = SelectedMode.StrokeWidth;

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
    // Listen to changes in the video to re-render the controls.
    flickManager.flickVideoManager.addListener(_videoListener);
  }

  _videoListener() {
    // Re-render the widget to update the controls.
    setState(() {});
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
    // Remove the listener.
    flickManager.flickVideoManager.removeListener(_videoListener);
    flickManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: AnimatedFloatingActionButton(
        //Creating menu items
        fabButtons: fabOption(),

        //Color shown when animation starts
        colorStartAnimation: Colors.blue,

        //Color shown when animation ends
        colorEndAnimation: Colors.cyan,

        //Icon for FAB
        animatedIconData: AnimatedIcons.menu_close,
      ),
      body: Stack(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FlatButton(
                textColor: Color(0xFF6200EE),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Cancelar"),
              ),
              FlatButton(
                textColor: Color(0xFF6200EE),
                onPressed: () {
                  // Respond to button press
                },
                child: Text("Video"),
              ),
              FlatButton(
                textColor: Color(0xFF6200EE),
                onPressed: () {
                  // Respond to button press
                },
                child: Text("OK"),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.all(35.0),
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
                  flickVideoWithControls: FlickVideoWithControls(
                    controls: Container(),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(35.0),
            //height: 200,
            alignment: Alignment.topCenter,
            child: Signature(
              color: this.colorPincel,
              key: _sign,
              onSign: () {
                final sign = _sign.currentState;
                //debugPrint('${sign.points.length} points in the signature');
              },
              backgroundPainter:
                  DrawingPainter(pointsList: this.points, watermark: "2.0"),
            ),
          ),
        ],
      ),
    );
  }

  Widget colorMenuItem(Color color) {
    return GestureDetector(
      onTap: () {
        debugPrint("cambiado color a " + color.toString());
      },
      child: ClipOval(
        child: Container(
          padding: const EdgeInsets.only(bottom: 5.0),
          height: 36,
          width: 36,
          color: color,
        ),
      ),
    );
  }

  List<Widget> fabOption() {
    return <Widget>[
      FloatingActionButton(
          mini: true,
          heroTag: "clearDraw",
          tooltip: "Limpiar",
          child: Icon(Icons.clear),
          onPressed: () {
            final sign = _sign.currentState;
            sign.clear();
            setState(() {
              _img = ByteData(0);
            });
            debugPrint("cleared");
          }),
      FloatingActionButton(
          mini: true,
          heroTag: "saveDraw",
          tooltip: "Guardar",
          child: Icon(Icons.save),
          onPressed: () async {
            final sign = _sign.currentState;
            //retrieve image data, do whatever you want with it (send to server, save locally...)
            final _image = await sign.getData();

            var pngBytes =
                await _image.toByteData(format: ui.ImageByteFormat.png);

            sign.clear();
            Duration duration =
                flickManager.flickVideoManager.videoPlayerValue.position;
            debugPrint("posicion imagen en video:" +
                duration.inMilliseconds.toString());
            final encoded = base64.encode(pngBytes.buffer.asUint8List());
            showImage(context, pngBytes);

            setState(() {
              _img = pngBytes;
              _pos = duration.inMilliseconds;
              debugPrint("onPressed (encoded):" + encoded);
            });
          }),
      //FAB for picking red color
      FloatingActionButton(
        mini: true,
        backgroundColor: Colors.blue,
        heroTag: "color_red",
        child: colorMenuItem(Colors.red),
        tooltip: 'Color',
        onPressed: () {
          final sign = _sign.currentState;
          sign.changeColor(Colors.red);
          this.colorPincel = Colors.red;
        },
      ),

      //FAB for picking green color
      /*FloatingActionButton(
        mini: true,
        backgroundColor: Colors.blue,
        heroTag: "color_green",
        child: colorMenuItem(Colors.green),
        tooltip: 'Color',
        onPressed: () {},
      ),*/
      FloatingActionButton(
        mini: true,
        heroTag: "pauseVideo",
        child: FloatingButtonChild(
          isPlaying: flickManager.flickVideoManager.isPlaying,
        ),
        onPressed: () {
          flickManager.flickControlManager.togglePlay();
          Duration duration =
              flickManager.flickVideoManager.videoPlayerValue.position;
          debugPrint("posicion video:" + duration.inMilliseconds.toString());
        },
      ),
      FloatingActionButton(
          mini: true,
          heroTag: "replayVideo",
          tooltip: "Recargar",
          child: Icon(Icons.refresh),
          onPressed: () async {
            flickManager.flickControlManager.replay();
          }),
    ];
  }

  Future<Null> showImage(BuildContext context, ByteData pngBytes) async {
    //var pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);
    // Use plugin [path_provider] to export image to storage

    if (await Permission.storage.request().isGranted) {
      String path = _downloadsDirectory.path;

      await Directory('$path/videopainter').create(recursive: true);
      File('$path/videopainter/${formattedDate()}.png')
          .writeAsBytesSync(pngBytes.buffer.asInt8List());
      String ruta = "$path/videopainter/${formattedDate()}.png";
      debugPrint('ruta: $ruta');
      debugPrint(
          'imagen:SS' + Uint8List.view(pngBytes.buffer).toString() + 'EE');
      Map map = {"ruta": ruta, "posicion": _pos};
      String opJson = json.encode(map);
      debugPrint('JSON:' + opJson);
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
    String dateTimeString = 'CapturaVideo_' +
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

class FloatingButtonChild extends StatelessWidget {
  const FloatingButtonChild({Key key, this.isPlaying}) : super(key: key);
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return isPlaying ? Icon(Icons.pause) : Icon(Icons.play_arrow);
  }
}
