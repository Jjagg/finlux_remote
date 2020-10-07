import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:upnp/upnp.dart' show CommonDevices, Device, DeviceDiscoverer;
//import 'package:alt_http/alt_http.dart';

import 'keycodes.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finlux Remote',
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
          brightness: Brightness.dark, primarySwatch: Colors.deepPurple),
      home: DeviceListPage(title: 'Finlux Remote'),
    );
  }
}

class DeviceDiscoveryList extends StatefulWidget {
  @override
  _DeviceDiscoveryListState createState() => _DeviceDiscoveryListState();
}

class _DeviceDiscoveryListState extends State<DeviceDiscoveryList> {
  bool _busy = false;
  List<Device> _devices = [];

  Future<void> _refresh() async {
    if (_busy) return;
    setState(() => _busy = true);
    _devices.clear();
    await _discoverDevices();
  }

  Future<void> _discoverDevices() async {
    var dd = DeviceDiscoverer();
    await dd.start();
    var sub = dd
        .quickDiscoverClients(query: CommonDevices.DIAL)
        .listen((client) async {
      var device = await client.getDevice();

      var valid = await _isValidDevice(device);
      if (valid) {
        _devices.add(device);
        setState(() {
          _devices = _devices;
        });
      }
    });

    sub.onDone(() async {
      await sub.cancel();
      setState(() {
        _busy = false;
      });
    });

    sub.onError((e) async {
      await sub.cancel();
      setState(() {
        _busy = false;
      });
    });

    //var client = MDnsClient();
    //await client.start();
    //await for (var ptr in client.lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(''))) {
    //}

    //client.stop();
  }

  Future<bool> _isValidDevice(Device device) async {
    var url = device.url;
    var deviceDescResp = await http.get(url);
    var deviceDescStr = deviceDescResp.body;

    return deviceDescStr.toLowerCase().contains('finlux');
  }

  @override
  void initState() {
    super.initState();

    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    Widget w = _busy
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          )
        : RaisedButton(
            child: Text('Refresh'),
            onPressed: _busy ? null : _refresh,
          );
    return Column(children: [
      w,
      Expanded(
        child: ListView.builder(
          itemCount: _devices.length,
          itemBuilder: (context, index) {
            var device = _devices[index];
            return ListTile(
              title: Text(device.friendlyName),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => RemotePage(device)));
              },
            );
          },
        ),
      )
    ]);
  }
}

class DeviceListPage extends StatefulWidget {
  DeviceListPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _DeviceListPageState createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.launch),
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => RemotePage(null)));
            },
          )
        ],
      ),
      body: DeviceDiscoveryList(),
    );
  }
}

class Rb {
  final String label;
  final int keycode;
  final IconData icon;

  Rb(this.label, this.keycode) : icon = null;
  Rb.icon(this.icon, this.keycode) : label = null;
}

class RemotePage extends StatefulWidget {
  final Device device;
  final String url;

  RemotePage(this.device) : url = _getTargetUrl(device);

  @override
  _RemotePageState createState() => _RemotePageState();

  static _getTargetUrl(Device device) {
    var base = device.urlBase.substring(0, device.urlBase.lastIndexOf(':'));
    return base + ':56789/apps/SmartCenter';
  }
}

class _RemotePageState extends State<RemotePage> {
  TextEditingController _inputController;
  FocusNode _inputFocus;
  TextEditingController _keycodeController;
  String _keycodeErrorText;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
    _inputFocus = FocusNode();
    _keycodeController = TextEditingController();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocus.dispose();
    _keycodeController.dispose();
    super.dispose();
  }

  Widget _btn(Rb rb) {
    Widget content;
    if (rb.icon != null) {
      content = Icon(rb.icon);
    } else if (rb.label.endsWith('.png')) {
      content = Image(
          image: AssetImage('assets/netflix.png'), width: 100, height: 40);
    } else {
      content = Text(rb.label);
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: RaisedButton(
          child: content, onPressed: () => sendKeycode(rb.keycode)),
    );
  }

  String left = '\u02C2';

  String right = '\u02C3';

  String up = '\u02C4';

  String down = '\u02C5';

  @override
  Widget build(BuildContext context) {
    var row1 = [
      Rb('Source', Keycodes.source),
      Rb.icon(Icons.arrow_drop_up, Keycodes.up),
      Rb('Menu', Keycodes.menu)
    ];

    var row2 = [
      Rb.icon(Icons.arrow_left, Keycodes.left),
      Rb('Ok', Keycodes.ok),
      Rb.icon(Icons.arrow_right, Keycodes.right)
    ];

    var row3 = [
      Rb('Back', Keycodes.back),
      Rb.icon(Icons.arrow_drop_down, Keycodes.down),
      Rb('Exit', Keycodes.exit)
    ];

    var row4 = [
      Rb.icon(Icons.fast_rewind, Keycodes.rewind),
      Rb.icon(Icons.play_arrow, Keycodes.play),
      Rb.icon(Icons.fast_forward, Keycodes.fastForward)
    ];

    var row5 = [
      Rb.icon(Icons.volume_down, Keycodes.volumeDown),
      Rb.icon(Icons.volume_up, Keycodes.volumeUp)
    ];

    var row6 = [Rb('assets/netflix.png', Keycodes.netflix)];

    var rows = [row1, row2, row3, row4, row5, row6]
        .map(
          (r) => Row(
            mainAxisSize: MainAxisSize.min,
            children: r.map(_btn).toList(),
          ),
        )
        .toList();

    return Scaffold(
        appBar: AppBar(
            title: Text(widget.device?.friendlyName ?? 'Remote'),
            actions: [
              IconButton(
                  icon: Icon(Icons.power_settings_new),
                  onPressed: () => sendKeycode(Keycodes.power))
            ]),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
              child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 50.0, vertical: 10.0),
                  child: TextField(
                    autofocus: false,
                    controller: _inputController,
                    focusNode: _inputFocus,
                    onChanged: _textInputChanged,
                    decoration: InputDecoration(
                        labelText: 'Text input',
                        suffixIcon: IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _inputFocus.unfocus();
                              _inputController.clear();
                            })),
                  ),
                )
              ]
                ..addAll(rows)
                ..add(Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 50.0, vertical: 10.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          autofocus: false,
                          controller: _keycodeController,
                          inputFormatters: [
                            WhitelistingTextInputFormatter.digitsOnly
                          ],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              labelText: 'Keycode',
                              errorText: _keycodeErrorText),
                        ),
                      ),
                      RaisedButton(
                        child: Text('Send'),
                        onPressed: () {
                          manualKeycode(_keycodeController.text);
                        },
                      )
                    ],
                  ),
                )),
            ),
          )),
        ));
  }

  Future<http.Response> manualKeycode(String keycode) {
    var kc = int.tryParse(keycode);
    if (kc == null) {
      setState(() {
        _keycodeErrorText = 'Needs to be a number';
      });
    }

    setState(() {
      _keycodeErrorText = null;
    });

    return sendKeycode(kc);
  }

  Future<http.Response> sendKeycode(int keycode) async {
    var msg = createKeycodeMessage(keycode);

    //var dio = Dio();

    //(dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
    //    (HttpClient client) {
    //  if (client == null || !(client is AltHttpClient)) {
    //    var altClient = AltHttpClient();
    //    return altClient;
    //  }
    //  return client;
    //};

    //var resp = await dio.post(widget.url, data: msg);

    var client = HttpClient();
    var req = await client.post('192.168.0.152', 56789, 'apps/SmartCenter');
    req.headers.set('Content-Length', msg.length, preserveHeaderCase: true);
    req.headers.set('Content-Type', 'text/plain; charset=ISO-8859-1',
        preserveHeaderCase: true);
    req.headers.set('Host', '192.168.0.152:56789', preserveHeaderCase: true);
    req.headers.set('Connection', 'Keep-Alive', preserveHeaderCase: true);

    req.write(msg);
    var resp = await req.close();

    //var getResp = await http.get(widget.url);
    //var getBody = getResp.body;

    //var firstResp = await http.post(
    //    'http://192.168.0.152:56789/apps/SmartCenter',
    //    body: "<?xml version='1.0' ?><remote><key code='1056'/></remote>");
    //var fbody = firstResp.body;

    //var resp = await http.post(widget.url, body: msg, headers: {
    //  //'Content-Type': 'application/xml',
    //  'Connection': 'keep-alive'
    //});
    //var body = resp.body;

    return null;
  }

  void _textInputChanged(String value) {
    if (value == null || value.isEmpty) return;
    var char = value.codeUnits.last;
    // TODO this is not how character input works
    if (char < 128) {
      sendKeycode(char);
    }
  }
}

String createKeycodeMessage(int keyCode) {
  // <?xml version='1.0' ?><remote><key code='1017'/></remote>
  return "<?xml version='1.0' ?><remote><key code='$keyCode'/></remote>";
}
