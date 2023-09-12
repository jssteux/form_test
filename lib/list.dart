import 'package:flutter/material.dart';
import 'package:form_test/form_store.dart';
import 'package:form_test/main.dart';
import 'package:form_test/sheet.dart';
import 'package:vs_scrollbar/vs_scrollbar.dart';

// Define a custom Form widget.
class MyCustomList extends StatefulWidget {
  const MyCustomList(this.store, {super.key});

  final FormStore store;

  @override
  MyCustomListState createState() {
    return MyCustomListState();
  }


}

// Define a corresponding State class.
// This class holds data related to the form.
class MyCustomListState extends State<MyCustomList> {
  late ScrollController _scrollController;
  double initialScrollOffset = 0;
  late List<Map<String, String>> _items;
  Key _refreshKey = UniqueKey();

  Widget _comp(int index) {

    var current = index;
    return GestureDetector(
        child: ListTile(
            title: Row(children: <Widget>[
      Expanded(child: Text(_items.elementAt(index)['NOM']!)),
      Expanded(child: Text(_items.elementAt(index)['PRENOM']!)),
      Expanded(child: Text(_items.elementAt(index)['DATE_NAISSANCE']!)),
    ])),
    onTap: () {
      initialScrollOffset = _scrollController.offset;
      print('offset :$initialScrollOffset' );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FormRoute(widget.store!, current)),
      ).then((value) =>
            setState( (){ if(value == true) {
              _refreshKey = UniqueKey();} })); }
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

  List<Widget> buildWidgets() {
    List<Widget> widgets = [];

    for (int i = 0; i < _items.length; i++) {
      widgets.add(_comp(i));
    }
    return widgets;
  }



  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.

    return FutureBuilder<DatasSheet>(
        key: _refreshKey,
        future: widget.store.loadData(),
        builder: (context, AsyncSnapshot<DatasSheet> snapshot) {
          if (snapshot.hasData) {
            _items = snapshot.data!.datas;
            _scrollController = ScrollController(initialScrollOffset: initialScrollOffset);
            return Form(
                child: Column(children: <Widget>[
              const ListTile(
                  title: Row(children: <Widget>[
                Expanded(
                    child: Text("nom",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    child: Text("prenom",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    child: Text("date naissance",
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ])),
              Expanded(
                  child: VsScrollbar(
                controller: _scrollController,
                showTrackOnHover: true,
                // default false
                isAlwaysShown: true,
                // default false
                scrollbarFadeDuration: const Duration(milliseconds: 500),
                // default : Duration(milliseconds: 300)
                scrollbarTimeToFade: const Duration(milliseconds: 800),
                // default : Duration(milliseconds: 600)
                style: VsScrollbarStyle(
                  hoverThickness: 10.0,
                  // default 12.0
                  radius: const Radius.circular(12),
                  // default Radius.circular(8.0)
                  thickness: 10.0,
                  // [ default 8.0 ]
                  color: Colors.purple.shade900, // default ColorScheme Theme
                ),

                child: SingleChildScrollView(
                  key: Key(_items.length.toString()),
                  controller: _scrollController,
                  child: Column(
                    children: buildWidgets(),
                  ),
                ),
              ))
            ]));
          } else {
            return const CircularProgressIndicator();
          }
        });
  }
}
