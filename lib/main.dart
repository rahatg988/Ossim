import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------
// Firebase সেটিং (google-services.json থেকে)
// ---------------------------------------------------------------
const FirebaseOptions kFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyCfRwGDYv0GAPCfbSa2pA00NKNBNYCl2MY',
  appId: '1:107405549494:android:b811e39e1ebd494e35eb17',
  messagingSenderId: '107405549494',
  projectId: 'ossim-5e0c2',
  storageBucket: 'ossim-5e0c2.firebasestorage.app',
);

// ---------------------------------------------------------------
// ধ্রুবক
// ---------------------------------------------------------------
const List<String> kMonths = [
  'জানুয়ারি',
  'ফেব্রুয়ারি',
  'মার্চ',
  'এপ্রিল',
  'মে',
  'জুন',
  'জুলাই',
  'আগস্ট',
  'সেপ্টেম্বর',
  'অক্টোবর',
  'নভেম্বর',
  'ডিসেম্বর',
];
const List<String> kWeekdays = [
  'রবি',
  'সোম',
  'মঙ্গল',
  'বুধ',
  'বৃহস্পতি',
  'শুক্র',
  'শনি',
];

// মিলের একদিন শুরু হয় দুপুরে: দুপুর + রাত + পরদিন সকাল
const List<String> kCycleKeys = ['l', 'd', 'b'];
const List<String> kCycleNames = ['দুপুর', 'রাত', 'সকাল'];

const List<String> kYears = [
  'HSC',
  '1st year',
  '2nd year',
  '3rd year',
  'Final year',
  "Master's",
];

const int kPeriodDays = 4;

// খাবারের সময়-সূচি: [শুরু, শেষ] মিনিটে (রাত ১২টা থেকে)
// শেষের সময়গুলো আনুমানিক, ম্যানেজার সেটিংস থেকে বদলাবেন
const Map<String, List<int>> kDefaultSchedule = {
  'b': [8 * 60 + 40, 9 * 60 + 40],
  'l': [13 * 60 + 45, 14 * 60 + 45],
  'd': [20 * 60 + 15, 21 * 60 + 15],
};

Map<String, List<int>> copyDefaultSchedule() => {
      for (final e in kDefaultSchedule.entries)
        e.key: List<int>.from(e.value),
    };

// ---------------------------------------------------------------
// ছোট সাহায্যকারী ফাংশন
// ---------------------------------------------------------------
String bnDigits(String s) {
  const d = '০১২৩৪৫৬৭৮৯';
  return s.replaceAllMapped(RegExp(r'\d'), (m) => d[int.parse(m.group(0)!)]);
}

String normSearch(String s) {
  const bnD = '০১২৩৪৫৬৭৮৯';
  var r = s.toLowerCase().trim();
  for (int i = 0; i < 10; i++) {
    r = r.replaceAll(bnD[i], '$i');
  }
  return r;
}

String dateLabel(DateTime d) =>
    '${bnDigits('${d.day}')} ${kMonths[d.month - 1]} (${kWeekdays[d.weekday % 7]})';

String shortDate(DateTime d) =>
    '${bnDigits('${d.day}')} ${kMonths[d.month - 1]}';

String isoOf(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

DateTime todayDate() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

Map<String, String> mapOf(dynamic raw) {
  if (raw == null) return {};
  final out = <String, String>{};
  (raw as Map).forEach((k, v) => out[k.toString()] = v.toString());
  return out;
}

double numOf(dynamic v) => (v as num?)?.toDouble() ?? 0.0;

String money(double v) =>
    '${v < 0 ? '−' : ''}৳${bnDigits(v.abs().round().toString())}';

int nowMinutes() {
  final n = DateTime.now();
  return n.hour * 60 + n.minute;
}

String fmtTime(int m) {
  final h = m ~/ 60;
  final mi = m % 60;
  final h12 = h % 12 == 0 ? 12 : h % 12;
  String p;
  if (h < 4) {
    p = 'রাত';
  } else if (h < 12) {
    p = 'সকাল';
  } else if (h < 16) {
    p = 'দুপুর';
  } else if (h < 18) {
    p = 'বিকাল';
  } else {
    p = 'রাত';
  }
  return '${bnDigits('$h12')}:${bnDigits(mi.toString().padLeft(2, '0'))} $p';
}

String fmtRange(String key) =>
    '${fmtTime(data.schedule[key]![0])} – ${fmtTime(data.schedule[key]![1])}';

String fmtNoticeTime(String iso) {
  final dt = DateTime.parse(iso);
  return '${shortDate(dt)}, ${fmtTime(dt.hour * 60 + dt.minute)}';
}

Future<String?> pickOption(
    BuildContext context, String title, List<String> options) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            for (final o in options)
              ListTile(
                title: Text(o),
                onTap: () => Navigator.pop(ctx, o),
              ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------
// অনলাইন ডেটা (Firestore) — সব ফোনে একই তথ্য
// ---------------------------------------------------------------
double balOf(Map<String, dynamic> s) =>
    numOf(s['op']) + numOf(s['pd']) - numOf(s['pc']);

int countEaten(Map<String, dynamic> s, String fromIso, String toIso) {
  final eaten = mapOf(s['eaten']);
  int n = 0;
  eaten.forEach((k, v) {
    if (k.compareTo(fromIso) >= 0 && k.compareTo(toIso) <= 0) n += v.length;
  });
  return n;
}

void normalizeStudent(Map<String, dynamic> s) {
  // গতকালের মিল দিন রাখা হয়, কারণ আজ সকালের খাবার সেটারই অংশ
  final keepFrom = isoOf(addDays(todayDate(), -1));
  final meals = mapOf(s['meals']);
  meals.removeWhere((k, v) => k.compareTo(keepFrom) < 0);
  s['meals'] = meals;
  s['eaten'] = mapOf(s['eaten']);
  s['op'] = numOf(s['op']);
  s['pd'] = numOf(s['pd']);
  s['pc'] = numOf(s['pc']);
  s['slots'] = (s['slots'] as num?)?.toInt() ?? 0;
  s['history'] = (s['history'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ??
      <Map<String, dynamic>>[];
}

class AppData extends ChangeNotifier {
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> notices = [];
  Map<String, List<int>> schedule = copyDefaultSchedule();
  String managerPin = '1234';
  String managerRoom = '';
  String periodStart = isoOf(todayDate());

  bool studentsLoaded = false;
  bool configLoaded = false;
  bool dark = false; // শুধু এই ফোনের পছন্দ
  String lastError = ''; // অনলাইন সংযোগের শেষ সমস্যা

  void _err(Object e) {
    lastError = e.toString();
    notifyListeners();
  }

  FirebaseFirestore get _fs => FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> get _cfg =>
      _fs.collection('config').doc('app');

  void start() {
    _fs.collection('students').snapshots().listen((snap) {
      final list = <Map<String, dynamic>>[];
      for (final d in snap.docs) {
        final s = Map<String, dynamic>.from(d.data());
        normalizeStudent(s);
        list.add(s);
      }
      list.sort((a, b) =>
          ((a['id'] as num?) ?? 0).compareTo((b['id'] as num?) ?? 0));
      students = list;
      if (!snap.metadata.isFromCache || list.isNotEmpty) {
        studentsLoaded = true;
        lastError = '';
      }
      notifyListeners();
    }, onError: _err);

    _cfg.snapshots().listen((doc) {
      if (!doc.exists) {
        // একদম প্রথমবার: সার্ভারে সত্যিই কিছু না থাকলে ডিফল্ট বসানো হয়
        if (!doc.metadata.isFromCache) {
          _cfg.set({
            'managerPin': managerPin,
            'managerRoom': managerRoom,
            'periodStart': periodStart,
            'schedule': kDefaultSchedule,
          }).catchError(_err);
        }
        return;
      }
      final m = doc.data() ?? {};
      managerPin = (m['managerPin'] ?? '1234').toString();
      managerRoom = (m['managerRoom'] ?? '').toString();
      periodStart = (m['periodStart'] ?? periodStart).toString();
      final sc = m['schedule'];
      if (sc is Map) {
        for (final k in ['b', 'l', 'd']) {
          final v = sc[k];
          if (v is List && v.length == 2) {
            schedule[k] = [(v[0] as num).toInt(), (v[1] as num).toInt()];
          }
        }
      }
      configLoaded = true;
      lastError = '';
      notifyListeners();
    }, onError: _err);

    _fs.collection('notices').orderBy('at').snapshots().listen((snap) {
      notices = snap.docs.map((d) {
        final m = Map<String, dynamic>.from(d.data());
        m['id'] = d.id;
        return m;
      }).toList();
      notifyListeners();
    }, onError: _err);
  }

  Future<bool> ensureLoaded(
      {bool needStudents = true, bool needConfig = false}) async {
    bool ready() =>
        (!needStudents || studentsLoaded) && (!needConfig || configLoaded);
    final end = DateTime.now().add(const Duration(seconds: 15));
    while (DateTime.now().isBefore(end)) {
      if (ready()) return true;
      if (lastError.isNotEmpty) break; // আসল সমস্যা ধরা পড়লে দেরি না করে জানানো
      await Future.delayed(const Duration(milliseconds: 200));
    }
    return ready();
  }

  String failMessage() {
    if (lastError.isNotEmpty) {
      return 'সংযোগে সমস্যা:\n$lastError';
    }
    return 'তথ্য আনা যায়নি। ইন্টারনেট চালু করে আবার চেষ্টা করুন';
  }

  // ---- লেখা (অনলাইনে না থাকলেও ফোনে জমে থাকে, নেট এলে সিঙ্ক হয়) ----
  void saveStudent(Map<String, dynamic> s) {
    notifyListeners();
    _fs
        .collection('students')
        .doc('${s['id']}')
        .set(s)
        .catchError(_err);
  }

  void deleteStudent(Map<String, dynamic> s) {
    students.remove(s);
    notifyListeners();
    _fs.collection('students').doc('${s['id']}').delete().catchError(_err);
  }

  void saveConfig() {
    notifyListeners();
    _cfg.set({
      'managerPin': managerPin,
      'managerRoom': managerRoom,
      'periodStart': periodStart,
      'schedule': schedule,
    }, SetOptions(merge: true)).catchError(_err);
  }

  void addNotice(String text) {
    _fs.collection('notices').add({
      'text': text,
      'at': DateTime.now().toIso8601String(),
    }).then<void>((_) {}).catchError(_err);
  }

  void deleteNotice(String id) {
    _fs.collection('notices').doc(id).delete().catchError(_err);
  }

  // নতুন ৪ দিনের হিসাব: চলমান হিসাব ইতিহাসে জমা হয়
  void commitPeriod() {
    final today = todayDate();
    final fromIso = periodStart;
    final toIso = isoOf(today);
    final batch = _fs.batch();
    for (final s in students) {
      final cl = balOf(s);
      final hist = (s['history'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      hist.add({
        'from': fromIso,
        'to': toIso,
        'op': numOf(s['op']),
        'pd': numOf(s['pd']),
        'pc': numOf(s['pc']),
        'cl': cl,
        'slots': s['slots'] ?? 0,
        'ate': countEaten(s, fromIso, toIso),
      });
      s['history'] = hist;
      s['op'] = cl;
      s['pd'] = 0.0;
      s['pc'] = 0.0;
      s['slots'] = 0;
      batch.set(_fs.collection('students').doc('${s['id']}'), s);
    }
    periodStart = toIso;
    batch.set(_cfg, {'periodStart': toIso}, SetOptions(merge: true));
    batch.commit().catchError(_err);
    notifyListeners();
  }

  void setDark(bool v) {
    dark = v;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setBool('dark', v));
  }
}

final AppData data = AppData();

// ---------------------------------------------------------------
// মিলের লাইন (কার্ডে দেখানোর জন্য)
// ---------------------------------------------------------------
String cycleNames(String v, String eaten) {
  final parts = <String>[];
  for (int j = 0; j < 3; j++) {
    if (v.contains(kCycleKeys[j])) {
      final name = j == 2 ? 'পরদিন সকাল' : kCycleNames[j];
      parts.add(name + (eaten.contains(kCycleKeys[j]) ? ' ✓' : ''));
    }
  }
  return parts.join(', ');
}

List<String> activeLines(Map<String, dynamic> s) {
  final meals = mapOf(s['meals']);
  final eaten = mapOf(s['eaten']);
  final today = todayDate();
  final todayIso = isoOf(today);
  final yIso = isoOf(addDays(today, -1));
  final keys = meals.keys.toList()..sort();
  final lines = <String>[];
  for (final k in keys) {
    final v = meals[k] ?? '';
    if (v.isEmpty) continue;
    if (k.compareTo(todayIso) >= 0) {
      lines.add(
          '${dateLabel(DateTime.parse(k))}: ${cycleNames(v, eaten[k] ?? '')}');
    } else if (k == yIso &&
        v.contains('b') &&
        nowMinutes() < data.schedule['l']![0]) {
      final e = (eaten[k] ?? '').contains('b') ? ' ✓' : '';
      lines.add('${dateLabel(today)}: সকাল$e');
    }
  }
  return lines;
}

int activeDays(Map<String, dynamic> s) {
  final meals = mapOf(s['meals']);
  final todayIso = isoOf(todayDate());
  int n = 0;
  meals.forEach((k, v) {
    if (v.isNotEmpty && k.compareTo(todayIso) >= 0) n++;
  });
  return n;
}

// ---------------------------------------------------------------
// সবার জন্য ছোট উইজেট
// ---------------------------------------------------------------
Widget noticeBanner({VoidCallback? onTap}) {
  final text = data.notices.isNotEmpty
      ? (data.notices.last['text'] ?? '').toString()
      : 'কোনো নতুন নোটিশ নেই।';
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade700),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '📢 $text',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.black87, fontWeight: FontWeight.w500),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black54),
        ],
      ),
    ),
  );
}

Widget accountRows(double op, double pd, double pc, double cl) {
  Widget row(String a, String b, {Color? color, bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(a),
            Text(b,
                style: TextStyle(
                    color: color,
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      );
  return Column(
    children: [
      row('শুরুর ব্যালেন্স', money(op)),
      row('জমা', '+${money(pd)}'),
      row('মিল খরচ', '−${money(pc)}'),
      const Divider(height: 10),
      row(
        cl >= 0 ? 'পাওনা' : 'বকেয়া',
        money(cl.abs()),
        color: cl >= 0 ? Colors.green : Colors.red,
        bold: true,
      ),
    ],
  );
}

Widget priceCard() {
  Widget row(String title, String price) => ListTile(
        dense: true,
        title: Text(title),
        trailing: Text(price,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      );
  return Card(
    child: Column(
      children: [
        row('শুধু সকাল', '৳ ১৫'),
        const Divider(height: 1),
        row('শুধু দুপুর', '৳ ৩৫'),
        const Divider(height: 1),
        row('শুধু রাত', '৳ ৩০'),
        const Divider(height: 1),
        row('দুপুর + রাত', '৳ ৬০'),
        const Divider(height: 1),
        row('সকাল + দুপুর', '৳ ৫০'),
        const Divider(height: 1),
        row('সকাল + রাত', '৳ ৪৫'),
        const Divider(height: 1),
        row('সকাল + দুপুর + রাত (পুরো দিন)', '৳ ৭০'),
      ],
    ),
  );
}

Widget scheduleCard() {
  Widget row(String key, String name) => ListTile(
        dense: true,
        leading: const Icon(Icons.access_time, color: Colors.teal),
        title: Text(name),
        trailing: Text(fmtRange(key),
            style: const TextStyle(fontWeight: FontWeight.bold)),
      );
  return Card(
    child: Column(
      children: [
        row('b', 'সকাল'),
        const Divider(height: 1),
        row('l', 'দুপুর'),
        const Divider(height: 1),
        row('d', 'রাত'),
      ],
    ),
  );
}

// ---------------------------------------------------------------
// শুরু
// ---------------------------------------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: kFirebaseOptions);
  final prefs = await SharedPreferences.getInstance();
  data.dark = prefs.getBool('dark') ?? false;
  data.start();
  runApp(const OssimApp());
}

class OssimApp extends StatelessWidget {
  const OssimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: data,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ossim',
        themeMode: data.dark ? ThemeMode.dark : ThemeMode.light,
        theme: ThemeData(
          brightness: Brightness.light,
          colorSchemeSeed: Colors.teal,
          scaffoldBackgroundColor: const Color(0xFFAFAFAF),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorSchemeSeed: Colors.teal,
          useMaterial3: true,
        ),
        home: const LoginScreen(),
      ),
    );
  }
}

// ---------------------------------------------------------------
// লগইন: শিক্ষার্থী / ম্যানেজার
// ---------------------------------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool manager = false;
  bool busy = false;
  final TextEditingController idC = TextEditingController();
  final TextEditingController pinC = TextEditingController();
  String error = '';

  @override
  void dispose() {
    idC.dispose();
    pinC.dispose();
    super.dispose();
  }

  Future<void> _studentLogin() async {
    final q = normSearch(idC.text);
    if (q.isEmpty) {
      setState(() => error = 'নাম বা নম্বর লিখুন');
      return;
    }
    setState(() {
      busy = true;
      error = '';
    });
    final ok = await data.ensureLoaded();
    if (!mounted) return;
    setState(() => busy = false);
    if (!ok) {
      setState(() => error = data.failMessage());
      return;
    }
    final students = data.students;
    var found = students
        .where((s) =>
            s['id'].toString() == q || normSearch(s['name'].toString()) == q)
        .toList();
    if (found.isEmpty) {
      found = students
          .where((s) => normSearch(s['name'].toString()).contains(q))
          .toList();
    }
    if (found.isEmpty) {
      setState(() => error = 'কোনো শিক্ষার্থী পাওয়া যায়নি');
      return;
    }
    if (found.length > 1) {
      setState(() => error = 'একাধিক নাম মিলেছে, পুরো নাম বা নম্বর লিখুন');
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => StudentScreen(studentId: found.first['id'] as int),
      ),
    );
  }

  Future<void> _managerLogin() async {
    setState(() {
      busy = true;
      error = '';
    });
    final ok =
        await data.ensureLoaded(needStudents: false, needConfig: true);
    if (!mounted) return;
    setState(() => busy = false);
    if (!ok) {
      setState(() => error = data.failMessage());
      return;
    }
    if (pinC.text.trim() != data.managerPin) {
      setState(() => error = 'পিন ভুল হয়েছে');
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.rice_bowl, size: 72, color: Colors.teal),
              const SizedBox(height: 8),
              const Text(
                'Ossim-এ স্বাগতম',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('শিক্ষার্থী লগইন'),
                    selected: !manager,
                    onSelected: (_) => setState(() {
                      manager = false;
                      error = '';
                    }),
                  ),
                  ChoiceChip(
                    label: const Text('ম্যানেজার লগইন'),
                    selected: manager,
                    onSelected: (_) => setState(() {
                      manager = true;
                      error = '';
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!manager) ...[
                TextField(
                  controller: idC,
                  decoration: const InputDecoration(
                    labelText: 'আপনার নাম বা নম্বর',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'নাম বা স্টুডেন্ট নম্বর, যেকোনোটা লিখলেই হবে।',
                  style: TextStyle(fontSize: 12),
                ),
              ] else ...[
                TextField(
                  controller: pinC,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'ম্যানেজার পিন',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'প্রথমবার ডিফল্ট পিন ১২৩৪। ঢুকে সেটিংস থেকে বদলে নিন।',
                  style: TextStyle(fontSize: 12),
                ),
              ],
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: busy
                      ? null
                      : (manager ? _managerLogin : _studentLogin),
                  child: busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          manager ? 'ম্যানেজার হিসেবে ঢুকুন' : 'প্রবেশ করুন',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void goLogin(BuildContext context) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (r) => false,
  );
}

// ---------------------------------------------------------------
// শিক্ষার্থীর স্ক্রিন
// ---------------------------------------------------------------
class StudentScreen extends StatelessWidget {
  final int studentId;
  const StudentScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: data,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        Map<String, dynamic>? s;
        for (final x in data.students) {
          if (x['id'] == studentId) s = x;
        }
        final startDate = DateTime.parse(data.periodStart);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Ossim'),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                onPressed: () => data.setDark(!isDark),
              ),
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NoticesScreen(isManager: false),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => goLogin(context),
              ),
            ],
          ),
          body: s == null
              ? const Center(child: Text('আপনার তথ্য পাওয়া যায়নি।'))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    noticeBanner(onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const NoticesScreen(isManager: false),
                        ),
                      );
                    }),
                    Card(
                      margin: const EdgeInsets.only(top: 10),
                      child: ListTile(
                        leading: const Icon(Icons.admin_panel_settings,
                            color: Colors.teal, size: 30),
                        title: const Text('বর্তমান ম্যানেজার',
                            style: TextStyle(fontSize: 12)),
                        subtitle: Text(
                          data.managerRoom.isEmpty
                              ? 'এখনও নির্ধারণ করা হয়নি'
                              : 'রুম ${data.managerRoom} এর ভাইয়েরা',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  child: Text('${s['id']}'),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s['name'].toString(),
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                        'বর্ষ: ${s['year']} | রুম: ${s['room']}',
                                        style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'চলমান হিসাব (${shortDate(startDate)} – ${shortDate(addDays(startDate, kPeriodDays - 1))})',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            accountRows(numOf(s['op']), numOf(s['pd']),
                                numOf(s['pc']), balOf(s)),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          HistoryScreen(studentId: studentId),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.history),
                                label: const Text(
                                    'আগের সব হিসাব দেখুন (ইতিহাস)'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.restaurant, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  activeDays(s) > 0
                                      ? 'আপনার মিল: ${activeDays(s)} দিন চালু'
                                      : (activeLines(s).isNotEmpty
                                          ? 'আপনার মিল চালু'
                                          : 'আপনার মিল বন্ধ'),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            for (final line in activeLines(s))
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 24, top: 3),
                                child: Text(line),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 12, bottom: 2),
                      child: Text('⏰ খাবারের সময়-সূচি',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal)),
                    ),
                    scheduleCard(),
                    const Padding(
                      padding: EdgeInsets.only(top: 12, bottom: 2),
                      child: Text('🍽️ মূল্য তালিকা (প্রতি দিন)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal)),
                    ),
                    priceCard(),
                  ],
                ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------
// হিসাবের ইতিহাস
// ---------------------------------------------------------------
class HistoryScreen extends StatelessWidget {
  final int studentId;
  const HistoryScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: data,
      builder: (context, _) {
        Map<String, dynamic>? student;
        for (final x in data.students) {
          if (x['id'] == studentId) student = x;
        }
        if (student == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('হিসাবের ইতিহাস'),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            body: const Center(child: Text('তথ্য পাওয়া যায়নি।')),
          );
        }
        final hist = (student['history'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList()
            .reversed
            .toList();
        final start = DateTime.parse(data.periodStart);

        return Scaffold(
          appBar: AppBar(
            title: const Text('হিসাবের ইতিহাস'),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.teal),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('চলমান হিসাব',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                              '${shortDate(start)} – ${shortDate(addDays(start, kPeriodDays - 1))}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.teal)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      accountRows(numOf(student['op']), numOf(student['pd']),
                          numOf(student['pc']), balOf(student)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                child: Text('আগের হিসাব (${bnDigits('${hist.length}')}টি)',
                    style: const TextStyle(fontSize: 13)),
              ),
              if (hist.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('এখনও কোনো আগের হিসাব নেই।')),
                ),
              for (final h in hist)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${shortDate(DateTime.parse(h['from'] as String))} – ${shortDate(DateTime.parse(h['to'] as String))}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'বেলা ${bnDigits('${h['slots'] ?? 0}')} | খেয়েছে ${bnDigits('${h['ate'] ?? 0}')}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        accountRows(numOf(h['op']), numOf(h['pd']),
                            numOf(h['pc']), numOf(h['cl'])),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------
// নোটিফিকেশন
// ---------------------------------------------------------------
class NoticesScreen extends StatelessWidget {
  final bool isManager;
  const NoticesScreen({super.key, required this.isManager});

  void _compose(BuildContext context) {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('নতুন নোটিফিকেশন'),
        content: TextField(
          controller: c,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'সবার জন্য নোটিফিকেশনের লেখা...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () {
              final t = c.text.trim();
              if (t.isEmpty) return;
              data.addNotice(t);
              Navigator.pop(ctx);
            },
            child: const Text('পাঠান'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: data,
      builder: (context, _) {
        final items = data.notices.reversed.toList();
        return Scaffold(
          appBar: AppBar(
            title: const Text('নোটিফিকেশন'),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          floatingActionButton: isManager
              ? FloatingActionButton.extended(
                  onPressed: () => _compose(context),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.send),
                  label: const Text('নতুন নোটিফিকেশন'),
                )
              : null,
          body: items.isEmpty
              ? const Center(child: Text('কোনো নোটিফিকেশন নেই।'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                  children: [
                    if (isManager)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'পাঠানো নোটিফিকেশন সবার অ্যাপে দেখা যাবে (অ্যাপ খুললে বা খোলা থাকলে)। ফোনে আলাদা শব্দ বা পপআপ আসবে না।',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    for (final n in items)
                      Card(
                        child: ListTile(
                          title: Text((n['text'] ?? '').toString()),
                          subtitle: Text(fmtNoticeTime(n['at'].toString()),
                              style: const TextStyle(fontSize: 11)),
                          trailing: isManager
                              ? IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      data.deleteNotice(n['id'].toString()),
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------
// ম্যানেজারের হোম
// ---------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String searchQuery = '';

  static const int maxMealDays = 4;

  List<Map<String, dynamic>> get students => data.students;

  int _price(bool b, bool l, bool d) {
    if (b && l && d) return 70;
    if (b && l) return 50;
    if (b && d) return 45;
    if (l && d) return 60;
    if (b) return 15;
    if (l) return 35;
    if (d) return 30;
    return 0;
  }

  // f = [দুপুর, রাত, সকাল]
  int _priceOf(List<bool> f) => _price(f[2], f[0], f[1]);

  List<bool> _flagsOf(String? v) {
    final s = v ?? '';
    return [s.contains('l'), s.contains('d'), s.contains('b')];
  }

  String _flagsToStr(List<bool> f) {
    var r = '';
    if (f[0]) r += 'l';
    if (f[1]) r += 'd';
    if (f[2]) r += 'b';
    return r;
  }

  // ---- নতুন ৪ দিনের হিসাব ----
  void _confirmNewPeriod() {
    final start = DateTime.parse(data.periodStart);
    final end = addDays(start, kPeriodDays - 1);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('নতুন ৪ দিনের হিসাব শুরু করবেন?'),
        content: Text(
          'চলমান হিসাব (${shortDate(start)} – ${shortDate(end)}) সবার ইতিহাসে জমা হবে। প্রত্যেকের বর্তমান পাওনা বা বকেয়া নতুন হিসাবের শুরুর ব্যালেন্স হিসেবে যাবে। মিল চালু থাকা বেলাগুলো আগের মতোই থাকবে।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () {
              data.commitPeriod();
              Navigator.pop(ctx);
            },
            child: const Text('হ্যাঁ, শুরু করুন'),
          ),
        ],
      ),
    );
  }

  Widget _periodCard() {
    final start = DateTime.parse(data.periodStart);
    final end = addDays(start, kPeriodDays - 1);
    final today = todayDate();
    final over = today.isAfter(end);
    int dn = today.difference(start).inDays + 1;
    if (dn < 1) dn = 1;
    if (dn > kPeriodDays) dn = kPeriodDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: over ? Colors.orange.shade800 : Colors.transparent),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('চলমান ৪ দিনের হিসাব',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '${shortDate(start)} – ${shortDate(end)} | ${over ? '৪ দিন পূর্ণ' : 'দিন ${bnDigits('$dn')}/৪'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _confirmNewPeriod,
                  child: const Text('নতুন হিসাব শুরু'),
                ),
              ],
            ),
            if (over)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '৪ দিন পূর্ণ হয়েছে। নতুন হিসাব শুরু করুন।',
                  style:
                      TextStyle(fontSize: 12, color: Colors.orange.shade900),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---- স্টুডেন্ট যোগ ----
  void _showAddStudentDialog() {
    final nameC = TextEditingController();
    final yearC = TextEditingController();
    final roomC = TextEditingController();
    final depositC = TextEditingController();
    bool tried = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('নতুন স্টুডেন্ট যোগ করুন'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameC,
                  decoration: const InputDecoration(labelText: 'নাম'),
                ),
                // বর্ষ: ট্যাপ করলে অপশনের তালিকা আসবে
                TextField(
                  controller: yearC,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'বর্ষ',
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                    errorText: (tried && yearC.text.isEmpty)
                        ? 'বর্ষ বেছে নিন'
                        : null,
                  ),
                  onTap: () async {
                    final v = await pickOption(ctx, 'বর্ষ বেছে নিন', kYears);
                    if (v != null) {
                      setDialogState(() => yearC.text = v);
                    }
                  },
                ),
                TextField(
                  controller: roomC,
                  decoration: const InputDecoration(labelText: 'রুম নম্বর'),
                ),
                TextField(
                  controller: depositC,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'শুরুর জমা (৳)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বাতিল'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameC.text.trim();
                if (name.isEmpty) return;
                if (yearC.text.isEmpty) {
                  setDialogState(() => tried = true);
                  return;
                }
                final deposit = double.tryParse(depositC.text.trim()) ?? 0.0;
                int nextId = 1;
                for (final s in students) {
                  final id = (s['id'] as num).toInt();
                  if (id >= nextId) nextId = id + 1;
                }
                final s = <String, dynamic>{
                  'id': nextId,
                  'name': name,
                  'year': yearC.text,
                  'room': roomC.text.trim(),
                  'op': 0.0,
                  'pd': deposit,
                  'pc': 0.0,
                  'slots': 0,
                  'meals': <String, String>{},
                  'eaten': <String, String>{},
                  'history': <Map<String, dynamic>>[],
                };
                students.add(s);
                data.saveStudent(s);
                Navigator.pop(ctx);
              },
              child: const Text('যোগ করুন'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDepositDialog(Map<String, dynamic> student) {
    final amountC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${student['name']} - টাকা জমা'),
        content: TextField(
          controller: amountC,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'পরিমাণ (৳)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountC.text.trim()) ?? 0.0;
              if (amount <= 0) return;
              student['pd'] = numOf(student['pd']) + amount;
              data.saveStudent(student);
              Navigator.pop(ctx);
            },
            child: const Text('জমা দিন'),
          ),
        ],
      ),
    );
  }

  void _showMealDialog(Map<String, dynamic> student) {
    final meals = mapOf(student['meals']);
    final today = todayDate();
    final dates = List.generate(maxMealDays, (i) => addDays(today, i));
    final locked = dates.map((d) => _flagsOf(meals[isoOf(d)])).toList();
    final sel = locked.map((f) => List<bool>.from(f)).toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          int total = 0;
          int newSlots = 0;
          for (int i = 0; i < maxMealDays; i++) {
            total += _priceOf(sel[i]) - _priceOf(locked[i]);
            for (int j = 0; j < 3; j++) {
              if (sel[i][j] && !locked[i][j]) newSlots++;
            }
          }

          return AlertDialog(
            title: Text('${student['name']} - মিল চালু করুন'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'মিলের একদিন শুরু হয় দুপুরে। পুরো একদিন = ওই তারিখের দুপুর + রাত + পরদিন সকাল। ধূসর বেলা আগে থেকেই চালু।',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  for (int i = 0; i < maxMealDays; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(dateLabel(dates[i]),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ),
                              GestureDetector(
                                onTap: () => setDialogState(() {
                                  for (int j = 0; j < 3; j++) {
                                    sel[i][j] = true;
                                  }
                                }),
                                child: const Text(
                                  'পুরো দিন',
                                  style: TextStyle(
                                      color: Colors.teal, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            children: [
                              for (int j = 0; j < 3; j++)
                                FilterChip(
                                  label: Text(j == 2
                                      ? 'সকাল (${shortDate(addDays(dates[i], 1))})'
                                      : kCycleNames[j]),
                                  selected: sel[i][j],
                                  onSelected: locked[i][j]
                                      ? null
                                      : (v) => setDialogState(
                                          () => sel[i][j] = v),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'নতুন যোগ: ৳ $total',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('বাতিল'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (newSlots == 0) return;
                  final updated = Map<String, String>.from(meals);
                  for (int i = 0; i < maxMealDays; i++) {
                    final str = _flagsToStr(sel[i]);
                    final key = isoOf(dates[i]);
                    if (str.isEmpty) {
                      updated.remove(key);
                    } else {
                      updated[key] = str;
                    }
                  }
                  student['pc'] = numOf(student['pc']) + total;
                  student['slots'] =
                      ((student['slots'] as num?)?.toInt() ?? 0) + newSlots;
                  student['meals'] = updated;
                  data.saveStudent(student);
                  Navigator.pop(ctx);
                },
                child: const Text('চালু করুন'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ডিলিট করবেন?'),
        content: Text('${student['name']} কে তালিকা থেকে মুছে ফেলা হবে।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('না'),
          ),
          ElevatedButton(
            onPressed: () {
              data.deleteStudent(student);
              Navigator.pop(ctx);
            },
            child: const Text('হ্যাঁ, ডিলিট'),
          ),
        ],
      ),
    );
  }

  void _openNotices() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NoticesScreen(isManager: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: data,
      builder: (context, _) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final q = normSearch(searchQuery);
    final filtered = students.where((s) {
      if (q.isEmpty) return true;
      return normSearch(s['name'].toString()).contains(q) ||
          normSearch(s['id'].toString()).contains(q) ||
          normSearch(s['room'].toString()).contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ossim (ম্যানেজার)'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            onPressed: () => data.setDark(!isDark),
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _openNotices,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => goLogin(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStudentDialog,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('স্টুডেন্ট যোগ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            noticeBanner(onTap: _openNotices),
            const SizedBox(height: 10),
            _periodCard(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AttendanceScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.fact_check),
                    label: const Text('খাবার চিহ্নিত করুন'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _openNotices,
                    icon: const Icon(Icons.send),
                    label: const Text('নোটিফিকেশন'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: InputDecoration(
                hintText: 'স্টুডেন্ট নম্বর বা নাম দিয়ে খুঁজুন...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        students.isEmpty
                            ? 'কোনো স্টুডেন্ট নেই।\nনিচের "স্টুডেন্ট যোগ" বাটন চাপুন।'
                            : 'কাউকে খুঁজে পাওয়া যায়নি।',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final student = filtered[index];
                        final double balance = balOf(student);
                        final lines = activeLines(student);
                        final days = activeDays(student);

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      child: Text('${student['id']}'),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student['name'].toString(),
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                              'বর্ষ: ${student['year']} | রুম: ${student['room']}'),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _confirmDelete(student),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('জমা: ${money(numOf(student['pd']))}'),
                                    Text(
                                      balance >= 0
                                          ? 'পাওনা: ${money(balance)}'
                                          : 'বকেয়া: ${money(balance.abs())}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: balance >= 0
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.restaurant,
                                      size: 16,
                                      color: lines.isNotEmpty
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      days > 0
                                          ? 'মিল চালু: $days দিন'
                                          : (lines.isNotEmpty
                                              ? 'মিল চালু'
                                              : 'মিল বন্ধ'),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: lines.isNotEmpty
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                for (final line in lines)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 22, top: 2),
                                    child: Text(line,
                                        style: const TextStyle(fontSize: 12)),
                                  ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.teal.shade700,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () =>
                                            _showDepositDialog(student),
                                        icon: const Icon(Icons.payment),
                                        label: const Text('জমা দিন'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.orange.shade800,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () =>
                                            _showMealDialog(student),
                                        icon: const Icon(Icons.restaurant),
                                        label: const Text('মিল যোগ'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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

// ---------------------------------------------------------------
// খাবার চিহ্নিত করা (ম্যানেজার)
// ---------------------------------------------------------------
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late final DateTime today;
  late DateTime cycle;
  int slot = 0; // 0 = দুপুর, 1 = রাত, 2 = পরদিন সকাল

  @override
  void initState() {
    super.initState();
    today = todayDate();
    final n = nowMinutes();
    // সময়-সূচি অনুযায়ী এখন কোন বেলা চলছে তা নিজে থেকে বেছে নেওয়া হয়
    if (n < data.schedule['l']![0]) {
      cycle = addDays(today, -1);
      slot = 2;
    } else if (n < data.schedule['d']![0]) {
      cycle = today;
      slot = 0;
    } else {
      cycle = today;
      slot = 1;
    }
  }

  String get _key => isoOf(cycle);
  String get _ch => kCycleKeys[slot];

  bool _hasMeal(Map<String, dynamic> s) {
    final v = mapOf(s['meals'])[_key] ?? '';
    return v.contains(_ch);
  }

  bool _ate(Map<String, dynamic> s) {
    final v = mapOf(s['eaten'])[_key] ?? '';
    return v.contains(_ch);
  }

  void _setAte(Map<String, dynamic> s, bool value) {
    final e = mapOf(s['eaten']);
    var cur = e[_key] ?? '';
    if (value) {
      if (!cur.contains(_ch)) cur += _ch;
    } else {
      cur = cur.replaceAll(_ch, '');
    }
    if (cur.isEmpty) {
      e.remove(_key);
    } else {
      e[_key] = cur;
    }
    s['eaten'] = e;
    data.saveStudent(s);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: data,
      builder: (context, _) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final all = data.students;
    final on = all.where(_hasMeal).toList();
    final off = all.where((s) => !_hasMeal(s)).toList();
    final ateCount = on.where(_ate).length;
    final remaining = on.length - ateCount;
    final canPrev = cycle.isAfter(addDays(today, -1));
    final canNext = cycle.isBefore(addDays(today, 3));
    final mealDate = slot == 2 ? addDays(cycle, 1) : cycle;
    final timeKey = ['l', 'd', 'b'][slot];

    return Scaffold(
      appBar: AppBar(
        title: const Text('খাবার চিহ্নিত করুন'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'খেয়েছে: ${bnDigits('$ateCount')}',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
                Text(
                  'বাকি: ${bnDigits('$remaining')}',
                  style: TextStyle(fontSize: 12, color: Colors.amber.shade200),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: canPrev
                      ? () => setState(() => cycle = addDays(cycle, -1))
                      : null,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'মিল দিন: ${dateLabel(cycle)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'দুপুর থেকে পরদিন সকাল পর্যন্ত',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: canNext
                      ? () => setState(() => cycle = addDays(cycle, 1))
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (int i = 0; i < 3; i++)
                  ChoiceChip(
                    label: Text(i == 2
                        ? 'পরদিন সকাল (${shortDate(addDays(cycle, 1))})'
                        : kCycleNames[i]),
                    selected: slot == i,
                    onSelected: (_) => setState(() => slot = i),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'খাবারের তারিখ: ${dateLabel(mealDate)}\nসময়: ${fmtRange(timeKey)}',
              style: const TextStyle(fontSize: 12),
            ),
            if (on.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    for (final s in on) {
                      _setAte(s, true);
                    }
                  },
                  child: const Text('সবাইকে চিহ্নিত করুন'),
                ),
              ),
            Expanded(
              child: on.isEmpty
                  ? const Center(
                      child: Text('এই বেলায় কারও মিল চালু নেই।'),
                    )
                  : ListView(
                      children: [
                        for (final s in on)
                          Card(
                            child: CheckboxListTile(
                              value: _ate(s),
                              onChanged: (v) => _setAte(s, v ?? false),
                              title: Text(
                                s['name'].toString(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('রুম: ${s['room']}'),
                              secondary: CircleAvatar(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                child: Text('${s['id']}'),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            if (off.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'এই বেলায় মিল বন্ধ: ${off.map((s) => s['name']).join(', ')}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
// সেটিংস (শুধু ম্যানেজার)
// ---------------------------------------------------------------
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---- ম্যানেজারের রুম ----
  void _pickRoom() {
    final rooms = <String>{};
    for (final s in data.students) {
      final r = s['room'].toString();
      if (r.isNotEmpty) rooms.add(r);
    }
    final c = TextEditingController();
    String selected = data.managerRoom;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('ম্যানেজার কত নম্বর রুমে থাকেন?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  children: [
                    for (final r in rooms)
                      ChoiceChip(
                        label: Text('রুম $r'),
                        selected: selected == r,
                        onSelected: (_) => setD(() {
                          selected = r;
                          c.clear();
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('তালিকায় না থাকলে নম্বর লিখুন',
                    style: TextStyle(fontSize: 12)),
                TextField(
                  controller: c,
                  decoration: const InputDecoration(labelText: 'রুম নম্বর'),
                  onChanged: (_) => setD(() => selected = ''),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বাতিল'),
            ),
            ElevatedButton(
              onPressed: () {
                final room =
                    c.text.trim().isNotEmpty ? c.text.trim() : selected;
                if (room.isEmpty) return;
                data.managerRoom = room;
                data.saveConfig();
                Navigator.pop(ctx);
              },
              child: const Text('সেভ করুন'),
            ),
          ],
        ),
      ),
    );
  }

  // ---- সময়-সূচি (শুরু ও শেষ) ----
  Future<void> _editSchedule(String key, String name) async {
    final cur = data.schedule[key]!;
    final start = await showTimePicker(
      context: context,
      helpText: '$name - শুরুর সময়',
      initialTime: TimeOfDay(hour: cur[0] ~/ 60, minute: cur[0] % 60),
    );
    if (start == null || !mounted) return;
    final end = await showTimePicker(
      context: context,
      helpText: '$name - শেষের সময়',
      initialTime: TimeOfDay(hour: cur[1] ~/ 60, minute: cur[1] % 60),
    );
    if (end == null || !mounted) return;
    final s = start.hour * 60 + start.minute;
    final e = end.hour * 60 + end.minute;
    if (e <= s) {
      _snack('শেষের সময় শুরুর পরে হতে হবে');
      return;
    }
    data.schedule[key] = [s, e];
    data.saveConfig();
  }

  void _resetSchedule() {
    data.schedule = copyDefaultSchedule();
    data.saveConfig();
  }

  Widget _scheduleRow(String key, String name) {
    return ListTile(
      leading: const Icon(Icons.access_time, color: Colors.teal),
      title: Text(name),
      subtitle: Text(fmtRange(key)),
      trailing: const Icon(Icons.edit, size: 18),
      onTap: () => _editSchedule(key, name),
    );
  }

  // ---- পিন পরিবর্তন ----
  void _changePin() {
    final curC = TextEditingController();
    final newC = TextEditingController();
    final confC = TextEditingController();
    String err = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('ম্যানেজার পিন পরিবর্তন'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: curC,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'বর্তমান পিন'),
                ),
                TextField(
                  controller: newC,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'নতুন পিন (কমপক্ষে ৪ অক্ষর)'),
                ),
                TextField(
                  controller: confC,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'নতুন পিন আবার লিখুন'),
                ),
                if (err.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(err,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বাতিল'),
            ),
            ElevatedButton(
              onPressed: () {
                if (curC.text.trim() != data.managerPin) {
                  setD(() => err = 'বর্তমান পিন ভুল');
                  return;
                }
                final np = newC.text.trim();
                if (np.length < 4) {
                  setD(() => err = 'নতুন পিন কমপক্ষে ৪ অক্ষরের হতে হবে');
                  return;
                }
                if (np != confC.text.trim()) {
                  setD(() => err = 'নতুন পিন মিলছে না');
                  return;
                }
                data.managerPin = np;
                data.saveConfig();
                Navigator.pop(ctx);
                _snack('পিন বদলানো হয়েছে');
              },
              child: const Text('বদলান'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: data,
      builder: (context, _) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    const heading = TextStyle(
        fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal);

    return Scaffold(
      appBar: AppBar(
        title: const Text('সেটিংস (ম্যানেজার)'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('🏠 ম্যানেজারের রুম', style: heading),
          const SizedBox(height: 6),
          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.admin_panel_settings, color: Colors.teal),
              title: Text(data.managerRoom.isEmpty
                  ? 'রুম বেছে নিন'
                  : 'রুম ${data.managerRoom}'),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: _pickRoom,
            ),
          ),
          const Text(
            'শিক্ষার্থীরা দেখতে পাবে এখন কোন রুমের ভাইয়েরা ম্যানেজারির দায়িত্বে আছেন।',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 22),
          const Text('⏰ খাবারের সময়-সূচি', style: heading),
          const SizedBox(height: 4),
          const Text(
            'প্রতিটা বেলার শুরু ও শেষের সময়। বদলাতে সারিতে ট্যাপ করুন।',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 6),
          Card(
            child: Column(
              children: [
                _scheduleRow('b', 'সকাল'),
                const Divider(height: 1),
                _scheduleRow('l', 'দুপুর'),
                const Divider(height: 1),
                _scheduleRow('d', 'রাত'),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _resetSchedule,
              child: const Text('ডিফল্টে ফিরুন'),
            ),
          ),
          const SizedBox(height: 14),
          const Text('🍽️ খাবারের মূল্য তালিকা (প্রতি দিন)', style: heading),
          const SizedBox(height: 6),
          priceCard(),
          const SizedBox(height: 8),
          const Text(
            'মিলের একদিন শুরু হয় দুপুরে। পুরো দিন = ওই তারিখের দুপুর + রাত + পরদিন সকাল। আজ থেকে পরের ৪ দিনের যেকোনো বেলা চালু করা যাবে।',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 22),
          const Text('🔒 ম্যানেজার পিন', style: heading),
          const SizedBox(height: 4),
          const Text(
            'ম্যানেজার বদলালে নতুন পিন বসিয়ে নতুন ম্যানেজারকে দিন।',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 6),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock, color: Colors.teal),
              title: const Text('পিন পরিবর্তন করুন'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _changePin,
            ),
          ),
        ],
      ),
    );
  }
}
