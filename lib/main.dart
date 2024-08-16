import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:rs232/utils/size_config.dart';
import 'package:usb_serial/usb_serial.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  UsbPort? _port;
  String _data = 'No Data';
  String _lastWeight = '';

  void _getDevice() async {
    // Show loading progress indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    await Future.delayed(const Duration(seconds: 3));

    List<UsbDevice> devices = await UsbSerial.listDevices();
    if (devices.isNotEmpty) {
      try {
        UsbPort? port = await devices[0].create();
        bool openResult = await port?.open() ?? false;
        if (openResult) {
          _port = port;
          _port!.setDTR(true);
          _port!.setRTS(true);
          _port!.setPortParameters(9600, UsbPort.DATABITS_8, UsbPort.STOPBITS_1,
              UsbPort.PARITY_NONE);

          _port!.inputStream?.listen((Uint8List data) {
            String newData = String.fromCharCodes(data).trim();
            final numericWeight = extractWeight(newData);
            if (numericWeight != null) {
              updateWeight(numericWeight);
            }
          });
        }
      } catch (e) {
        _data = e.toString();
      }
    }
    // Close loading progress indicator
    if (mounted) {
      Navigator.pop(context);
    }
  }

  double? extractWeight(String data) {
    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(data);
    return match != null ? double.tryParse(match.group(0)!) : null;
  }

  void updateWeight(double weight) {
    const threshold = 0.01;
    if ((weight - double.parse(_lastWeight)).abs() > threshold) {
      setState(() {
        _lastWeight = weight.toStringAsFixed(2);
        _data = _lastWeight;
      });
    }
  }

  @override
  void dispose() {
    _port?.close();
    _port = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Center(
            child: Text(
          'Data Reader Application (rs232)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        )),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Real-Time Scale Data Reader'),
            SizedBox(
              height: getProportionateScreenHeight(10),
            ),
            ElevatedButton(
              onPressed: _getDevice,
              child: const Text(
                'Connect to scale',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              ),
            ),
            SizedBox(
              height: getProportionateScreenHeight(10),
            ),
            Text(
              _data,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
