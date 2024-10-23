import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: BLEScanner(),
    );
  }
}

class BLEScanner extends StatefulWidget {
  const BLEScanner({Key? key}) : super(key: key);

  @override
  _BLEScannerState createState() => _BLEScannerState();
}

class _BLEScannerState extends State<BLEScanner> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  String message = '';
  Map<Permission, bool> permissionsStatus = {};

  @override
  void initState() {
    super.initState();
    requestPermissionsAndStartScan();
  }

  // パーミッションのリクエストとスキャン開始
  Future<void> requestPermissionsAndStartScan() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location, // 位置情報のパーミッション
    ].request();

    setState(() {
      permissionsStatus = {
        Permission.bluetoothScan: statuses[Permission.bluetoothScan]?.isGranted ?? false,
        Permission.bluetoothConnect: statuses[Permission.bluetoothConnect]?.isGranted ?? false,
        Permission.location: statuses[Permission.location]?.isGranted ?? false,
      };
    });

    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (allGranted) {
      startScan();
    } else {
      setState(() {
        message = 'パーミッションが許可されていません';
      });
    }
  }

  // BLEスキャンを開始
  void startScan() async {
    if (isScanning) {
      return;
    }

    // Bluetoothが有効か確認
    bool isBluetoothEnabled = await FlutterBluePlus.isOn;
    if (!isBluetoothEnabled) {
      setState(() {
        message = 'Bluetoothが有効化されていません。';
      });
      return;
    }

    // 位置情報サービスが有効か確認
    ServiceStatus locationStatus = await Permission.location.serviceStatus;
    if (locationStatus != ServiceStatus.enabled) {
      setState(() {
        message = '位置情報サービスが有効になっていません。デバイスの設定で有効にしてください。';
      });
      return;
    }

    setState(() {
      isScanning = true;
      message = '';
      scanResults.clear();
    });

    try {
      // スキャンを10秒間実行
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      // スキャン結果を処理
      FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          scanResults = results;
        });
        for (ScanResult r in results) {
          print('${r.device.name} found! rssi: ${r.rssi}');
        }
      });

      // スキャンの完了を待機
      await Future.delayed(const Duration(seconds: 10));

      // スキャンを停止
      FlutterBluePlus.stopScan();

      setState(() {
        isScanning = false;
        if (scanResults.isEmpty) {
          message = 'デバイスが見つかりませんでした';
        } else {
          message = 'スキャン完了';
        }
      });

    } catch (e) {
      setState(() {
        isScanning = false;
        message = 'スキャン中にエラーが発生しました: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('BLEデバイススキャナ'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: !isScanning ? startScan : null,
                child: const Text('スキャン開始'),
              ),
            ),
            if (isScanning)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                message,
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
            // パーミッション状態の表示
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bluetooth Scan パーミッション: ${permissionsStatus[Permission.bluetoothScan] == true ? '許可' : '未許可'}',
                    style: TextStyle(
                        fontSize: 16,
                        color: permissionsStatus[Permission.bluetoothScan] == true ? Colors.green : Colors.red),
                  ),
                  Text(
                    'Bluetooth Connect パーミッション: ${permissionsStatus[Permission.bluetoothConnect] == true ? '許可' : '未許可'}',
                    style: TextStyle(
                        fontSize: 16,
                        color: permissionsStatus[Permission.bluetoothConnect] == true ? Colors.green : Colors.red),
                  ),
                  Text(
                    '位置情報 パーミッション: ${permissionsStatus[Permission.location] == true ? '許可' : '未許可'}',
                    style: TextStyle(
                        fontSize: 16,
                        color: permissionsStatus[Permission.location] == true ? Colors.green : Colors.red),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: scanResults.length,
                itemBuilder: (context, index) {
                  final result = scanResults[index];
                  final name = result.device.name.isNotEmpty ? result.device.name : '不明なデバイス';
                  return ListTile(
                    title: Text('名前: $name'),
                    subtitle: Text('アドレス: ${result.device.id.id}, RSSI: ${result.rssi}'),
                  );
                },
              ),
            ),
          ],
        ));
  }
}
