import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter/scheduler.dart';
import 'package:flutter_responsive_breakpoints/flutter_responsive_breakpoints.dart';
import 'package:ynotes/globals.dart';
import 'package:ynotes/ui/components/dialogs.dart';
import 'package:ynotes/ui/components/y_page/mixins.dart';
import 'package:ynotes/ui/components/y_page/y_page.dart';
import 'package:ynotes/ui/screens/summary/widgets/administrative_data.dart';
import 'package:ynotes_packages/components.dart' hide YPage;
import 'widgets/average.dart';
import 'data/constants.dart';
import 'widgets/last_grades.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({
    Key? key,
  }) : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return SummaryPageState();
  }
}

class SummaryPageState extends State<SummaryPage> with YPageMixin {
  bool firstStart = true;
  List<Widget> pages = [
    const SummaryAverage(),
    const SummaryLastGrades(),
    YVerticalSpacer(1.2.vh),
    const SummaryAdministrativeData()
  ];

  @override
  Widget build(BuildContext context) {
    return YPage(
        title: "Résumé",
        body: RefreshIndicator(
          onRefresh: () async {},
          child: Padding(
              padding: EdgeInsets.symmetric(vertical: sidePadding),
              child: Column(
                children: const [
                  SummaryAverage(),
                  SummaryLastGrades(),
                  YVerticalSpacer(40),
                  SummaryAdministrativeData()
                ],
              )),
        ));
  }

  initLoginController() async {
    await appSys.loginController.init();
  }

  @override
  initState() {
    super.initState();

    //Init controllers
    SchedulerBinding.instance!.addPostFrameCallback((!mounted
        ? null
        : (_) {
            showUpdateNote();
            refreshControllers(force: false);
            if (firstStart) {
              initLoginController().then((var f) {
                if (firstStart) {
                  firstStart = false;
                }
                refreshControllers();
              });
            }
          })!);
  }

  Future<void> refreshControllers({force = true}) async {
    await appSys.gradesController.refresh(force: force);
    await appSys.homeworkController.refresh(force: force);
  }

  showUpdateNote() async {
    if ((appSys.settings.system.lastReadUpdateNote != "0.12")) {
      appSys.settings.system.lastReadUpdateNote = "0.12";
      appSys.saveSettings();
      await CustomDialogs.showUpdateNoteDialog(context);
    }
  }
}
