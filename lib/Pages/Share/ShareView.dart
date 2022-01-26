import 'dart:convert';
import '../../generated/l10n.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../Utils/States/MainState.dart';
import '../../Components/Toast.dart';
import '../../Models/CourseModel.dart';
import '../../Models/CourseTableModel.dart';

import 'QRShareView.dart';
import 'QRScanView.dart';

class ShareView extends StatefulWidget {
  const ShareView({Key? key}) : super(key: key);

  @override
  _ShareViewState createState() => _ShareViewState();
}

class _ShareViewState extends State<ShareView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).import_or_export_title),
        ),
        body: SingleChildScrollView(
            child: Column(children: <Widget>[
          SingleChildScrollView(
              child: Column(
                  children: ListTile.divideTiles(context: context, tiles: [
            ListTile(
              title: Text(S.of(context).export_classtable_title),
              subtitle: Text(S.of(context).export_classtable_subtitle),
              onTap: () async {
                int index = await ScopedModel.of<MainStateModel>(context)
                    .getClassTable();
                CourseProvider courseProvider = CourseProvider();
                List allCoursesMap = await courseProvider.getAllCourses(index);
                CourseTableProvider courseTableProvider = CourseTableProvider();
                CourseTable? courseTable =
                    await courseTableProvider.getCourseTable(index);
                Map rst = {'name': courseTable!.name, 'courses': allCoursesMap};
                // String rstStr = json.encode(rst).toString();
                // print(rstStr);

                try {
                  Dio dio = Dio();
                  Response response =
                      await dio.post("https://file.io/?expires=1w",
                          data: {"text": json.encode(rst)},
                          options: Options(
                            contentType: Headers.formUrlEncodedContentType,
                          ));
                  // print(response.data);
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) =>
                          QRShareView(response.data['link'])));
                } catch (e) {
                  Toast.showToast(S.of(context).network_error_toast, context);
                }
              },
            ),
            ListTile(
              title: Text(S.of(context).import_from_qrcode_title),
              subtitle: Text(S.of(context).import_from_qrcode_subtitle),
              onTap: () async {
                String? str = await Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (BuildContext context) => const QRScanView()));
                // var str = null;
                // String str = await _scan();
                if (str == null) return;
                Toast.showToast(S.of(context).importing_toast, context);
                Map courseTableMap;

                try {
                  Dio dio = Dio();
                  Response response = await dio.get(str);
                  // print(response.data.toString());
                  courseTableMap = json.decode(response.data.toString());
                } catch (e) {
                  Toast.showToast(
                      S.of(context).qrcode_url_error_toast, context);
                  return;
                }

                CourseTableProvider courseTableProvider = CourseTableProvider();
                int index;

                try {
                  CourseTable courseTable = await courseTableProvider
                      .insert(CourseTable(courseTableMap['name']));
                  index = (courseTable.id!);
                } catch (e) {
                  Toast.showToast(
                      S.of(context).qrcode_name_error_toast, context);
                  return;
                }
                CourseProvider courseProvider = CourseProvider();
                await ScopedModel.of<MainStateModel>(context)
                    .changeclassTable(index);

                List<Map<String, dynamic>> coursesMap =
                    List<Map<String, dynamic>>.from(courseTableMap['courses']);
                try {
                  for (var courseMap in coursesMap) {
                    // courseMap.remove('id');
                    courseMap['tableid'] = index;
                    Course course = Course.fromMap(courseMap);
                    courseProvider.insert(course);
                  }
                } catch (e) {
                  Toast.showToast(
                      S.of(context).qrcode_read_error_toast, context);
                  return;
                }
                Toast.showToast(S.of(context).import_success_toast, context);
                UmengCommonSdk.onEvent("qr_import", {"action": "success"});
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ]).toList()))
        ])));
  }

//   Future<String> _scan() async {
//     String? barcode;
//     try {
//       // barcode = await BarcodeScanner.scan();
// //    } on PlatformException catch (e) {
// //      if (e.code == BarcodeScanner.CameraAccessDenied) {
// //      } else {
// //      }
// //    } on FormatException{
//     } catch (e) {}
//     return "barcode";
//   }
}
