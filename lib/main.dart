import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  'HSC 1st year',
  'HSC 2nd year',
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
    numOf(s['op']) + numOf(s['pd']) - numOf(s['pc']) - numOf(s['po']);

// শিক্ষার্থীর দেখানোর নম্বর (না থাকলে ডেটাবেসের আইডিই নম্বর)
int noOf(Map<String, dynamic> s) =>
    (s['no'] as num?)?.toInt() ?? (s['id'] as num).toInt();

// নতুন হিসাবে ফেরত যাবে এমন আগাম মিলের টাকা (যে বেলা খাওয়া হয়নি)
double advanceRefund(Map<String, dynamic> s) {
  final todayIso = isoOf(todayDate());
  final meals = mapOf(s['meals']);
  final eaten = mapOf(s['eaten']);
  double refund = 0;
  meals.forEach((k, v) {
    if (k.compareTo(todayIso) < 0 || v.isEmpty) return;
    final e = eaten[k] ?? '';
    final ate = v.split('').where((c) => e.contains(c)).join();
    refund += xPrice(xFlags(v)) - xPrice(xFlags(ate));
  });
  return refund;
}

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
  s['po'] = numOf(s['po']);
  s['slots'] = (s['slots'] as num?)?.toInt() ?? 0;
  s['history'] = (s['history'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ??
      <Map<String, dynamic>>[];
}

class AppData extends ChangeNotifier {
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> notices = [];
  List<Map<String, dynamic>> periods = []; // ম্যানেজারের মোট হিসাবের ইতিহাস
  List<Map<String, dynamic>> halls = []; // সব হলের তালিকা {id, name}
  List<Map<String, dynamic>> roster = []; // লগইনের জন্য শুধু নাম ও নম্বর
  Map<String, List<int>> schedule = copyDefaultSchedule();
  List<int> dd = List<int>.filled(15, 0); // চলমান হিসাবে দিনভিত্তিক জমা
  String? hallId;
  String hallName = '';
  String managerRoom = '';
  String periodStart = isoOf(todayDate());

  // ---- লগইন অবস্থা ----
  String role = ''; // 'manager' | 'student' | '' (ঢোকেনি)
  int studentId = 0;
  bool hallSecured = false; // এই হল নতুন নিরাপদ ব্যবস্থায় এসেছে কিনা
  String legacyPin = ''; // পুরোনো হলের ম্যানেজার পিন (একবার আপগ্রেডের জন্য)

  bool studentsLoaded = false;
  bool configLoaded = false;
  bool rosterLoaded = false;
  bool hallsLoaded = false;
  bool dark = false; // শুধু এই ফোনের পছন্দ
  String lastError = ''; // অনলাইন সংযোগের শেষ সমস্যা

  final List<StreamSubscription<dynamic>> _pub = [];
  final List<StreamSubscription<dynamic>> _priv = [];
  StreamSubscription<dynamic>? _hallsSub;

  void _err(Object e) {
    lastError = e.toString();
    notifyListeners();
  }

  FirebaseFirestore get _fs => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  String get uid => _auth.currentUser?.uid ?? '';

  DocumentReference<Map<String, dynamic>> get _hall =>
      _fs.collection('halls').doc(hallId);
  CollectionReference<Map<String, dynamic>> get _stuCol =>
      _hall.collection('students');
  DocumentReference<Map<String, dynamic>> get _sess =>
      _hall.collection('sessions').doc(uid);

  // ---- অদৃশ্য সাইন-ইন (Firebase Anonymous) ----
  Future<bool> ensureAuth() async {
    try {
      if (_auth.currentUser == null) await _auth.signInAnonymously();
      return true;
    } catch (e) {
      lastError =
          'নিরাপদ সংযোগ চালু করা যায়নি। Firebase-এ Anonymous সাইন-ইন চালু আছে কিনা দেখুন।\n$e';
      notifyListeners();
      return false;
    }
  }

  // ---- সব হলের তালিকা (হল বাছার স্ক্রিনের জন্য) ----
  void startHallList() {
    _hallsSub?.cancel();
    _hallsSub = _fs.collection('halls').snapshots().listen((snap) {
      halls = snap.docs
          .map((d) => <String, dynamic>{
                'id': d.id,
                'name': (d.data()['name'] ?? '').toString(),
              })
          .toList();
      halls.sort(
          (a, b) => a['name'].toString().compareTo(b['name'].toString()));
      hallsLoaded = true;
      notifyListeners();
    }, onError: _err);
  }

  // ---- হল বাছা / ছাড়া ----
  Future<void> selectHall(String id) async {
    await _stopHall();
    hallId = id;
    final p = await SharedPreferences.getInstance();
    await p.setString('hallId', id);
    _startPublic();
    await extra.startFor(id);
    notifyListeners();
  }

  Future<void> leaveHall() async {
    await _stopHall();
    hallId = null;
    final p = await SharedPreferences.getInstance();
    await p.remove('hallId');
    notifyListeners();
  }

  Future<void> _stopHall() async {
    await logout(notify: false);
    for (final s in _pub) {
      s.cancel();
    }
    _pub.clear();
    roster = [];
    rosterLoaded = false;
    configLoaded = false;
    hallName = '';
    managerRoom = '';
    hallSecured = false;
    legacyPin = '';
    periodStart = isoOf(todayDate());
    schedule = copyDefaultSchedule();
    dd = List<int>.filled(15, 0);
    lastError = '';
    extra.reset();
  }

  // সবার জন্য খোলা অংশ: হলের সেটিংস ও নামের তালিকা (পিন বা হিসাব নয়)
  void _startPublic() {
    _pub.add(_hall.snapshots().listen((doc) {
      if (!doc.exists) {
        if (!doc.metadata.isFromCache) leaveHall();
        return;
      }
      final m = doc.data() ?? {};
      hallName = (m['name'] ?? '').toString();
      managerRoom = (m['managerRoom'] ?? '').toString();
      periodStart = (m['periodStart'] ?? periodStart).toString();
      hallSecured = m['secured'] == true;
      legacyPin = (m['managerPin'] ?? '').toString();
      final sc = m['schedule'];
      if (sc is Map) {
        for (final k in ['b', 'l', 'd']) {
          final v = sc[k];
          if (v is List && v.length == 2) {
            schedule[k] = [(v[0] as num).toInt(), (v[1] as num).toInt()];
          }
        }
      }
      final d = m['dd'];
      if (d is List) {
        dd = List<int>.generate(
            15, (i) => i < d.length ? (d[i] as num).toInt() : 0);
      }
      configLoaded = true;
      lastError = '';
      notifyListeners();
    }, onError: _err));

    _pub.add(_hall.collection('roster').snapshots().listen((snap) {
      roster = snap.docs.map((d) => Map<String, dynamic>.from(d.data())).toList();
      if (!snap.metadata.isFromCache || roster.isNotEmpty) rosterLoaded = true;
      notifyListeners();
    }, onError: _err));
  }

  // লগইনের পর খোলা অংশ: ম্যানেজার সব দেখে, শিক্ষার্থী শুধু নিজেরটা
  void _startPrivate() {
    for (final s in _priv) {
      s.cancel();
    }
    _priv.clear();
    studentsLoaded = false;

    _priv.add(_hall
        .collection('notices')
        .orderBy('at')
        .snapshots()
        .listen((snap) {
      notices = snap.docs.map((d) {
        final m = Map<String, dynamic>.from(d.data());
        m['id'] = d.id;
        return m;
      }).toList();
      notifyListeners();
    }, onError: _err));

    if (role == 'manager') {
      _priv.add(_stuCol.snapshots().listen((snap) {
        final list = <Map<String, dynamic>>[];
        for (final d in snap.docs) {
          final s = Map<String, dynamic>.from(d.data());
          normalizeStudent(s);
          list.add(s);
        }
        list.sort((a, b) => noOf(a).compareTo(noOf(b)));
        students = list;
        if (!snap.metadata.isFromCache || list.isNotEmpty) {
          studentsLoaded = true;
          lastError = '';
        }
        notifyListeners();
      }, onError: _err));

      _priv.add(_hall
          .collection('periods')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snap) {
        periods = snap.docs.map((d) {
          final m = Map<String, dynamic>.from(d.data());
          m['id'] = d.id;
          return m;
        }).toList();
        notifyListeners();
      }, onError: _err));
    } else if (role == 'student') {
      _priv.add(_stuCol.doc('$studentId').snapshots().listen((doc) {
        if (doc.exists) {
          final s = Map<String, dynamic>.from(doc.data() ?? {});
          normalizeStudent(s);
          students = [s];
        } else {
          students = [];
        }
        studentsLoaded = true;
        lastError = '';
        notifyListeners();
      }, onError: _err));
    }
  }

  Future<bool> _waitPublic() async {
    final end = DateTime.now().add(const Duration(seconds: 15));
    while (DateTime.now().isBefore(end)) {
      if (rosterLoaded && configLoaded) return true;
      if (lastError.isNotEmpty) break;
      await Future.delayed(const Duration(milliseconds: 200));
    }
    return rosterLoaded && configLoaded;
  }

  String failMessage() {
    if (lastError.isNotEmpty) {
      return 'সংযোগে সমস্যা:\n$lastError';
    }
    return 'তথ্য আনা যায়নি। ইন্টারনেট চালু করে আবার চেষ্টা করুন';
  }

  Map<String, dynamic> _sessionData(String r, String sid, String pin) => {
        'role': r,
        'sid': sid,
        'pin': pin,
        'at': DateTime.now().toIso8601String(),
      };

  // ---- লগইন (পিন ঠিক কিনা, Firestore-এর নিয়মই যাচাই করে) ----
  Future<String?> loginStudent(String query, String pin) async {
    if (!await ensureAuth()) return failMessage();
    if (!await _waitPublic()) return failMessage();
    final q = normSearch(query);
    var found = roster
        .where((s) =>
            (s['no'] ?? s['id']).toString() == q ||
            normSearch(s['name'].toString()) == q)
        .toList();
    if (found.isEmpty) {
      found = roster
          .where((s) => normSearch(s['name'].toString()).contains(q))
          .toList();
    }
    if (found.isEmpty) return 'কোনো শিক্ষার্থী পাওয়া যায়নি';
    if (found.length > 1) return 'একাধিক নাম মিলেছে, পুরো নাম বা নম্বর লিখুন';
    if (!hallSecured) {
      return 'এই হলের ম্যানেজার এখনো নতুন অ্যাপে ঢোকেননি। ম্যানেজারকে একবার ঢুকতে বলুন';
    }
    final id = (found.first['id'] as num).toInt();
    try {
      await _sess.set(_sessionData('student', '$id', pin));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return 'পিন ভুল হয়েছে';
      return 'সংযোগে সমস্যা: ${e.message}';
    }
    role = 'student';
    studentId = id;
    _startPrivate();
    return null;
  }

  Future<String?> loginManager(String pin) async {
    if (!await ensureAuth()) return failMessage();
    if (!await _waitPublic()) return failMessage();
    try {
      await _sess.set(_sessionData('manager', '', pin));
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') return 'সংযোগে সমস্যা: ${e.message}';
      // পুরোনো (আপগ্রেড হয়নি এমন) হল: একবার নিজে থেকে নিরাপদ ব্যবস্থায় আনা
      if (!hallSecured && legacyPin.isNotEmpty && legacyPin == pin) {
        try {
          await _migrateHall(pin);
        } catch (err) {
          return 'আপগ্রেড করা যায়নি: $err';
        }
        role = 'manager';
        _startPrivate();
        return null;
      }
      return 'পিন ভুল হয়েছে';
    }
    role = 'manager';
    _startPrivate();
    return null;
  }

  Future<void> openAsManager() async {
    role = 'manager';
    _startPrivate();
    notifyListeners();
  }

  Future<void> logout({bool notify = true}) async {
    if (role.isNotEmpty && hallId != null) {
      try {
        await _sess.delete();
      } catch (_) {}
    }
    for (final s in _priv) {
      s.cancel();
    }
    _priv.clear();
    role = '';
    studentId = 0;
    students = [];
    notices = [];
    periods = [];
    studentsLoaded = false;
    if (notify) notifyListeners();
  }

  // বর্তমান পিন ঠিক আছে কিনা (পিন বদলানোর আগে)
  Future<bool> verifyPin(String pin) async {
    try {
      await _sess.set(_sessionData(role, role == 'student' ? '$studentId' : '', pin));
      return true;
    } on FirebaseException {
      return false;
    }
  }

  // নিজের পিন বদলানো (ম্যানেজার বা শিক্ষার্থী)
  Future<void> changeOwnPin(String newPin) async {
    final id = role == 'student' ? '$studentId' : 'manager';
    await _hall.collection('secrets').doc(id).set({'pin': newPin});
  }

  // ম্যানেজার শিক্ষার্থীর পিন নতুন করে বসান
  Future<void> resetStudentPin(int id, String newPin) async {
    await _hall.collection('secrets').doc('$id').set({'pin': newPin});
  }

  // ---- পুরোনো হলকে নিরাপদ ব্যবস্থায় আনা (একবার) ----
  Future<void> _migrateHall(String pin) async {
    final sec = _hall.collection('secrets');
    await sec.doc('manager').set({'pin': pin});
    await _sess.set(_sessionData('manager', '', pin));
    role = 'manager';

    final snap = await _stuCol.get();
    WriteBatch b = _fs.batch();
    int n = 0;
    for (final d in snap.docs) {
      final m = d.data();
      final p = (m['pin'] ?? '1234').toString();
      b.set(sec.doc(d.id), {'pin': p});
      b.set(_hall.collection('roster').doc(d.id),
          {'id': m['id'], 'no': m['no'] ?? m['id'], 'name': m['name']});
      if (m.containsKey('pin')) {
        b.update(d.reference, {'pin': FieldValue.delete()});
      }
      n += 3;
      if (n >= 400) {
        await b.commit();
        b = _fs.batch();
        n = 0;
      }
    }
    await b.commit();
    await _hall.set({
      'managerPin': FieldValue.delete(),
      'secured': true,
    }, SetOptions(merge: true));
  }

  // ---- নতুন হল তৈরি ----
  Future<bool> legacyExists() async {
    try {
      final d = await _fs.collection('config').doc('app').get();
      return d.exists;
    } catch (_) {
      return false;
    }
  }

  Future<String?> createHall(String name, String pin,
      {bool importLegacy = false}) async {
    try {
      if (!await ensureAuth()) return null;
      final ref = _fs.collection('halls').doc();
      await ref.set({
        'name': name,
        'creator': uid,
        'secured': true,
        'managerRoom': '',
        'periodStart': isoOf(todayDate()),
        'schedule': kDefaultSchedule,
        'dd': List<int>.filled(15, 0),
        'prices': ExtraData.kDefaultPrices,
        'periodDays': 4,
        'mealOpen': false,
        'openAt': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });
      await ref.collection('secrets').doc('manager').set({'pin': pin});
      await ref
          .collection('sessions')
          .doc(uid)
          .set(_sessionData('manager', '', pin));
      if (importLegacy) await _importLegacy(ref);
      return ref.id;
    } catch (e) {
      _err(e);
      return null;
    }
  }

  // আগের (হল-ছাড়া) ডেটা নতুন হলে কপি করা
  Future<void> _importLegacy(DocumentReference<Map<String, dynamic>> ref) async {
    final cfg = await _fs.collection('config').doc('app').get();
    final ex = await _fs.collection('config').doc('extra').get();
    final upd = <String, dynamic>{};
    final c = cfg.data() ?? {};
    for (final k in ['managerRoom', 'periodStart', 'schedule']) {
      if (c[k] != null) upd[k] = c[k];
    }
    final e = ex.data() ?? {};
    for (final k in ['prices', 'periodDays']) {
      if (e[k] != null) upd[k] = e[k];
    }
    if (upd.isNotEmpty) await ref.set(upd, SetOptions(merge: true));

    WriteBatch b = _fs.batch();
    int n = 0;
    Future<void> tick() async {
      n++;
      if (n % 150 == 0) {
        await b.commit();
        b = _fs.batch();
      }
    }

    for (final d in (await _fs.collection('students').get()).docs) {
      final m = Map<String, dynamic>.from(d.data());
      final p = (m.remove('pin') ?? '1234').toString();
      b.set(ref.collection('students').doc(d.id), m);
      b.set(ref.collection('roster').doc(d.id),
          {'id': m['id'], 'no': m['no'] ?? m['id'], 'name': m['name']});
      b.set(ref.collection('secrets').doc(d.id), {'pin': p});
      await tick();
    }
    for (final d in (await _fs.collection('notices').get()).docs) {
      b.set(ref.collection('notices').doc(d.id), d.data());
      await tick();
    }
    await b.commit();
  }

  // ---- লেখা (অনলাইনে না থাকলেও ফোনে জমে থাকে, নেট এলে সিঙ্ক হয়) ----
  void saveStudent(Map<String, dynamic> s) {
    notifyListeners();
    final doc = _stuCol.doc('${s['id']}');
    if (role == 'student') {
      // শিক্ষার্থী শুধু নিজের মিল, খরচ ও ইতিহাস বদলাতে পারে
      doc.update({
        'meals': s['meals'],
        'pc': s['pc'],
        'slots': s['slots'],
        'history': s['history'],
      }).catchError(_err);
    } else {
      doc.set(s).catchError(_err);
    }
  }

  // নতুন শিক্ষার্থী: তথ্য + নামের তালিকা + প্রথম পিন (১২৩৪)
  void addStudent(Map<String, dynamic> s, {String pin = '1234'}) {
    final id = '${s['id']}';
    final b = _fs.batch();
    b.set(_stuCol.doc(id), s);
    b.set(_hall.collection('roster').doc(id),
        {'id': s['id'], 'no': s['no'] ?? s['id'], 'name': s['name']});
    b.set(_hall.collection('secrets').doc(id), {'pin': pin});
    b.commit().catchError(_err);
    notifyListeners();
  }

  void deleteStudent(Map<String, dynamic> s) {
    final id = '${s['id']}';
    students.remove(s);
    notifyListeners();
    final b = _fs.batch();
    b.delete(_stuCol.doc(id));
    b.delete(_hall.collection('roster').doc(id));
    b.delete(_hall.collection('secrets').doc(id));
    b.commit().catchError(_err);
  }

  // নাম ও দেখানোর নম্বর বদলানো (ডেটাবেসের আইডি একই থাকে, তাই পিন ও হিসাব ঠিক থাকে)
  void renameStudent(Map<String, dynamic> s, String name, int no) {
    final id = '${s['id']}';
    s['name'] = name;
    s['no'] = no;
    notifyListeners();
    final b = _fs.batch();
    b.update(_stuCol.doc(id), {'name': name, 'no': no});
    b.set(_hall.collection('roster').doc(id),
        {'id': s['id'], 'no': no, 'name': name});
    b.commit().catchError(_err);
  }

  // পাওনা মেটানো: শিক্ষার্থীকে টাকা ফেরত দেওয়ার পর হিসাব থেকে বাদ
  void payOut(Map<String, dynamic> s, double amount) {
    s['po'] = numOf(s['po']) + amount;
    saveStudent(s);
  }

  void saveConfig() {
    notifyListeners();
    _hall.set({
      'managerRoom': managerRoom,
      'periodStart': periodStart,
      'schedule': schedule,
    }, SetOptions(merge: true)).catchError(_err);
  }

  void addNotice(String text) {
    _hall.collection('notices').add({
      'text': text,
      'at': DateTime.now().toIso8601String(),
    }).then<void>((_) {}).catchError(_err);
  }

  void deleteNotice(String id) {
    _hall.collection('notices').doc(id).delete().catchError(_err);
  }

  // ---- জমা (চলমান হিসাবের দিনভিত্তিক জমাও লেখা হয়) ----
  void bumpDeposit(double amount) {
    final idx = periodInfo().dn - 1;
    if (idx < 0 || idx >= dd.length) return;
    dd[idx] = dd[idx] + amount.round();
    _hall.set({'dd': dd}, SetOptions(merge: true)).catchError(_err);
  }

  void addDeposit(Map<String, dynamic> s, double amount) {
    s['pd'] = numOf(s['pd']) + amount;
    bumpDeposit(amount);
    saveStudent(s);
  }

  // ---- শিক্ষার্থীর নিজের ইতিহাস ----
  void deleteHistory(Map<String, dynamic> s, int index) {
    final h = (s['history'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    if (index < 0 || index >= h.length) return;
    h.removeAt(index);
    s['history'] = h;
    saveStudent(s);
  }

  void clearHistory(Map<String, dynamic> s) {
    s['history'] = <Map<String, dynamic>>[];
    saveStudent(s);
  }

  // ---- ম্যানেজারের মোট হিসাবের ইতিহাস ----
  void deletePeriod(String id) {
    _hall.collection('periods').doc(id).delete().catchError(_err);
  }

  void clearPeriods() {
    final batch = _fs.batch();
    for (final p in periods) {
      batch.delete(_hall.collection('periods').doc(p['id'].toString()));
    }
    batch.commit().catchError(_err);
  }

  // নতুন হিসাব: মিল, মিলের খরচ ও ব্যালেন্স সব ৳০ থেকে শুরু।
  // চলমান হিসাব ইতিহাসে জমা হয় (শিক্ষার্থীর নিজের + ম্যানেজারের মোট হিসাব)।
  void commitPeriod() {
    final todayIso = isoOf(todayDate());
    final fromIso = periodStart;
    final days = extra.periodDays;
    final batch = _fs.batch();
    int stuCount = 0;
    int slotTotal = 0;
    double depTotal = 0;
    double costTotal = 0;
    double poTotal = 0;

    for (final s in students) {
      final meals = mapOf(s['meals']);
      final eaten = mapOf(s['eaten']);
      // আজ বা পরের দিনের যে বেলা খাওয়া হয়নি, তার টাকা ফেরত
      double refund = 0;
      int unused = 0;
      meals.forEach((k, v) {
        if (k.compareTo(todayIso) < 0 || v.isEmpty) return;
        final e = eaten[k] ?? '';
        final ate = v.split('').where((c) => e.contains(c)).join();
        refund += xPrice(xFlags(v)) - xPrice(xFlags(ate));
        unused += v.length - ate.length;
      });
      final pc = numOf(s['pc']) - refund;
      final cl = numOf(s['op']) + numOf(s['pd']) - pc - numOf(s['po']);
      int slots = (s['slots'] as num?)?.toInt() ?? 0;
      if (slots > 0) stuCount++;
      slots = slots - unused;
      if (slots < 0) slots = 0;

      final hist = (s['history'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      hist.add({
        'from': fromIso,
        'to': todayIso,
        'op': numOf(s['op']),
        'pd': numOf(s['pd']),
        'pc': pc,
        'po': numOf(s['po']),
        'cl': cl,
        'slots': slots,
        'ate': countEaten(s, fromIso, todayIso),
      });

      depTotal += numOf(s['pd']);
      costTotal += pc;
      poTotal += numOf(s['po']);
      slotTotal += slots;

      s['history'] = hist;
      s['op'] = 0.0;
      s['pd'] = 0.0;
      s['pc'] = 0.0;
      s['po'] = 0.0;
      s['slots'] = 0;
      s['meals'] = <String, String>{};
      s['eaten'] = <String, String>{};
      batch.set(_stuCol.doc('${s['id']}'), s);
    }

    batch.set(_hall.collection('periods').doc(), {
      'from': fromIso,
      'to': todayIso,
      'days': days,
      'students': stuCount,
      'slots': slotTotal,
      'deposit': depTotal,
      'cost': costTotal,
      'po': poTotal,
      'dd': dd.sublist(0, days),
      'createdAt': DateTime.now().toIso8601String(),
    });
    dd = List<int>.filled(15, 0);
    periodStart = todayIso;
    batch.set(_hall, {'periodStart': todayIso, 'dd': dd},
        SetOptions(merge: true));
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

Widget accountRows(double op, double pd, double pc, double cl,
    {double po = 0}) {
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
      if (po > 0) row('ফেরত দেওয়া', '−${money(po)}'),
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
  await data.ensureAuth();
  data.startHallList();
  final saved = prefs.getString('hallId');
  if (saved != null) await data.selectHall(saved);
  runApp(OssimApp(
    home: saved != null ? const LoginScreen2() : const HallPickerScreen(),
  ));
}

class OssimApp extends StatelessWidget {
  final Widget home;
  const OssimApp({super.key, required this.home});

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
        home: home,
      ),
    );
  }
}

// লগইন স্ক্রিন (শিক্ষার্থী / ম্যানেজার) এখন extras.dart-এর LoginScreen2

void goLogin(BuildContext context) {
  data.logout();
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen2()),
    (r) => false,
  );
}

// সব স্ক্রিন এখন screens.dart-এ
