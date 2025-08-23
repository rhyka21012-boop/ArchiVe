import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewingCounterWidget extends StatefulWidget {
  final String? url;
  const ViewingCounterWidget({this.url});

  @override
  _ViewingCounterWidgetState createState() => _ViewingCounterWidgetState();
}

class _ViewingCounterWidgetState extends State<ViewingCounterWidget> {
  int viewingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadViewingCount();
  }

  Future<void> _loadViewingCount() async {
    if (widget.url == null) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      viewingCount = prefs.getInt(widget.url!) ?? 0;
    });
  }

  Future<void> _saveViewingCount() async {
    if (widget.url == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(widget.url!, viewingCount);
  }

  void _increment() {
    setState(() {
      viewingCount++;
    });
    _saveViewingCount();
  }

  void _decrement() {
    if (viewingCount > 0) {
      setState(() {
        viewingCount--;
      });
      _saveViewingCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 35,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.remove),
            onPressed: viewingCount > 0 ? _decrement : null,
            iconSize: 18,
            color: Colors.black,
          ),
          Text(
            '視聴数: $viewingCount',
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _increment,
            iconSize: 18,
            color: Colors.black,
          ),
        ],
      ),
    );
  }
}
