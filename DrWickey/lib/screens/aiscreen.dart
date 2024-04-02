import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';

import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/material.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen>
    with SingleTickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  stt.SpeechToText speech = stt.SpeechToText();

  bool speechEnabled = false;
  String wordsRec = "";
  int faceState = 0;

  var client = http.Client();
  String svUrl = "http://192.168.11.123:8000/ai";
  var headers = {};
  var reply = "";

  var tmp1 = "";
  var tmp2 = "";

  var rCount = 0;
  List<String> words = [];

  bool isComplete = false;
  bool speak = false;

  TextEditingController _txtControl = TextEditingController();

  var alt = const AssetImage('assets/images/alt.png');
  var thinking = const AssetImage('assets/images/thinking.png');
  var happy = const AssetImage('assets/images/happy.png');
  List<AssetImage> faceStates = [];

  http.Request genReq(String reqStr) {
    http.Request request = http.Request("POST", Uri.parse(svUrl));
    request.headers['Accept'] = "text/event-stream";
    request.headers['Cache-Control'] = "no-cache";
    request.headers['Content-type'] = "application/json";
    request.body = '{"keyword":"$reqStr"}';
    return request;
  }

  void sendReq(String reqStr) async {
    reply = "";
    rCount = 0;
    words = [];
    tmp1 = "";
    tmp2 = "";
    isComplete = false;
    var req = genReq(reqStr);
    flutterTts.stop();
    Future<http.StreamedResponse> response = client.send(req);
    response.then((streamedResponse) async {
      streamedResponse.stream.listen((value) async {
        final parsedData = utf8.decode(value);
        if (parsedData != "#") {
          setState(() {
            reply += parsedData;
          });
        } else {
          setState(() {
            faceState = 2;
            if (speak) {
              flutterTts.speak(reply);
            }
          });
        }
      });
    });
  }

  void initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0); // 0.5 -> 1.5
    await flutterTts.awaitSpeakCompletion(true);
    flutterTts.setCompletionHandler(() {
      if (!isComplete) {
        setState(() {
          tmp2 = tmp1;
          words.add(tmp1);
          tmp1 = "";
        });
      } else {
        flutterTts.speak(tmp1);
        isComplete = false;
      }
    });
  }

  void initSpeech() async {
    speechEnabled = await speech.initialize();
    setState(() {});
  }

  void onSpeechResult(result) {
    setState(() {
      wordsRec = result.recognizedWords;
      _txtControl.text = wordsRec;
    });
  }

  void startListening() {
    // ignore: deprecated_member_use
    speech.listen(onResult: onSpeechResult, partialResults: false);
    setState(() {});
  }

  void stopListening() async {
    await speech.stop();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    initSpeech();
    initTts();
    faceStates = [alt, thinking, happy];
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            speak = !speak;
          });
        },
        child: Icon(speak ? Icons.speaker : Icons.speaker_notes_off),
      ),
      backgroundColor: const Color(0xffffffff),
      body: Column(children: [
        Text("Currently connected to $svUrl"),
        Padding(
          padding: const EdgeInsets.all(40.0),
          child: Row(
            children: [
              Text(
                "Dr.",
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 32),
              ),
              const Text(
                "Wickey",
                style: TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 32),
              )
            ],
          ),
        ),
        Center(
          child: emotionIndicator(),
        ),
        Expanded(
            child: Padding(
          padding: const EdgeInsets.only(right: 100, left: 100),
          child: SingleChildScrollView(
            child: Text(
              faceState == 1 ? "$reply ⬤" : reply,
              style: TextStyle(
                fontSize: 40,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        )),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(30.0),
            ),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextField(
                  controller: _txtControl,
                  onChanged: (value) => wordsRec = value,
                  decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      hintText: 'Your query here'),
                ),
              ),
              Row(
                children: [
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Stack(children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: ProcessIndicator(),
                      ),
                      Container(
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.deepPurpleAccent, width: 2),
                            shape: BoxShape.circle),
                        child: IconButton(
                          onPressed: () {
                            speech.isNotListening
                                ? startListening()
                                : stopListening();
                          },
                          icon: Icon(
                            speech.isNotListening
                                ? Icons.mic_rounded
                                : Icons.stop,
                            color: speech.isNotListening
                                ? Colors.deepPurpleAccent
                                : Colors.grey.shade400,
                          ),
                          iconSize: 70,
                        ),
                      ),
                    ]),
                  ),
                  const Spacer()
                ],
              ),
              IconButton(
                  onPressed: () {
                    setState(() {
                      faceState = 1;
                      wordsRec != ""
                          ? sendReq(wordsRec)
                          : print("empty string");
                    });
                  },
                  icon: const Icon(
                    Icons.send,
                    color: Colors.deepPurpleAccent,
                  ))
            ]),
          ),
        ),
      ]),
    );
  }

  Image emotionIndicator() {
    return Image(
      image: faceStates[faceState],
      width: 400,
    );
  }

  Widget ProcessIndicator() {
    if (faceState == 1) {
      return const CircularProgressIndicator(
        color: Colors.deepPurpleAccent,
        strokeWidth: 4,
      );
    } else {
      return Container();
    }
  }
}
