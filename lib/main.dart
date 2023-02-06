import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:neumorphic_test/rock_paper_scissors_icons.dart';
import 'package:rxdart/rxdart.dart';

enum Status {
  init,
  playing,
  judge,
  prise,
  win,
  draw,
  lose,
}

final handIcons = [
  RockPaperScissors.rock,
  RockPaperScissors.scissors,
  RockPaperScissors.paper,
];
final bonusCounts = [20, 1, 7, 4, 10, 2, 5, 1];
final alignments = [
  Alignment.topCenter,
  const Alignment(0.7, -0.7),
  Alignment.centerRight,
  const Alignment(0.7, 0.7),
  Alignment.bottomCenter,
  const Alignment(-0.7, 0.7),
  Alignment.centerLeft,
  const Alignment(-0.7, -0.7)
];

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const NeumorphicApp(
      debugShowCheckedModeBanner: false,
      title: 'Rock Paper Scissors Fever',
      themeMode: ThemeMode.light,
      theme: NeumorphicThemeData(
          defaultTextColor: Color(0xFF303E57),
          accentColor: Color(0xFF7B79FC),
          variantColor: Colors.black38,
          baseColor: Color(0xFFF8F9FC),
          depth: 8,
          intensity: 0.5,
          lightSource: LightSource.topLeft),
      home: Material(
        child: NeumorphicBackground(
          child: MyHomePage(),
        ),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: MainContent(),
    );
  }
}

class MainContent extends StatefulWidget {
  const MainContent({super.key});

  @override
  MainContentState createState() => MainContentState();
}

class MainContentState extends State<MainContent> {
  final random = Random();

  final _onCoinCountsChange = BehaviorSubject<int>.seeded(20);
  final _onBonusIndexChange = BehaviorSubject<int>.seeded(9);
  final _onPHandIndexChange = BehaviorSubject<int>.seeded(9);
  final _onEHandIndexChange = BehaviorSubject<int>.seeded(0);
  final _onStatusChange = BehaviorSubject<Status>.seeded(Status.init);

  @override
  void initState() {
    _onStatusChange.stream.listen((event) async {
      switch (event) {
        case Status.playing:
          play();
          break;
        case Status.judge:
          judge();
          break;
        case Status.draw:
          Future.delayed(const Duration(milliseconds: 1500), () {
            _onCoinCountsChange.sink.add(_onCoinCountsChange.stream.value + 1);
            _onStatusChange.sink.add(Status.playing);
          });
          break;
        case Status.prise:
          prise();
          break;
        case Status.win:
          break;
        case Status.lose:
          break;
        case Status.init:
          // TODO: Handle this case.
          break;
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _onCoinCountsChange.close();
    _onBonusIndexChange.close();
    _onPHandIndexChange.close();
    _onEHandIndexChange.close();
    _onStatusChange.close();
    super.dispose();
  }

  void play({bool isFree = false}) {
    _onPHandIndexChange.sink.add(9);
    _onBonusIndexChange.sink.add(9);
    _onEHandIndexChange.sink.add(random.nextInt(handIcons.length));
    if (!isFree) {
      _onCoinCountsChange.sink.add(_onCoinCountsChange.stream.value - 1);
    }
  }

  void judge() {
    if (_onPHandIndexChange.stream.value == _onEHandIndexChange.stream.value) {
      _onStatusChange.sink.add(Status.draw);
    } else if ((_onPHandIndexChange.stream.value == 2 &&
            _onEHandIndexChange.stream.value == 0) ||
        _onEHandIndexChange.stream.value - _onPHandIndexChange.stream.value ==
            1) {
      _onStatusChange.sink.add(Status.prise);
    } else {
      _onStatusChange.sink.add(Status.lose);
    }
  }

  void prise() async {
    int value = await roulette();
    _onCoinCountsChange.sink
        .add(_onCoinCountsChange.stream.value + bonusCounts[value]);
  }

  Future<int> roulette() async {
    int bIndex = random.nextInt(bonusCounts.length);
    int moveCount = 10 + random.nextInt(8);
    int interval = 300;
    int ticks = bIndex + moveCount;

    Timer.periodic(Duration(milliseconds: interval), (Timer timer) {
      if (ticks == bIndex) {
        timer.cancel();
      } else {
        ticks -= 1;
        _onBonusIndexChange.sink.add(ticks % bonusCounts.length);
      }
    });

    await Future.delayed(Duration(milliseconds: interval * moveCount));
    _onStatusChange.sink.add(Status.win);
    return bIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: _buildTitle(context),
        ),
        Flexible(
          child: Display(
            bonusIndexStream: _onBonusIndexChange.stream,
            eHandIndexStream: _onEHandIndexChange.stream,
            statusStream: _onStatusChange.stream,
            eHandIndexSink: _onEHandIndexChange.sink,
            statusSink: _onStatusChange.sink,
          ),
        ),
        const SizedBox(height: 20),
        _buildHandButtons(context),
        const SizedBox(height: 20),
        PlayButton(
          coinCountsStream: _onCoinCountsChange.stream,
          statusStream: _onStatusChange.stream,
          statusSink: _onStatusChange.sink,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
    return NeumorphicText(
      "Rock Paper Scissors Fever",
      style: NeumorphicStyle(
        depth: 1, //customize depth here
        color: NeumorphicTheme.defaultTextColor(context), //customize color here
      ),
      textStyle: NeumorphicTextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildHandButtons(BuildContext context) {
    final List<Widget> children = List.generate(
        3,
        (index) => HandButton(
              index: index,
              pHandIndexStream: _onPHandIndexChange.stream,
              statusStream: _onStatusChange.stream,
              pHandIndexSink: _onPHandIndexChange.sink,
              statusSink: _onStatusChange.sink,
            ));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: children,
    );
  }
}

class Display extends StatelessWidget {
  final Stream<int> bonusIndexStream;
  final Stream<int> eHandIndexStream;
  final Stream<Status> statusStream;
  final StreamSink<int> eHandIndexSink;
  final StreamSink<Status> statusSink;

  const Display({
    super.key,
    required this.bonusIndexStream,
    required this.eHandIndexStream,
    required this.statusStream,
    required this.eHandIndexSink,
    required this.statusSink,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = List<Widget>.generate(9, (index) {
      if (index == 8) {
        return Neumorphic(
          style: const NeumorphicStyle(
            depth: 14,
            boxShape: NeumorphicBoxShape.circle(),
          ),
          margin: const EdgeInsets.all(50),
          child: Neumorphic(
            style: const NeumorphicStyle(
              depth: -8,
              boxShape: NeumorphicBoxShape.circle(),
            ),
            margin: const EdgeInsets.all(10),
            child: StreamBuilder(
              initialData: Status.init,
              stream: statusStream,
              builder: (BuildContext context, AsyncSnapshot<Status> sSnapShot) {
                return Center(
                  child: StreamBuilder(
                    initialData: 0,
                    stream: eHandIndexStream,
                    builder:
                        (BuildContext context, AsyncSnapshot<int> eSnapShot) {
                      return LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraint) {
                          return _buildHands(
                            context,
                            constraint,
                            sSnapShot.data,
                            eSnapShot.data,
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );
      }
      return Align(
        alignment: alignments[index],
        child: _createNumber(context, index),
      );
    });

    return AspectRatio(
      aspectRatio: 1,
      child: Neumorphic(
        margin: const EdgeInsets.all(14),
        style: const NeumorphicStyle(
          boxShape: NeumorphicBoxShape.circle(),
        ),
        child: Stack(
          children: children,
        ),
      ),
    );
  }

  Widget _createNumber(BuildContext context, int index) {
    return Neumorphic(
      margin: const EdgeInsets.all(8.0),
      style: const NeumorphicStyle(
        depth: 0,
      ),
      child: StreamBuilder(
        initialData: 9,
        stream: bonusIndexStream,
        builder: (BuildContext context, AsyncSnapshot<int> snapShot) {
          return Text(
            "${bonusCounts[index]}",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 32,
              shadows: const [
                Shadow(
                    color: Colors.black38,
                    offset: Offset(1.0, 1.0),
                    blurRadius: 2)
              ],
              color: snapShot.data == index
                  ? NeumorphicTheme.accentColor(context)
                  : NeumorphicTheme.baseColor(context),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHands(BuildContext context, BoxConstraints constraint,
      Status? status, int? eHandIndex) {
    final double iconMargin = Platform.isAndroid ? 40.0 : 100.0;
    final List<Widget> children = List.generate(4, (index) {
      return Opacity(
        opacity:
            (index < 3 && status != Status.playing && eHandIndex == index) ||
                    (index == 3 && status == Status.playing)
                ? 1.0
                : 0.0,
        child: NeumorphicIcon(
          index == 3 ? Icons.help_outline : handIcons[index],
          size: constraint.biggest.width - iconMargin,
          style: NeumorphicStyle(
            color:
                (index != 3) && (status == Status.lose || status == Status.draw)
                    ? NeumorphicTheme.accentColor(context)
                    : NeumorphicTheme.baseColor(context),
          ),
        ),
      );
    });

    return Stack(
      children: children,
    );
  }
}

class HandButton extends StatelessWidget {
  final int index;
  final Stream<int> pHandIndexStream;
  final Stream<Status> statusStream;
  final StreamSink<int> pHandIndexSink;
  final StreamSink<Status> statusSink;

  const HandButton({
    super.key,
    required this.index,
    required this.pHandIndexStream,
    required this.statusStream,
    required this.pHandIndexSink,
    required this.statusSink,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      initialData: Status.init,
      stream: statusStream,
      builder: (BuildContext context, AsyncSnapshot<Status> sSnapShot) {
        return NeumorphicButton(
          onPressed: () {
            if (sSnapShot.data == Status.playing) {
              pHandIndexSink.add(index);
              statusSink.add(Status.judge);
            }
          },
          style: const NeumorphicStyle(
            intensity: 0.8,
            shape: NeumorphicShape.convex,
            boxShape: NeumorphicBoxShape.circle(),
          ),
          child: StreamBuilder(
            initialData: 9,
            stream: pHandIndexStream,
            builder: (BuildContext context, AsyncSnapshot<int> pSnapShot) {
              return NeumorphicIcon(
                handIcons[index],
                size: 60,
                style: NeumorphicStyle(
                  intensity: 0.8,
                  color: sSnapShot.data == Status.playing ||
                          ((sSnapShot.data == Status.prise ||
                                  sSnapShot.data == Status.win ||
                                  sSnapShot.data == Status.draw) &&
                              pSnapShot.data == index)
                      ? NeumorphicTheme.accentColor(context)
                      : NeumorphicTheme.baseColor(context),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class PlayButton extends StatelessWidget {
  final Stream<int> coinCountsStream;
  final Stream<Status> statusStream;
  final StreamSink<Status> statusSink;

  const PlayButton({
    super.key,
    required this.coinCountsStream,
    required this.statusStream,
    required this.statusSink,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      initialData: Status.init,
      stream: statusStream,
      builder: (BuildContext context, AsyncSnapshot<Status> snapShot) {
        return NeumorphicButton(
          style: const NeumorphicStyle(
            intensity: 0.8,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 14.0),
          onPressed: snapShot.data == Status.playing ||
                  snapShot.data == Status.draw ||
                  snapShot.data == Status.prise
              ? null
              : () => statusSink.add(Status.playing),
          child: _buildText(context),
        );
      },
    );
  }

  Widget _buildText(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StreamBuilder(
          initialData: 20,
          stream: coinCountsStream,
          builder: (BuildContext context, AsyncSnapshot<int> snapShot) {
            return Text(
              "${snapShot.data}",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 36,
                shadows: const [
                  Shadow(
                      color: Colors.black38,
                      offset: Offset(1.0, 1.0),
                      blurRadius: 2)
                ],
                color: NeumorphicTheme.defaultTextColor(context),
              ),
            );
          },
        ),
      ],
    );
  }
}
