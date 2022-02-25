import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/WeekWidget.dart';

import '../../Components/Toast.dart';
import '../../Resources/Config.dart';
import '../../Utils/States/MainState.dart';
import '../../generated/l10n.dart';
import '../Import/ImportView.dart';
import '../../Utils/PrivacyUtil.dart';
import '../../Utils/UpdateUtil.dart';
import '../Settings/SettingsView.dart';

class TermView extends StatefulWidget {
  const TermView({Key? key}) : super(key: key);

  @override
  _TermViewState createState() => _TermViewState();
}

class _TermViewState extends State<TermView>
    with TickerProviderStateMixin {
  late List<Widget> _weekWidgetList;

  //late List<Widget> _weekTextList;
  late List<DropdownMenuItem<int>> _dropButtonList;

  late int _nowWeekNum;
  late int _nowShowWeekNum;
  late Future _futureBuilderFuture;
  bool weekSelectorVisibility = false;

  basicCheck() async {
    UpdateUtil updateUtil = UpdateUtil();
    await updateUtil.checkUpdate(context, false);
    PrivacyUtil privacyUtil = PrivacyUtil();
    bool privacyRst = await privacyUtil.checkPrivacy(context, false);
    if (!privacyRst) return;
    bool rst = await Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) => const ImportView())) ??
        false;
    if (!rst) return;
    ScopedModel.of<MainStateModel>(context).refresh();
  }

  Future _getData() async {
    _nowWeekNum = await ScopedModel.of<MainStateModel>(context).getWeek();
    // int _nowShowWeekNum =
    //     await ScopedModel.of<MainStateModel>(context).getTmpWeek();
    _nowShowWeekNum = _nowWeekNum;
    TabController _tabController = TabController(
        initialIndex: _nowWeekNum - 1, length: Config.MAX_WEEKS, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    return {
      "nowWeekNum": _nowWeekNum,
      "nowShowWeekNum": _nowShowWeekNum,
      "tabController": _tabController
    };
  }

  _initList() {
    _weekWidgetList = List.generate(
        Config.MAX_WEEKS, (index) => WeekWidget(showWeek: index + 1));
    // _weekTextList =
    //     List.generate(Config.MAX_WEEKS, (index) => Text("第${index + 1}周"));
    _dropButtonList = List.generate(
        Config.MAX_WEEKS,
            (index) => DropdownMenuItem<int>(
          value: index,
          child: Text(
            S.of(context).week((index + 1).toString()),
          ),
        ));
  }

  @override
  void initState() {
    super.initState();
    //防止FutureBuilder不必要的重绘
    _futureBuilderFuture = _getData();
    basicCheck();
  }

  @override
  Widget build(BuildContext context) {
    _initList();

    return Scaffold(
      body: FutureBuilder(
        future: _futureBuilderFuture,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              TabController _tabController = snapshot.data["tabController"];
              int _nowWeekNum = snapshot.data["nowWeekNum"];
              int _nowShowWeekNum = snapshot.data["nowShowWeekNum"];

              // String nowWeek = S.of(context).week(_nowShowWeekNum.toString());
              // if (_nowWeekNum < 1) {
              //   nowWeek = S.of(context).not_open + ' ' + nowWeek;
              // } else if (_nowWeekNum != _nowShowWeekNum) {
              //   nowWeek = S.of(context).not_this_week + ' ' + nowWeek;
              // }
              return Scaffold(
                drawer: Drawer(
                  //侧边栏按钮Drawer
                  child: ListView(children: [
                    ListTile(
                      //第一个功能项
                        title: const Text('设置'),
                        trailing: const Icon(Icons.settings),
                        onTap: () {
                          Navigator.of(context)
                              .push(MaterialPageRoute(
                              builder: (BuildContext context) =>
                              const SettingsView()))
                              .then((value) {
                            setState(() {});
                          });
                        }),
                  ]),
                ),
                appBar: AppBar(
                  //为false的时候会影响leading，actions、titile组件，导致向上偏移
                  primary: true,
                  //centerTitle: true,
                  title: DropdownButton<int>(
                    value: _tabController.index,
                    items: _dropButtonList,
                    onChanged: (int? value) {
                      setState(() {
                        _tabController.animateTo(value!);
                      });
                    },
                  ),
                  actions: [
                    InkWell(
                      child: const Icon(Icons.settings),
                      onTap: () {
                        Navigator.of(context)
                            .push(MaterialPageRoute(
                            builder: (BuildContext context) =>
                            const SettingsView()))
                            .then((value) {
                          setState(() {});
                        });
                        UmengCommonSdk.onEvent(
                            "setting_tap", {"action": "success"});
                      }
                    ),
                    const Padding(padding: EdgeInsets.only(right: 20))
                  ],

                  //设置导航条上面的状态栏显示字体颜色
                  backgroundColor: Colors.amber,
                ),
                body: TabBarView(
                    controller: _tabController, children: _weekWidgetList),
              );
            } else {
              return Container(
                alignment: Alignment.center,
                child: const Text('error'),
              );
            }
          } else {
            return Container(
                alignment: Alignment.center,
                child: const CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
