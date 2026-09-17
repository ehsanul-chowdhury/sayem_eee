import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'firebase_options.dart';

const _bg = Color(0xFFFAFAFA);
const _border = Color(0xFFE4E4E7);
const _muted = Color(0xFF71717A);
const _ink = Color(0xFF18181B);
const _accent = Color(0xFF16A34A);
const _card = Colors.white;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final options = DefaultFirebaseOptions.currentPlatform;
  if (options.apiKey.isEmpty || options.databaseURL == null) {
    throw StateError(
      'Firebase credentials are missing. Build with '
      '--dart-define-from-file=.env (see .env.example).',
    );
  }

  await Firebase.initializeApp(options: options);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Irrigation',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _accent,
          brightness: Brightness.light,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  double _moisture = 0;
  double _ph = 0;
  String _tank = '--';
  String _pump = '--';
  String _mode = '--';

  @override
  void initState() {
    super.initState();

    _db.child('moisture').onValue.listen((event) {
      setState(() {
        _moisture = (event.snapshot.value as num?)?.toDouble() ?? 0;
      });
    });

    _db.child('ph').onValue.listen((event) {
      setState(() {
        _ph = (event.snapshot.value as num?)?.toDouble() ?? 0;
      });
    });

    _db.child('tank').onValue.listen((event) {
      setState(() {
        _tank = event.snapshot.value?.toString() ?? '--';
      });
    });

    _db.child('pump/status').onValue.listen((event) {
      setState(() {
        _pump = event.snapshot.value?.toString() ?? '--';
      });
    });

    _db.child('mode').onValue.listen((event) {
      setState(() {
        _mode = event.snapshot.value?.toString() ?? '--';
      });
    });
  }

  void _setMode(String mode) => _db.child('mode').set(mode);

  void _setPumpCommand(String command) =>
      _db.child('pump/command').set(command);

  bool get _isOk => _tank.toUpperCase() == 'OK';
  bool get _isPumpOn => _pump.toUpperCase() == 'ON';
  bool get _isPumpOff => _pump.toUpperCase() == 'OFF';
  bool get _isAuto => _mode.toUpperCase() == 'AUTO';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text(
          'Smart Irrigation',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: _ink,
          ),
        ),
        elevation: 0,
        backgroundColor: _bg,
        surfaceTintColor: _bg,
        foregroundColor: _ink,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionLabel('Live readings'),
              const SizedBox(height: 10),
              _card2(
                children: [
                  _metricRow('Soil moisture', '${_moisture.toStringAsFixed(0)}%'),
                  _divider(),
                  _metricRow('Soil pH', _ph.toStringAsFixed(1)),
                  _divider(),
                  _metricRow(
                    'Tank status',
                    _tank,
                    badgeColor: _isOk ? _accent : const Color(0xFFDC2626),
                  ),
                  _divider(),
                  _metricRow(
                    'Pump status',
                    _pump,
                    badgeColor: _isPumpOn ? _accent : _muted,
                  ),
                  _divider(),
                  _metricRow(
                    'Mode',
                    _mode,
                    badgeColor: _isAuto ? const Color(0xFF2563EB) : _muted,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _sectionLabel('Controls'),
              const SizedBox(height: 10),
              _card2(
                padding: const EdgeInsets.all(14),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _controlButton(
                          label: 'AUTO',
                          active: _isAuto,
                          onTap: () => _setMode('AUTO'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _controlButton(
                          label: 'ON',
                          active: _isPumpOn && !_isAuto,
                          activeColor: _accent,
                          onTap: () => _setPumpCommand('ON'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _controlButton(
                          label: 'OFF',
                          active: _isPumpOff && !_isAuto,
                          activeColor: const Color(0xFFDC2626),
                          onTap: () => _setPumpCommand('OFF'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: _muted,
        ),
      ),
    );
  }

  Widget _card2({required List<Widget> children, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => const Divider(height: 1, thickness: 1, color: _border);

  Widget _metricRow(String label, String value, {Color? badgeColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14.5, color: _muted)),
          if (badgeColor != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: badgeColor,
                ),
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required String label,
    required VoidCallback onTap,
    bool active = false,
    Color activeColor = _ink,
  }) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: active ? activeColor : _bg,
          foregroundColor: active ? Colors.white : _ink,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
            side: BorderSide(color: active ? activeColor : _border),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
      ),
    );
  }
}
