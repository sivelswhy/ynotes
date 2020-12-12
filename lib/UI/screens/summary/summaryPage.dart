import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:badges/badges.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:circular_check_box/circular_check_box.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:html/parser.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:stacked/stacked.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:ynotes/UI/animations/FadeAnimation.dart';
import 'package:ynotes/UI/components/dialogs.dart';
import 'package:ynotes/UI/components/hiddenSettings.dart';
import 'package:ynotes/UI/screens/drawer/drawerBuilderWidgets/drawer.dart';
import 'package:ynotes/UI/screens/grades/gradesPage.dart';
import 'package:ynotes/UI/screens/homework/homeworkPage.dart';
import 'package:ynotes/UI/screens/summary/summaryPageWidgets/quickGrades.dart';
import 'package:ynotes/UI/screens/summary/summaryPageWidgets/summaryPageSettings.dart';
import 'package:ynotes/UI/screens/summary/summaryPageWidgets/chart.dart';
import 'package:ynotes/apis/utils.dart';
import 'package:ynotes/main.dart';
import 'package:ynotes/models/homework/controller.dart';
import 'package:ynotes/usefulMethods.dart';
import 'package:ynotes/utils/themeUtils.dart';

import '../../../classes.dart';

///First page to access quickly to last grades, homework and
class SummaryPage extends StatefulWidget {
  final Function switchPage;

  const SummaryPage({Key key, this.switchPage}) : super(key: key);
  State<StatefulWidget> createState() {
    return SummaryPageState();
  }
}

Future donePercentFuture;
int oldGauge = 0;
Future allGrades;
bool firstStart = true;
GlobalKey _one = GlobalKey();

class SummaryPageState extends State<SummaryPage> {
  double actualPage;
  PageController _pageControllerSummaryPage;
  PageController todoSettingsController;
  bool done2 = false;
  double offset;

  int _slider = 1;
  List items = [1, 2, 3, 4, 5];
  PageController summarySettingsController = PageController(initialPage: 1);
  setGauge() async {
    var tempGauge = await getHomeworkDonePercent();
    setState(() {
      oldGauge = tempGauge ?? 0;
    });
  }

  initState() {
    super.initState();

    todoSettingsController = new PageController(initialPage: 0);
    initialIndexGradesOffset = 0;
    _pageControllerSummaryPage = PageController();
    _pageControllerSummaryPage.addListener(() {
      setState(() {
        actualPage = _pageControllerSummaryPage.page;
        offset = _pageControllerSummaryPage.offset;
      });
    });
    homeworkListFuture = localApi.getNextHomework();
    disciplinesListFuture = localApi.getGrades();
    setState(() {
      donePercentFuture = getHomeworkDonePercent();
    });
    setGauge();
    SchedulerBinding.instance.addPostFrameCallback(!mounted
        ? null
        : (_) => {
              initTransparentLogin().then((var f) {
                if (firstStart == true) {
                  refreshLocalGradesList();
                  firstStart = false;
                }
              })
            });
  }

  void triggerSettings() {
    summarySettingsController.animateToPage(summarySettingsController.page == 1 ? 0 : 1,
        duration: Duration(milliseconds: 300), curve: Curves.ease);
  }

  initTransparentLogin() async {
    await tlogin.init();
  }

  @override
  Future<void> refreshLocalHomeworkList() async {
    setState(() {
      homeworkListFuture = localApi.getNextHomework(forceReload: true);
    });
    var realHW = await homeworkListFuture;
    setState(() {
      donePercentFuture = getHomeworkDonePercent();
    });
  }

  @override
  Future<void> refreshLocalGradesList() async {
    setState(() {
      allGradesOld = null;
      disciplinesListFuture = localApi.getGrades(forceReload: true);
    });
    var realGL = await disciplinesListFuture;
  }

  void refreshCallback() {
    setState(() {
      donePercentFuture = getHomeworkDonePercent();
    });
  }

  showDialog() async {
    await helpDialogs[0].showDialog(context);
    await showUpdateNote();
  }

  showUpdateNote() async {
    if ((!await getSetting("updateNote0.9"))) {
      await CustomDialogs.showUpdateNoteDialog(context);
      await setSetting("updateNote0.9", true);
    }
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData screenSize = MediaQuery.of(context);
    return VisibilityDetector(
      key: Key('sumpage'),
      onVisibilityChanged: (visibilityInfo) {
        var visiblePercentage = visibilityInfo.visibleFraction * 100;
        if (visiblePercentage == 100) {
          showDialog();
        }
      },
      child: HiddenSettings(
          controller: summarySettingsController,
          settingsWidget: SummaryPageSettings(),
          child: ShowCaseWidget(
            builder: Builder(builder: (context) {
              return Container(
                height: screenSize.size.height,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    //First division (gauge)
                    Container(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Color(0xff2c274c),
                              Color(0xff46426c),
                            ]),
                            border: Border.all(width: 0),
                            borderRadius: BorderRadius.circular(12)),
                        margin: EdgeInsets.only(top: screenSize.size.height / 10 * 0.2),
                        child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            color: Colors.transparent,
                            child: Container(
                              color: Colors.transparent,
                              width: screenSize.size.width / 5 * 4.5,
                              height: (screenSize.size.height / 10 * 8.8) / 10 * 2,
                              child: Row(
                                children: [
                                  Container(
                                      color: Colors.transparent,
                                      width: screenSize.size.width / 5 * 4.5,
                                      child: FutureBuilder(
                                          future: disciplinesListFuture,
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData) {
                                              List<Grade> grades = List();
                                              try {
                                                var temp = getAllGrades(snapshot.data);
                                                grades = temp;
                                              } catch (e) {
                                                print("Error while printing " + e.toString());
                                              }
                                              return SummaryChart(grades);
                                            } else {
                                              return SpinKitThreeBounce(
                                                  color: Theme.of(context).primaryColorDark,
                                                  size: screenSize.size.width / 5 * 0.4);
                                            }
                                          }))
                                ],
                              ),
                            ))),
                    //Third division (quick marks)
                    Container(
                      margin: EdgeInsets.only(
                          left: screenSize.size.width / 5 * 0.2, top: screenSize.size.height / 10 * 0.1),
                      child: FutureBuilder(
                          future: disciplinesListFuture,
                          initialData: null,
                          builder: (context, snapshot) {
                            List<Grade> grades = List();
                            try {
                              var temp = getAllGrades(snapshot.data);
                              grades = temp;
                            } catch (e) {
                              print(e.toString());
                            }
                            return QuickGrades(
                              grades: grades,
                              callback: widget.switchPage,
                              refreshCallback: refreshLocalGradesList,
                            );
                          }),
                    ),

                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: EdgeInsets.only(top: screenSize.size.height / 10 * 0.1),
                      color: Theme.of(context).primaryColor,
                      child: Container(
                        margin: EdgeInsets.only(top: screenSize.size.height / 10 * 0.1),
                        width: screenSize.size.width / 5 * 4.5,
                        height: (screenSize.size.height / 10 * 8.8) / 10 * 5.6,
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          child: PageView(
                            controller: todoSettingsController,
                            physics: NeverScrollableScrollPhysics(),
                            children: <Widget>[
                              Stack(
                                children: <Widget>[
                                  Align(
                                      alignment: Alignment.topCenter,
                                      child: Container(
                                        margin: EdgeInsets.only(top: (screenSize.size.height / 10 * 8.8) / 10 * 0.1),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                                width: screenSize.size.width / 5 * 0.5,
                                                height: screenSize.size.width / 5 * 0.5,
                                                child: FittedBox(
                                                  child: FutureBuilder<int>(
                                                      future: donePercentFuture,
                                                      initialData: oldGauge,
                                                      builder: (context, snapshot) {
                                                        return CircularPercentIndicator(
                                                          radius: 120,
                                                          lineWidth: screenSize.size.width / 5 * 0.4,
                                                          percent: (snapshot.data ?? 100) / 100,
                                                          backgroundColor: Colors.orange.shade400,
                                                          animationDuration: 550,
                                                          circularStrokeCap: CircularStrokeCap.round,
                                                          progressColor: Colors.green.shade300,
                                                        );
                                                      }),
                                                )),
                                            Text(
                                              "A faire",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontFamily: "Asap", fontSize: 18, color: ThemeUtils.textColor()),
                                            ),
                                          ],
                                        ),
                                      )),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      margin: EdgeInsets.only(
                                          bottom: (screenSize.size.height / 10 * 8.8) / 10 * 0.2,
                                          top: screenSize.size.height / 10 * 0.1),
                                      height: (screenSize.size.height / 10 * 8.8) / 10 * 4.5,
                                      child: RefreshIndicator(
                                        onRefresh: refreshLocalHomeworkList,
                                        child: CupertinoScrollbar(
                                          child: ViewModelBuilder.reactive(
                                              viewModelBuilder: () => HomeworkController(localApi),
                                              builder: (context, HomeworkController model, child) {
                                                if (model.getHomework != null && model.getHomework.length != 0) {
                                                  return ListView.builder(
                                                      itemCount: model.getHomework.length,
                                                      padding: EdgeInsets.only(
                                                          left: screenSize.size.width / 5 * 0.1,
                                                          right: screenSize.size.width / 5 * 0.1),
                                                      itemBuilder: (context, index) {
                                                        return FutureBuilder(
                                                          initialData: 0,
                                                          future: getColor(model.getHomework[index].codeMatiere),
                                                          builder: (context, color) => Column(
                                                            children: <Widget>[
                                                              if (index == 0 ||
                                                                  model.getHomework[index - 1].date !=
                                                                      model.getHomework[index].date)
                                                                Row(children: <Widget>[
                                                                  Expanded(
                                                                    child: new Container(
                                                                        margin: const EdgeInsets.only(
                                                                            left: 10.0, right: 20.0),
                                                                        child: Divider(
                                                                          color: ThemeUtils.textColor(),
                                                                          height: 36,
                                                                        )),
                                                                  ),
                                                                  Text(
                                                                    DateFormat("EEEE d MMMM", "fr_FR")
                                                                        .format(model.getHomework[index].date)
                                                                        .toString(),
                                                                    style: TextStyle(
                                                                        color: ThemeUtils.textColor(),
                                                                        fontFamily: "Asap"),
                                                                  ),
                                                                  Expanded(
                                                                    child: Container(
                                                                        margin: const EdgeInsets.only(
                                                                            left: 20.0, right: 10.0),
                                                                        child: Divider(
                                                                          color: ThemeUtils.textColor(),
                                                                          height: 36,
                                                                        )),
                                                                  ),
                                                                ]),
                                                              HomeworkTicket(
                                                                  model.getHomework[index],
                                                                  Color(color.data),
                                                                  widget.switchPage,
                                                                  refreshCallback),
                                                            ],
                                                          ),
                                                        );
                                                      });
                                                } else {
                                                  return FittedBox(
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: <Widget>[
                                                        Container(
                                                          height: (screenSize.size.height / 10 * 8.8) / 10 * 1.5,
                                                          child: Image(
                                                              fit: BoxFit.fitWidth,
                                                              image: AssetImage('assets/images/noHomework.png')),
                                                        ),
                                                        Text(
                                                          "Pas de devoirs à l'horizon... \non se détend ?",
                                                          textAlign: TextAlign.center,
                                                          style: TextStyle(
                                                              fontFamily: "Asap",
                                                              color: ThemeUtils.textColor(),
                                                              fontSize: (screenSize.size.height / 10 * 8.8) / 10 * 0.2),
                                                        ),
                                                        FlatButton(
                                                            onPressed: () async {
                                                              //Reload list
                                                              await model.refresh(force: true);
                                                            },
                                                            child: Text("Recharger",
                                                                style: TextStyle(
                                                                  fontFamily: "Asap",
                                                                  color: ThemeUtils.textColor(),
                                                                )))
                                                      ],
                                                    ),
                                                  );
                                                }
                                              }),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          )),
    );
  }
}

//The basic ticket for homeworks with the discipline and the description and a checkbox
class HomeworkTicket extends StatefulWidget {
  final Homework _homework;
  final Color color;
  final Function refreshCallback;

  final Function pageSwitcher;
  const HomeworkTicket(this._homework, this.color, this.pageSwitcher, this.refreshCallback);
  State<StatefulWidget> createState() {
    return _HomeworkTicketState();
  }
}

class _HomeworkTicketState extends State<HomeworkTicket> {
  @override
  Widget build(BuildContext context) {
    MediaQueryData screenSize = MediaQuery.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: (screenSize.size.height / 10 * 8.8) / 10 * 0.1),
      child: Material(
        color: widget.color,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            widget.pageSwitcher(4);
          },
          onLongPress: !widget._homework.loaded
              ? null
              : () async {
                  await CustomDialogs.showHomeworkDetailsDialog(context, this.widget._homework);
                  setState(() {});
                },
          child: Container(
            width: screenSize.size.width / 5 * 4.3,
            height: (screenSize.size.height / 10 * 8.8) / 10 * 0.8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(39),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: screenSize.size.width / 5 * 0.8,
                  child: FutureBuilder(
                      future: offline.doneHomework.getHWCompletion(widget._homework.id ?? ''),
                      initialData: false,
                      builder: (context, snapshot) {
                        bool done = snapshot.data;
                        return CircularCheckBox(
                          activeColor: Colors.blue,
                          inactiveColor: Colors.white,
                          value: done,
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                          onChanged: (bool x) async {
                            setState(() {
                              done = !done;
                              donePercentFuture = getHomeworkDonePercent();
                              widget.refreshCallback();
                            });
                            offline.doneHomework.setHWCompletion(widget._homework.id, x);
                          },
                        );
                      }),
                ),
                FittedBox(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                          width: screenSize.size.width / 5 * 2.8,
                          child: Row(
                            children: [
                              Container(
                                width: screenSize.size.width / 5 * 2.4,
                                child: AutoSizeText(widget._homework.matiere,
                                    textScaleFactor: 1.0,
                                    textAlign: TextAlign.left,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 14, fontFamily: "Asap", fontWeight: FontWeight.bold)),
                              ),
                              if (!widget._homework.loaded)
                                Container(
                                    width: screenSize.size.width / 5 * 0.4,
                                    child: FittedBox(
                                      child: SpinKitThreeBounce(
                                        color: darken(widget.color),
                                      ),
                                    )),
                            ],
                          )),
                      if (widget._homework.loaded)
                        Container(
                          width: screenSize.size.width / 5 * 2.8,
                          child: AutoSizeText(
                            parse(widget._homework.contenu ?? "").documentElement.text,
                            style: TextStyle(fontFamily: "Asap"),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sample data type.
class GaugeSegment {
  final String segment;
  final int size;
  final Color color;

  GaugeSegment(this.segment, this.size, this.color);
}

//Homework done percent
Future<int> getHomeworkDonePercent() async {
  List list = await getReducedListHomework();
  if (list != null) {
    //Number of elements in list
    int total = list.length;
    if (total == 0) {
      return 100;
    } else {
      int done = 0;

      await Future.forEach(list, (element) async {
        bool isDone = await offline.doneHomework.getHWCompletion(element.id);
        if (isDone) {
          done++;
        }
      });
      print(done);
      int percent = (done * 100 / total).round();

      return percent;
    }
  } else {
    return 100;
  }
}

Future<List<Homework>> getReducedListHomework() async {
  int reduce = await getIntSetting("summaryQuickHomework");
  if (reduce == 11) {
    reduce = 770;
  }
  List<Homework> localList = await localApi.getNextHomework();
  if (localList != null) {
    List<Homework> listToReturn = List<Homework>();
    localList.forEach((element) {
      var now = DateTime.now();
      var date = element.date;

      //ensure that the list doesn't contain the pinned homework
      if (date.difference(now).inDays < reduce &&
          date.isAfter(DateTime.parse(DateFormat("yyyy-MM-dd").format(DateTime.now())))) {
        listToReturn.add(element);
      }
    });
    print(listToReturn.length);
    return listToReturn;
  } else {
    return null;
  }
}
