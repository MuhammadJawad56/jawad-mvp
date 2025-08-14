import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:csv/csv.dart';
import 'package:synchronized/synchronized.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {
    secureStorage = FlutterSecureStorage();

    await _safeInitAsync(() async {
      _nevOpen = await secureStorage.getBool('ff_nevOpen') ?? _nevOpen;
    });

    await _safeInitAsync(() async {
      _address = await secureStorage.getString('ff_address') ?? _address;
    });

    await _safeInitAsync(() async {
      _latitude = await secureStorage.getDouble('ff_latitude') ?? _latitude;
    });

    await _safeInitAsync(() async {
      _longitude = await secureStorage.getString('ff_longitude') ?? _longitude;
    });

    await _safeInitAsync(() async {
      final storedMode = await secureStorage.getString('ff_themeMode');
      if (storedMode != null) {
        _themeMode = _parseThemeMode(storedMode);
      }
    });

    // ✅ New persisted userRole load
    await _safeInitAsync(() async {
      _userRole = await secureStorage.getString('ff_userRole') ?? _userRole;
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late FlutterSecureStorage secureStorage;

  bool _nevOpen = true;
  bool get nevOpen => _nevOpen;
  set nevOpen(bool value) {
    _nevOpen = value;
    secureStorage.setBool('ff_nevOpen', value);
  }

  void deleteNevOpen() {
    secureStorage.delete(key: 'ff_nevOpen');
  }

  String _address = '';
  String get address => _address;
  set address(String value) {
    _address = value;
    secureStorage.setString('ff_address', value);
  }

  void deleteAddress() {
    secureStorage.delete(key: 'ff_address');
  }

  double _latitude = 0.0;
  double get latitude => _latitude;
  set latitude(double value) {
    _latitude = value;
    secureStorage.setDouble('ff_latitude', value);
  }

  void deleteLatitude() {
    secureStorage.delete(key: 'ff_latitude');
  }

  String _longitude = '';
  String get longitude => _longitude;
  set longitude(String value) {
    _longitude = value;
    secureStorage.setString('ff_longitude', value);
  }

  void deleteLongitude() {
    secureStorage.delete(key: 'ff_longitude');
  }

  List<String> _localImageList = [];
  List<String> get localImageList => _localImageList;
  set localImageList(List<String> value) {
    _localImageList = value;
  }

  void addToLocalImageList(String value) {
    localImageList.add(value);
  }

  void removeFromLocalImageList(String value) {
    localImageList.remove(value);
  }

  void removeAtIndexFromLocalImageList(int index) {
    localImageList.removeAt(index);
  }

  void updateLocalImageListAtIndex(int index, String Function(String) updateFn) {
    localImageList[index] = updateFn(_localImageList[index]);
  }

  void insertAtIndexInLocalImageList(int index, String value) {
    localImageList.insert(index, value);
  }

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  set themeMode(ThemeMode mode) {
    _themeMode = mode;
    secureStorage.setString('ff_themeMode', mode.toString());
    notifyListeners();
  }

  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'ThemeMode.light':
        return ThemeMode.light;
      case 'ThemeMode.dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // ✅ ADDED: User Role Management
  String _userRole = 'provider';
  String get userRole => _userRole;
  set userRole(String value) {
    _userRole = value;
    secureStorage.setString('ff_userRole', value);
    notifyListeners();
  }
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

Future _safeInitAsync(Function() initializeField) async {
  try {
    await initializeField();
  } catch (_) {}
}

extension FlutterSecureStorageExtensions on FlutterSecureStorage {
  static final _lock = Lock();

  Future<void> writeSync({required String key, String? value}) async =>
      await _lock.synchronized(() async {
        await write(key: key, value: value);
      });

  void remove(String key) => delete(key: key);

  Future<String?> getString(String key) async => await read(key: key);
  Future<void> setString(String key, String value) async =>
      await writeSync(key: key, value: value);

  Future<bool?> getBool(String key) async =>
      (await read(key: key)) == 'true';
  Future<void> setBool(String key, bool value) async =>
      await writeSync(key: key, value: value.toString());

  Future<int?> getInt(String key) async =>
      int.tryParse(await read(key: key) ?? '');
  Future<void> setInt(String key, int value) async =>
      await writeSync(key: key, value: value.toString());

  Future<double?> getDouble(String key) async =>
      double.tryParse(await read(key: key) ?? '');
  Future<void> setDouble(String key, double value) async =>
      await writeSync(key: key, value: value.toString());

  Future<List<String>?> getStringList(String key) async =>
      await read(key: key).then((result) {
        if (result == null || result.isEmpty) {
          return null;
        }
        return CsvToListConverter()
            .convert(result)
            .first
            .map((e) => e.toString())
            .toList();
      });

  Future<void> setStringList(String key, List<String> value) async =>
      await writeSync(key: key, value: ListToCsvConverter().convert([value]));
}
