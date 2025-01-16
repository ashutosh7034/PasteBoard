import 'package:flutter/material.dart';
import 'package:clipboard/clipboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() => runApp(PasteBoardApp());

class PasteBoardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paste Board',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: PasteBoardHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PasteBoardHome extends StatefulWidget {
  @override
  _PasteBoardHomeState createState() => _PasteBoardHomeState();
}

class _PasteBoardHomeState extends State<PasteBoardHome> {
  String _copiedText = "No text copied yet!";
  List<String> _clipboardHistory = [];
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _loadClipboardHistory();
    _startClipboardMonitor();
  }

  Future<void> _loadClipboardHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHistory = prefs.getStringList('clipboardHistory') ?? [];
    setState(() {
      _clipboardHistory = savedHistory;
    });
  }

  Future<void> _saveClipboardHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('clipboardHistory', _clipboardHistory);
  }

  Future<void> _clearClipboardHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('clipboardHistory');
    setState(() {
      _clipboardHistory.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Clipboard history cleared!'),
      duration: Duration(seconds: 2),
    ));
  }

  Future<void> _deleteHistoryItem(String text) async {
    setState(() {
      _clipboardHistory.remove(text);
    });
    await _saveClipboardHistory();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Item deleted from history.'),
      duration: Duration(seconds: 2),
    ));
  }

  void _startClipboardMonitor() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      String clipboardText = await FlutterClipboard.paste();
      if (_copiedText != clipboardText && clipboardText.isNotEmpty) {
        setState(() {
          _copiedText = clipboardText;
          if (!_clipboardHistory.contains(clipboardText)) {
            _clipboardHistory.insert(0, clipboardText);
            if (_clipboardHistory.length > 10) {
              _clipboardHistory.removeLast();
            }
          }
        });
        await _saveClipboardHistory(); // Save the history persistently
      }
    });
  }

  void _copyFromHistory(String text) {
    FlutterClipboard.copy(text).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Copied to clipboard: $text'),
        duration: Duration(seconds: 2),
      ));
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paste Board'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            tooltip: 'Clear History',
            onPressed: () {
              _clearClipboardHistory();
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Copied Text:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 100,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    _copiedText,
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Clipboard History:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: _clipboardHistory.isEmpty
                  ? Center(
                child: Text(
                  'No history yet!',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              )
                  : ListView.builder(
                itemCount: _clipboardHistory.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 5,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Icon(Icons.copy, color: Colors.white),
                      ),
                      title: Text(
                        _clipboardHistory[index],
                        style: TextStyle(fontSize: 16),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () =>
                            _deleteHistoryItem(_clipboardHistory[index]),
                        tooltip: 'Delete item',
                      ),
                      onTap: () =>
                          _copyFromHistory(_clipboardHistory[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
