import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'extras.dart';
import 'screens.dart';

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

// হিসাবের মেয়াদ (দিন): ম্যানেজার সেটিংস থেকে ২, ৩ বা ৪ করতে পারে
int get kPeriodDays => extra.periodDays;

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

  // নতুন হিসাব: চলমান হিসাব ইতিহাসে জমা হয়
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
// (মূল্য তালিকা priceCard() এখন extras.dart-এ)
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
  await extra.init();
  extra.start();
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
        scaffoldMessengerKey: messengerKey,
        title: 'Ossim',
        themeMode: data.dark ? ThemeMode.dark : ThemeMode.light,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: K.pri, brightness: Brightness.light),
          scaffoldBackgroundColor: const Color(0xFFF3F6F5),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: K.pri, brightness: Brightness.dark),
          scaffoldBackgroundColor: const Color(0xFF0C1513),
        ),
        home: const LoginScreen2(),
      ),
    );
  }
}

// লগইন স্ক্রিন (শিক্ষার্থী / ম্যানেজার) এখন extras.dart-এর LoginScreen2

void goLogin(BuildContext context) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen2()),
    (r) => false,
  );
}

// সব স্ক্রিন এখন screens.dart-এ
