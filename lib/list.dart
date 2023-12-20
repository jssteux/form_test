import 'dart:async';

import 'package:flutter/material.dart';
import 'package:form_test/form_store.dart';
import 'package:form_test/main.dart';
import 'package:form_test/sheet.dart';
import 'package:vs_scrollbar/vs_scrollbar.dart';

import 'column_descriptor.dart';

// Define a custom Form widget.
class MyCustomList extends StatefulWidget {
  const MyCustomList(this.store, this.sheetName, this.formIndex, this.context,
      {super.key});

  final FormStore store;
  final Context context;
  final String? sheetName;
  final int formIndex;

  @override
  MyCustomListState createState() {
    return MyCustomListState();
  }
}

// Define a corresponding State class.
// This class holds data related to the form.
class MyCustomListState extends State<MyCustomList> {
  TextEditingController searchController = TextEditingController();
  late ScrollController _scrollController;
  final _formKey = GlobalKey<FormState>();
  double initialScrollOffset = 0;
  late List<FilteredLine> _items;
  late FormDatas sheet;
  Key _refreshKey = UniqueKey();
  FocusNode focusNode = FocusNode();
  String searchPattern = "";
  Timer? timer;

  @override
  void dispose() {
    if (timer != null) {
      timer!.cancel();
      timer = null;
    }
    focusNode.dispose();
    super.dispose();
  }



  Widget _comp(int index) {
    var current = index;

    return Dismissible(
      key: Key(index.toString()),
      background: Container(color: Colors.red),
      onDismissed: (direction) async {

        // Then show a snackbar.
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('item dismissed')));

        String id = sheet.lines[current].datas["ID"]!;
        sheet.lines.removeAt(current);
        await widget.store.removeData(context, sheet.form.sheetName, id);

        setState(() {
          initialScrollOffset = _scrollController.offset;
        });




      },
      child: GestureDetector(
          child: ListTile(title: Row(children: buildInnerWidgets(index))),
          onTap: () {
            initialScrollOffset = _scrollController.offset;
            //print('offset :$initialScrollOffset' );
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => FormRoute(
                      widget.store,
                      sheet.form.sheetName,
                      sheet.lines[current].originalIndex,
                      widget.context)),
            ).then((value) => setState(() {
              if (value == true) {
                _refreshKey = UniqueKey();
              }
            }));
          }),
    );
/*
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () => setState(() {
          _items.removeAt(index);
        }),
      );
*/
  }

  List<Widget> buildLines() {
    List<Widget> widgets = [];

    for (int i = 0; i < _items.length; i++) {
      widgets.add(_comp(i));
    }
    return widgets;
  }

  List<Widget> buildInnerWidgets(int index) {
    List<Widget> widgets = [];

    for (int i = 0; i < sheet.form.columns.length; i++) {
      String? label;

      String columName = sheet.form.columns[i];
      ColumnDescriptor? desc = sheet.columns[columName];
      if (desc != null && desc.reference.isNotEmpty) {
        label = sheet.lines[index].referenceLabels[columName];
      } else {
        label = _items.elementAt(index).datas[columName];
      }

      label ??= "";

      widgets.add(Expanded(child: Text(label)));
    }
    return widgets;
  }

  List<Widget> buildTitles() {
    List<Widget> widgets = [];

    for (int i = 0; i < sheet.form.columns.length; i++) {
      String columName = sheet.form.columns[i];
      ColumnDescriptor? columDesc = sheet.columns[columName];
      if (columDesc != null) {
        String label = columDesc.label;
        widgets.add(
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
        );
      }
    }
    return widgets;
  }



  Widget buildSearchItem() {
    var textField = TextFormField(
        controller: searchController,
        focusNode: focusNode,
        decoration: const InputDecoration(
          border: InputBorder.none,
            hintText: 'search items'
        ));

    searchController.addListener(() {
      if (timer != null) {
        timer!.cancel();
        timer = null;
      }

      timer = Timer(const Duration(milliseconds: 300), () {
        //print("timer");

        if (searchPattern != searchController.text) {
          setState(() {
            searchPattern = searchController.text;
          });
        }
      });
    });

    return Expanded( flex: 0, child: Container(color: Colors.grey[200], child: Padding(padding: const EdgeInsets.only(left:10),
    child:textField)));
  }

  @override
  Widget build(BuildContext context) {



    return FutureBuilder<FormDatas>(
        key: _refreshKey,
        future: widget.store.loadForm(
            widget.sheetName, widget.formIndex, searchPattern, widget.context),
        builder: (context, AsyncSnapshot<FormDatas> snapshot) {
          if (snapshot.hasData) {
            _items = snapshot.data!.lines;
            sheet = snapshot.data!;
            _scrollController =
                ScrollController(initialScrollOffset: initialScrollOffset);
            return Form(
                key: _formKey,
                // Without out this, pop in appBar has a blink effect due to keyboard
                // height if the focus is set on a text field
                child : WillPopScope(onWillPop: () async {

                  FocusScope.of(context).unfocus();
                  await Future.delayed(const Duration(milliseconds: 300));

                  return true;
                  },
                child: Scaffold(
                  resizeToAvoidBottomInset: false,
                  body:


                  Stack(
                      children: <Widget>[
                        Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              buildSearchItem(),
                              Expanded(
                                  flex: 1,
                                  child: Column(children: <Widget>[
                                    ListTile(title: Row(children: buildTitles())),
                                    Expanded(
                                        child: VsScrollbar(
                                          controller: _scrollController,
                                          showTrackOnHover: true,
                                          // default false
                                          isAlwaysShown: true,
                                          // default false
                                          scrollbarFadeDuration:
                                          const Duration(milliseconds: 500),
                                          // default : Duration(milliseconds: 300)
                                          scrollbarTimeToFade:
                                          const Duration(milliseconds: 800),
                                          // default : Duration(milliseconds: 600)
                                          style: VsScrollbarStyle(
                                            hoverThickness: 10.0,
                                            // default 12.0
                                            radius: const Radius.circular(12),
                                            // default Radius.circular(8.0)
                                            thickness: 10.0,
                                            // [ default 8.0 ]
                                            color: Colors.purple
                                                .shade900, // default ColorScheme Theme
                                          ),

                                          child: SingleChildScrollView(
                                            key: Key(_items.length.toString()),
                                            controller: _scrollController,
                                            child: Column(
                                              children: buildLines(),
                                            ),
                                          ),
                                        ))
                                  ]))
                            ]),
                        Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [


                              Padding(padding:const EdgeInsets.all(5),child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => FormRoute(
                                              widget.store,
                                              sheet.form.sheetName,
                                              -1,
                                              widget.context)),
                                    ).then((value) {

                                      FocusScope.of(context).unfocus();

                                      //print("keyboard" + MediaQuery.of(context).viewInsets.bottom.toString());
                                      setState(() {
                                      if (value == true) {


                                        _refreshKey = UniqueKey();
                                      }

                                    });});
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.all(16),
                                    backgroundColor: Colors.blue, // <-- Button color
                                  ),
                                  child: const Icon(Icons.add, color: Colors.white),
                                )
                              ]))
                            ])
                      ]),
                )));
          } else {
            return const CircularProgressIndicator();
          }
        });
  }
}
