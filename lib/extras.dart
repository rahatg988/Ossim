// ---------------------------------------------------------------
// extras.dart  (lib/extras.dart নামে নতুন ফাইল)
// নতুন সুবিধা:
//  1. ম্যানেজারের অনুমতি দিলে শিক্ষার্থীরা নিজেরা মিল চালু করতে পারবে
//  2. অনুমতি চালু করলে সবার অ্যাপে নোটিফিকেশন + একবার ভাইব্রেশন
//  3. শিক্ষার্থীর নিজের পিন (লগইন + পিন পরিবর্তন)
//  4. "খাবার চিহ্নিত করুন" স্ক্রিনে নাম/নম্বর দিয়ে সার্চ
//  5. কতজন মিল চালু করেছে, ম্যানেজার দেখতে পারবে
// ---------------------------------------------------------------
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';
import 'screens.dart';

final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

// ---------------------------------------------------------------
// মিল চালুর অনুমতি (Firestore: config/extra)
// ---------------------------------------------------------------
class ExtraData extends ChangeNotifier {
  bool mealOpen = false;
  int openAt = 0; // অনুমতি দেওয়ার সময় (millisecondsSinceEpoch)
  int seenOpenAt = 0; // এই ফোন যেটা শেষ দেখেছে
  bool isManager = false;

  // খাবারের মূল্য তালিকা (ম্যানেজার বদলাতে পারবে) ও হিসাবের মেয়াদ
  static const Map<String, int> kDefaultPrices = {
    'b': 15,
    'l': 35,
    'd': 30,
    'bl': 50,
    'bd': 45,
    'ld': 60,
    'bld': 70,
  };
  static const List<List<String>> kPriceNames = [
    ['b', 'শুধু সকাল'],
    ['l', 'শুধু দুপুর'],
    ['d', 'শুধু রাত'],
    ['ld', 'দুপুর + রাত'],
    ['bl', 'সকাল + দুপুর'],
    ['bd', 'সকাল + রাত'],
    ['bld', 'সকাল + দুপুর + রাত (পুরো দিন)'],
  ];
  Map<String, int> prices = Map<String, int>.from(kDefaultPrices);
  int periodDays = 4;

  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.collection('config').doc('extra');

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    seenOpenAt = p.getInt('seenOpenAt') ?? 0;
  }

  void start() {
    _doc.snapshots().listen((d) {
      final m = d.data() ?? <String, dynamic>{};
      mealOpen = m['mealOpen'] == true;
      openAt = (m['openAt'] as num?)?.toInt() ?? 0;
      final pr = m['prices'];
      if (pr is Map) {
        for (final k in kDefaultPrices.keys) {
          final v = pr[k];
          if (v is num) prices[k] = v.toInt();
        }
      }
      final pdv = (m['periodDays'] as num?)?.toInt();
      if (pdv != null && pdv >= 1 && pdv <= 7) periodDays = pdv;
      // নতুন অনুমতি এলে একবার ভাইব্রেট + বার্তা (ম্যানেজারের ফোনে নয়)
      if (mealOpen && openAt > seenOpenAt) {
        seenOpenAt = openAt;
        SharedPreferences.getInstance()
            .then((p) => p.setInt('seenOpenAt', openAt));
        if (!isManager) {
          HapticFeedback.vibrate();
          messengerKey.currentState?.showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 6),
              content: Text(
                  '📢 ম্যানেজার মিল চালুর অনুমতি দিয়েছেন। এখন নিজের মিল চালু করতে পারবেন।'),
            ),
          );
        }
      }
      notifyListeners();
    }, onError: (e) {});
  }

  void setPrice(String k, int v) {
    prices[k] = v;
    notifyListeners();
    _doc
        .set({'prices': prices}, SetOptions(merge: true))
        .catchError((e) {});
  }

  void resetPrices() {
    prices = Map<String, int>.from(kDefaultPrices);
    notifyListeners();
    _doc
        .set({'prices': prices}, SetOptions(merge: true))
        .catchError((e) {});
  }

  void setPeriodDays(int n) {
    periodDays = n;
    notifyListeners();
    _doc
        .set({'periodDays': n}, SetOptions(merge: true))
        .catchError((e) {});
  }

  void setOpen(bool v) {
    mealOpen = v;
    if (v) {
      openAt = DateTime.now().millisecondsSinceEpoch;
      seenOpenAt = openAt;
      SharedPreferences.getInstance()
          .then((p) => p.setInt('seenOpenAt', openAt));
      data.addNotice(
          'ম্যানেজার মিল চালুর অনুমতি দিয়েছেন। এখন আপনি নিজের মিল চালু করতে পারবেন।');
      HapticFeedback.vibrate();
    }
    notifyListeners();
    _doc
        .set({'mealOpen': v, 'openAt': openAt}, SetOptions(merge: true))
        .catchError((e) {});
  }
}

final ExtraData extra = ExtraData();

// ---------------------------------------------------------------
// মিল চালুর ডায়ালগ (ম্যানেজার ও শিক্ষার্থী দুজনেই ব্যবহার করবে)
// ---------------------------------------------------------------
int get kMealDays => extra.periodDays;

int xPrice(List<bool> f) {
  // f = [দুপুর, রাত, সকাল]
  final key = (f[2] ? 'b' : '') + (f[0] ? 'l' : '') + (f[1] ? 'd' : '');
  if (key.isEmpty) return 0;
  return extra.prices[key] ?? 0;
}

List<bool> xFlags(String? v) {
  final s = v ?? '';
  return [s.contains('l'), s.contains('d'), s.contains('b')];
}

String xStr(List<bool> f) {
  var r = '';
  if (f[0]) r += 'l';
  if (f[1]) r += 'd';
  if (f[2]) r += 'b';
  return r;
}

void showMealDialog(BuildContext context, Map<String, dynamic> student,
    {bool self = false}) {
  final meals = mapOf(student['meals']);
  final today = todayDate();
  final dates = List.generate(kMealDays, (i) => addDays(today, i));
  final locked = dates.map((d) => xFlags(meals[isoOf(d)])).toList();
  final sel = locked.map((f) => List<bool>.from(f)).toList();

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        int total = 0;
        int newSlots = 0;
        for (int i = 0; i < kMealDays; i++) {
          total += xPrice(sel[i]) - xPrice(locked[i]);
          for (int j = 0; j < 3; j++) {
            if (sel[i][j] && !locked[i][j]) newSlots++;
          }
        }

        return AlertDialog(
          title: Text(self
              ? 'আমার মিল চালু করুন'
              : '${student['name']} - মিল চালু করুন'),
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
                for (int i = 0; i < kMealDays; i++)
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
                              child: const Text('পুরো দিন',
                                  style: TextStyle(
                                      color: Colors.teal, fontSize: 13)),
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
                                    : (v) =>
                                        setDialogState(() => sel[i][j] = v),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Text('নতুন যোগ: ৳ ${bnDigits('$total')}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
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
                // শিক্ষার্থী শুধু অনুমতি থাকলেই মিল চালু করতে পারবে
                if (self && !extra.mealOpen) {
                  Navigator.pop(ctx);
                  messengerKey.currentState?.showSnackBar(const SnackBar(
                      content: Text('এখন মিল চালুর অনুমতি বন্ধ আছে')));
                  return;
                }
                final updated = Map<String, String>.from(meals);
                for (int i = 0; i < kMealDays; i++) {
                  final str = xStr(sel[i]);
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

void showStudentPinDialog(BuildContext context, Map<String, dynamic> s) {
  final curC = TextEditingController();
  final newC = TextEditingController();
  final confC = TextEditingController();
  String err = '';

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: const Text('পিন পরিবর্তন'),
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
                      style: const TextStyle(color: Colors.red, fontSize: 12)),
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
              final cur = (s['pin'] ?? '1234').toString();
              if (curC.text.trim() != cur) {
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
              s['pin'] = np;
              data.saveStudent(s);
              Navigator.pop(ctx);
              messengerKey.currentState?.showSnackBar(
                  const SnackBar(content: Text('পিন বদলানো হয়েছে')));
            },
            child: const Text('বদলান'),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------
// লগইন (শিক্ষার্থীর জন্য পিনসহ)
// ---------------------------------------------------------------
class LoginScreen2 extends StatefulWidget {
  const LoginScreen2({super.key});

  @override
  State<LoginScreen2> createState() => _LoginScreen2State();
}

class _LoginScreen2State extends State<LoginScreen2> {
  bool manager = false;
  bool busy = false;
  final TextEditingController idC = TextEditingController();
  final TextEditingController spC = TextEditingController();
  final TextEditingController pinC = TextEditingController();
  String error = '';

  @override
  void initState() {
    super.initState();
    extra.isManager = false;
  }

  @override
  void dispose() {
    idC.dispose();
    spC.dispose();
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
    final st = found.first;
    if (spC.text.trim() != (st['pin'] ?? '1234').toString()) {
      setState(() => error = 'পিন ভুল হয়েছে');
      return;
    }
    extra.isManager = false;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => StudentScreen(studentId: st['id'] as int),
      ),
    );
  }

  Future<void> _managerLogin() async {
    setState(() {
      busy = true;
      error = '';
    });
    final ok = await data.ensureLoaded(needStudents: false, needConfig: true);
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
    extra.isManager = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgC(context),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                        color: K.priDark, shape: BoxShape.circle),
                    child: const Icon(Icons.rice_bowl,
                        size: 42, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text('Ossim',
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: inkC(context))),
                  Text('হোস্টেল মিলের হিসাব, এক জায়গায়',
                      style: TextStyle(color: mutC(context))),
                  const SizedBox(height: 28),
                  segControl(
                    context,
                    const ['শিক্ষার্থী', 'ম্যানেজার'],
                    manager ? 1 : 0,
                    (i) => setState(() {
                      manager = i == 1;
                      error = '';
                    }),
                  ),
                  const SizedBox(height: 8),
                  if (!manager) ...[
                    TextField(
                      controller: idC,
                      decoration: inputDeco(
                          context, 'আপনার নাম বা নম্বর', Icons.person_outline),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: spC,
                      obscureText: true,
                      decoration:
                          inputDeco(context, 'আপনার পিন', Icons.lock_outline),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'প্রথমবার পিন ১২৩৪। ঢুকে নিজের পিন বদলে নিন।',
                        style: TextStyle(fontSize: 12, color: mutC(context)),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: pinC,
                      obscureText: true,
                      decoration: inputDeco(
                          context, 'ম্যানেজার পিন', Icons.lock_outline),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'প্রথমবার ডিফল্ট পিন ১২৩৪। ঢুকে সেটিংস থেকে বদলে নিন।',
                        style: TextStyle(fontSize: 12, color: mutC(context)),
                      ),
                    ),
                  ],
                  if (error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(error,
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: badC(context), fontSize: 13)),
                    ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: K.pri,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed:
                          busy ? null : (manager ? _managerLogin : _studentLogin),
                      child: busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              manager ? 'ম্যানেজার হিসেবে ঢুকুন' : 'প্রবেশ করুন',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
