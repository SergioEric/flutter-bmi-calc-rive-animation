import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';

void main() {
  if (Platform.isAndroid) {
    // we hide the horrible dark area behind the statusBar on Android
    // and we handle the appBar with the preferredSize Widget
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }
  runApp(MyApp());
}

const primaryColor = Color(0xFFFF3636);
const darkerOnPrimary = Color(0xFFDE1B1B);

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMI Rive Animation',
      theme: ThemeData(
        primaryColor: primaryColor,
        sliderTheme: SliderThemeData(
          activeTickMarkColor: primaryColor,
          activeTrackColor: primaryColor,
          thumbColor: darkerOnPrimary,
          inactiveTrackColor: primaryColor.withOpacity(0.2),
        ),
        //use your own fonts, or googleFont package
        fontFamily: "Montserrat",
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  SimpleAnimation smile, sad;

  Artboard _artboard;

  int _height = 142; // cm
  int _weight = 50; // kg

  final ValueNotifier<String> _classification = ValueNotifier("");
  final ValueNotifier<double> _bmiScore = ValueNotifier(-1);

  @override
  void initState() {
    _loadRiveFile();
    super.initState();
  }

  void _loadRiveFile() async {
    //
    final data = await rootBundle.load('assets/drop.riv');
    //
    final file = RiveFile();
    if (file.import(data)) {
      final artboard = file.mainArtboard;

      artboard.addController(SimpleAnimation('onEnter'));

      artboard.addController(smile = SimpleAnimation('smile'));
      artboard.addController(sad = SimpleAnimation('sad'));

      // on enter this view, smile and sad won't be played
      smile.isActive = false;
      sad.isActive = false;

      setState(() => _artboard = artboard);
    }
  }

  // we keep the old mix animation state to avoid unnecessary execution
  bool _oldState;

  void _toggleAnimation(bool state) {
    if (_oldState == state) return;

    _oldState = state;
    if (state) {
      smile.isActive = true;
      sad.instance.reset();
      return;
    }
    sad.isActive = true;
    smile.instance.reset();
  }

  /// weight in Kg, and height in cm
  double _bmi(int w, int h) => (w / math.pow(h / 100, 2));

  void _classificationOfBmi() {
    //
    final bmi = _bmi(_weight, _height);
    _bmiScore.value = bmi;

    if (bmi >= 0 && bmi < 18.50) {
      // "Under weight"
      _toggleAnimation(false);
      _classification.value = "Under weight";
    } else if (bmi >= 18.5 && bmi <= 24.99) {
      // normal
      _toggleAnimation(true); // *smiley face
      _classification.value = "Normal";
    } else if (bmi >= 25.00 && bmi <= 29.99) {
      //Pre-obesity
      _toggleAnimation(false);
      _classification.value = "Pre-obesity";
    } else if (bmi >= 30) {
      //Obesity
      _toggleAnimation(false);
      _classification.value = "Obesity";
    } else {
      // incorrect value
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: size.height * 0.15,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  "Healthy?",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 3 / 1.5,
            child: _artboard != null
                ? Rive(
                    artboard: _artboard,
                    fit: BoxFit.contain,
                  )
                : const SizedBox(),
          ),
          BuildResultBox(
            bmiScore: _bmiScore,
            classification: _classification,
          ),
          buildWeightMeasureSlider(),
          buildHeighMeasuretSlider(),
        ],
      ),
    );
  }

  static const _titleOfSliderStyle = TextStyle(
    color: primaryColor,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const _measureOfSliderStyle = TextStyle(
    color: Color(0xff9F9F9F),
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  static const _valueOfSliderStyle = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  Widget buildWeightMeasureSlider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      padding: const EdgeInsets.only(top: 25, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor,
          width: 0.6,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Weight",
                style: _titleOfSliderStyle,
              ),
              const SizedBox(width: 12),
              Text(
                "$_weight",
                style: _valueOfSliderStyle,
              ),
              const SizedBox(width: 2),
              const Text(
                "Kg",
                style: _measureOfSliderStyle,
              ),
            ],
          ),
          Slider(
            value: _weight.toDouble(),
            min: 15,
            max: 100,
            // label: "${_height.toStringAsFixed(0)}",
            onChanged: (value) {
              setState(() {
                _weight = value.toInt();
              });
              _classificationOfBmi();
            },
          ),
        ],
      ),
    );
  }

  Widget buildHeighMeasuretSlider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      padding: const EdgeInsets.only(top: 25, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor,
          width: 0.6,
        ),
      ),
      child: Column(
        children: [
          // Text("${_height.toStringAsFixed(0)}"),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Height",
                style: _titleOfSliderStyle,
              ),
              const SizedBox(width: 12),
              Text(
                "$_height",
                style: _valueOfSliderStyle,
              ),
              const SizedBox(width: 2),
              const Text(
                "Cm",
                style: _measureOfSliderStyle,
              ),
            ],
          ),
          Slider(
            value: _height.toDouble(),
            min: 15,
            max: 200,
            // label: "${_height.toStringAsFixed(0)}",
            onChanged: (value) {
              setState(() {
                _height = value.toInt();
              });
              _classificationOfBmi();
            },
          ),
        ],
      ),
    );
  }
}

const headTitleStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w900,
);

const valueStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w900,
  color: primaryColor,
);

const borderColor = Color(0xff131313);

class BuildResultBox extends StatelessWidget {
  const BuildResultBox({
    Key key,
    this.bmiScore,
    this.classification,
  }) : super(key: key);

  final ValueListenable<double> bmiScore;
  final ValueListenable<String> classification;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Table(
        border: TableBorder(
          verticalInside: BorderSide(
            color: borderColor,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: primaryColor.withAlpha(5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
                bottomLeft: Radius.circular(5),
                bottomRight: Radius.circular(5),
              ),
              border: Border.all(color: borderColor, width: 2),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "BMI Score",
                      style: headTitleStyle,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    ValueListenableBuilder(
                      valueListenable: bmiScore,
                      builder: (_, double bmi, __) {
                        if (bmi == -1)
                          return Text(
                            "0",
                            style: valueStyle,
                          );
                        return Text(
                          "${bmi.toStringAsFixed(2)}",
                          style: valueStyle,
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Classification",
                          style: headTitleStyle,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    ValueListenableBuilder(
                      valueListenable: classification,
                      builder: (_, String value, __) {
                        return Text(
                          "$value",
                          style: valueStyle,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
