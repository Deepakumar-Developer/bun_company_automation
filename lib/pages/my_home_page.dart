import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

import '../function.dart';
import '../my_widget.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Bluetooth State Variables
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  BluetoothConnection? _connection;
  StreamSubscription<Uint8List>? _dataSubscription;

  List<BluetoothDevice> _bondedDevices = [];
  static const String hc05Name = 'HC-05';

  // UI State Variables
  String _statusMessage = "Initializing...";
  bool _isConnecting = false, isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
  }

  void _initializeBluetooth() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
    // Check initial state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
        _statusMessage = "Bluetooth is ${state.toString().split('.').last}";
      });
    });
    // Listen for state changes (e.g., user turns Bluetooth ON/OFF or grants permission)
    FlutterBluetoothSerial.instance.onStateChanged().listen((
      BluetoothState state,
    ) {
      setState(() {
        print('hi');
        print(state.toString());
        _bluetoothState = state;
        _statusMessage = "Bluetooth is ${state.toString().split('.').last}";
      });
      if (!state.isEnabled) {
        _disconnect();
      }
    });
  }

  // --- Bluetooth Communication Logic ---

  Future<void> _getBondedDevices() async {
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      setState(() => _statusMessage = "Bluetooth is OFF. Please enable it.");
      return;
    }
    setState(() => _statusMessage = "Searching for paired devices...");
    try {
      List<BluetoothDevice> bonded = await FlutterBluetoothSerial.instance
          .getBondedDevices();
      setState(() {
        _bondedDevices = bonded;
        _statusMessage = "Found ${_bondedDevices.length} paired devices.";
      });
    } catch (e) {
      setState(() => _statusMessage = "Error getting devices: $e");
    }
  }

  void _connectToHC05() async {
    setState(() {
      isLoading = true;
    });
    await _getBondedDevices();
    for (var val in _bondedDevices) {
      print('${val.name} - ${val.address}');
    }

    BluetoothDevice? targetDevice = _bondedDevices.firstWhere(
      (device) => device.name == hc05Name || device.address == hc05Name,
    );

    setState(() {
      _isConnecting = true;
      _statusMessage =
          "Connecting to Device...";
    });

    try {
      _connection = await BluetoothConnection.toAddress(targetDevice.address);
      setState(() {
        _statusMessage =
            "Connected to Device! Send commands now.";
        _isConnecting = true;
        isLoading = false;
      });
      // _listenForData(); // Start listening for Arduino's confirmation
    } catch (e) {
      setState(() {
        _statusMessage = "Connection failed: ${e.runtimeType}";
        print(e);
        _isConnecting = false;
        isLoading = false;
      });
      _disconnect();
    }
  }

  Future<void> _sendData(String data) async {
    if (_connection != null && _connection!.isConnected) {
      try {
        // Send '1' or '0' command to Arduino
        print('data send');
        Uint8List dataToSend = Uint8List.fromList(utf8.encode('$data\n'));

        _connection!.output.add(dataToSend);
        await _connection!.output.allSent;
      } catch (e) {
        setState(() => _statusMessage = "Error sending command: ${e.runtimeType}");
      }
    } else {
      setState(() => _statusMessage = "Not connected. Cannot send data.");
    }
  }

  void _disconnect() {
    _dataSubscription?.cancel();
    _connection?.dispose();
    _connection = null;
    setState(() {
      _isConnecting = false;
    });
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _connection?.dispose();
    super.dispose();
  }

  // Mock data for the two lights
  List<TubeLight> lights = [
    TubeLight(id: 'L1', name: 'Living Room Left'),
    TubeLight(id: 'L2', name: 'Living Room Right'),
  ];


  // Function to send command via Bluetooth and update state
  void _toggleLight(TubeLight light, String commend) {

    if (_isConnecting) {
      if(commend == 'phone') {
        setState(() {
          light.isOn = !light.isOn;
          if (light.isOn) {
            light.control = 'P';
          }
          _statusMessage =
          '${light.name} toggled to ${light.isOn ? 'ON' : 'OFF'}';
        });
      }
      if(commend == 'switch') {
          setState(() {
            light.control = 'S';
            light.isOn = false;
            print(light.control);
            _statusMessage =
            'Now, ${light.name} control by Switch';
          });
      }

      // *** BLUETOOTH SEND COMMAND LOGIC ***
      if(light.id == 'L1') {
        _sendData(light.control == 'S' ? 'LS' : light.isOn ? 'L1' : 'L0');
      } else if(light.id == 'L2') {
        _sendData(light.control == 'S' ? 'RS' : light.isOn ? 'R1' : 'R0');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(milliseconds: 500),
          content: Text('Pair the device.',style: TextStyle(color: Colors.white),),
          backgroundColor: Colors.grey[800],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background for the theme
      appBar: AppBar(

        title: Row(
          spacing: 16,
          children: [
            Icon(Icons.settings,color: Colors.white,size: 32,),
            const Text(
              'Controller',
              style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Grid Layout for the two themed control boxes
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1, // Vertical layout for two large boxes
                  childAspectRatio: 1.75, // Control box height/width ratio

                ),
                itemCount: lights.length + 1,
                itemBuilder: (context, index) {
                  if (index == lights.length) {
                    return SwitchControl();
                  }
                  return LightControlBox(
                    light: lights[index],
                    onToggle: _toggleLight,
                  );
                },
              ),
            ),
            SizedBox(
              width: width(context),
              height: 64,
              child: Center(
                child: Text(
                  _statusMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Connect/Disconnect Button
            Row(
              children: [
                SizedBox(width: 16),
                Icon(
                  isLoading ? Icons.bluetooth_searching: _bluetoothState == BluetoothState.STATE_ON && !_isConnecting
                      ? Icons.bluetooth
                      : _isConnecting
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color: _bluetoothState == BluetoothState.STATE_OFF
                      ? Colors.red[900]
                      : Colors.white,
                  semanticLabel: 'BT State',
                  size: 32,
                ),
                GestureDetector(
                  onTap: () {
                    if (_bluetoothState == BluetoothState.STATE_ON) {
                      if(_isConnecting) {
                        _disconnect();
                        setState(() {
                          _statusMessage = 'Unpair Successfully';
                        });
                      } else {
                        _connectToHC05();
                      }
                    } else if (_bluetoothState == BluetoothState.STATE_OFF) {
                      ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(
                          duration: Duration(milliseconds: 500),
                          content: Text('Bluetooth is not enabled.',style: TextStyle(color: Colors.white),),
                          backgroundColor: Colors.grey[800],
                        ),
                      );
                    } else {
                      _disconnect();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    margin: EdgeInsets.only(left: 16),
                    height: 54,
                    decoration: BoxDecoration(
                      color:
                          _bluetoothState == BluetoothState.STATE_OFF ||
                              _isConnecting
                          ? Colors.red[900]
                          : Colors.green[900],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    width: width(context) * 0.7,
                    child: Center(
                      child: isLoading ? CircularProgressIndicator(color: Colors.white,strokeWidth: 3,padding: EdgeInsets.symmetric(horizontal: width(context)*0.28),):Text(
                        _isConnecting
                            ? 'Unpair'
                            : 'Pair a Device',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget SwitchControl() {
    return Column();
  }
}
