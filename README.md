# App BLE Scan

## Version
- Flutter 3.24.3
- Dart 3.5.3
- fvm 3.2.1  

fvmのインストールは強制ではありませんが、その場合はバージョンに注意してください。

## Next Step
fvmをインストールしている場合：
```bash
fvm install
```
このコマンドでFlutter SDKのバージョン(3.24.3)がなければインストールされます。  
次に下記のコマンドを実行してください。依存関係がインストールされます。
```bash
fvm flutter pub get
```

fvmをインストールしていない場合：  
flutterのバージョンが3.24.3であることを確認してください。  
その後、下記のコマンドを実行してください。依存関係がインストールされます。
```dart
flutter pub get
```