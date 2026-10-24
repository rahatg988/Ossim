// ---------------------------------------------------------------
// extras.dart  (lib/extras.dart নামে নতুন ফাইল)
// নতুন সুবিধা:
//  1. ম্যানেজারের অনুমতি দিলে শিক্ষার্থীরা নিজেরা মিল চালু করতে পারবে
//  2. অনুমতি চালু করলে সবার অ্যাপে নোটিফিকেশন + একবার ভাইব্রেশন
//  3. শিক্ষার্থীর নিজের পিন (লগইন + পিন পরিবর্তন)
//  4. "খাবার চিহ্নিত করুন" স্ক্রিনে নাম/নম্বর দিয়ে সার্চ
//  5. কতজন মিল চালু করেছে, ম্যানেজার দেখতে পারবে
// ---------------------------------------------------------------
import 'dart:async';

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

  StreamSubscription<dynamic>? _sub;
  String? _hid;

  // এই হলের ডকুমেন্ট: halls/{hallId}
  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.collection('halls').doc(_hid);

  void reset() {
    _sub?.cancel();
    _sub = null;
    _hid = null;
    mealOpen = false;
    openAt = 0;
    seenOpenAt = 0;
    prices = Map<String, int>.from(kDefaultPrices);
    periodDays = 4;
  }

  Future<void> startFor(String hallId) async {
    reset();
    _hid = hallId;
    final p = await SharedPreferences.getInstance();
    seenOpenAt = p.getInt('seenOpenAt_$hallId') ?? 0;
    _sub = _doc.snapshots().listen((d) {
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
      if (pdv != null && pdv >= 1 && pdv <= 15) periodDays = pdv;
      // নতুন অনুমতি এলে একবার ভাইব্রেট + বার্তা (ম্যানেজারের ফোনে নয়)
      if (mealOpen && openAt > seenOpenAt) {
        seenOpenAt = openAt;
        SharedPreferences.getInstance()
            .then((p) => p.setInt('seenOpenAt_$hallId', openAt));
        if (!isManager) {
          HapticFeedback.vibrate();
          messengerKey.currentState?.showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 6),
              content: Text(
                  '📢 ম্যানেজার মিল চালুর অনুমতি দিয়েছেন। এখন নিজের মিল চালু বা বন্ধ করতে পারবেন।'),
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
    periodDays = n < 1 ? 1 : (n > 15 ? 15 : n);
    notifyListeners();
    _doc
        .set({'periodDays': periodDays}, SetOptions(merge: true))
        .catchError((e) {});
  }

  void setOpen(bool v) {
    mealOpen = v;
    if (v) {
      openAt = DateTime.now().millisecondsSinceEpoch;
      seenOpenAt = openAt;
      SharedPreferences.getInstance()
          .then((p) => p.setInt('seenOpenAt_$_hid', openAt));
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
  final eaten = mapOf(student['eaten']);
  final today = todayDate();
  final dates = List.generate(kMealDays, (i) => addDays(today, i));
  final orig = dates.map((d) => xFlags(meals[isoOf(d)])).toList();
  // যে বেলা খাওয়া হয়ে গেছে, তা বদলানো যাবে না
  final ate = dates.map((d) => xFlags(eaten[isoOf(d)])).toList();
  final sel = orig.map((f) => List<bool>.from(f)).toList();

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        int net = 0;
        int slotDelta = 0;
        bool changed = false;
        for (int i = 0; i < kMealDays; i++) {
          net += xPrice(sel[i]) - xPrice(orig[i]);
          for (int j = 0; j < 3; j++) {
            if (sel[i][j] != orig[i][j]) {
              changed = true;
              slotDelta += sel[i][j] ? 1 : -1;
            }
          }
        }

        return AlertDialog(
          title: Text(self ? 'আমার মিল' : '${student['name']} - মিল'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  self
                      ? 'অনুমতির সময়ে মিল চালু ও বন্ধ দুটোই করতে পারবেন। মিলের একদিন = দুপুর + রাত + পরদিন সকাল।'
                      : 'যেকোনো সময় চালু বা বন্ধ করা যাবে। মিলের একদিন = দুপুর + রাত + পরদিন সকাল। খাওয়া হয়ে যাওয়া বেলা বদলানো যাবে না।',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setDialogState(() {
                        for (int i = 0; i < kMealDays; i++) {
                          for (int j = 0; j < 3; j++) {
                            if (!ate[i][j]) sel[i][j] = true;
                          }
                        }
                      }),
                      child: const Text('সব চালু'),
                    ),
                    TextButton(
                      onPressed: () => setDialogState(() {
                        for (int i = 0; i < kMealDays; i++) {
                          for (int j = 0; j < 3; j++) {
                            if (!ate[i][j]) sel[i][j] = false;
                          }
                        }
                      }),
                      child: const Text('সব বন্ধ'),
                    ),
                  ],
                ),
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
                        Text(dateLabel(dates[i]),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
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
                                onSelected: ate[i][j]
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
                Text(
                  net > 0
                      ? 'নতুন যোগ: ৳ ${bnDigits('$net')}'
                      : (net < 0
                          ? 'ফেরত যাবে: ৳ ${bnDigits('${-net}')}'
                          : 'কোনো পরিবর্তন নেই'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: net < 0 ? Colors.green : null,
                  ),
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
              onPressed: !changed
                  ? null
                  : () {
                      // শিক্ষার্থী শুধু অনুমতি থাকলেই বদলাতে পারবে
                      if (self && !extra.mealOpen) {
                        Navigator.pop(ctx);
                        messengerKey.currentState?.showSnackBar(const SnackBar(
                            content: Text('এখন মিল বদলানোর অনুমতি বন্ধ আছে')));
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
                      student['pc'] = numOf(student['pc']) + net;
                      int slots =
                          ((student['slots'] as num?)?.toInt() ?? 0) +
                              slotDelta;
                      if (slots < 0) slots = 0;
                      student['slots'] = slots;
                      student['meals'] = updated;
                      data.saveStudent(student);
                      Navigator.pop(ctx);
                    },
              child: const Text('সেভ করুন'),
            ),
          ],
        );
      },
    ),
  );
}

// ---------------------------------------------------------------
// শিক্ষার্থীর পিন পরিবর্তন
// ---------------------------------------------------------------
void showStudentPinDialog(BuildContext context, Map<String, dynamic> s) {
  showOwnPinDialog(context, 'পিন পরিবর্তন');
}

// নিজের পিন বদলানো (শিক্ষার্থী বা ম্যানেজার, দুজনের জন্যই)
void showOwnPinDialog(BuildContext context, String title) {
  final curC = TextEditingController();
  final newC = TextEditingController();
  final confC = TextEditingController();
  String err = '';
  bool busy = false;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: Text(title),
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
            onPressed: busy ? null : () => Navigator.pop(ctx),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: busy
                ? null
                : () async {
                    final np = newC.text.trim();
                    if (np.length < 4) {
                      setD(() => err = 'নতুন পিন কমপক্ষে ৪ অক্ষরের হতে হবে');
                      return;
                    }
                    if (np != confC.text.trim()) {
                      setD(() => err = 'নতুন পিন মিলছে না');
                      return;
                    }
                    setD(() {
                      busy = true;
                      err = '';
                    });
                    final ok = await data.verifyPin(curC.text.trim());
                    if (!ok) {
                      setD(() {
                        busy = false;
                        err = 'বর্তমান পিন ভুল';
                      });
                      return;
                    }
                    try {
                      await data.changeOwnPin(np);
                    } catch (_) {
                      setD(() {
                        busy = false;
                        err = 'পিন বদলানো যায়নি, আবার চেষ্টা করুন';
                      });
                      return;
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    messengerKey.currentState?.showSnackBar(
                        const SnackBar(content: Text('পিন বদলানো হয়েছে')));
                  },
            child: busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('বদলান'),
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
    if (idC.text.trim().isEmpty) {
      setState(() => error = 'নাম বা নম্বর লিখুন');
      return;
    }
    if (spC.text.trim().isEmpty) {
      setState(() => error = 'পিন লিখুন');
      return;
    }
    setState(() {
      busy = true;
      error = '';
    });
    final err = await data.loginStudent(idC.text, spC.text.trim());
    if (!mounted) return;
    setState(() => busy = false);
    if (err != null) {
      setState(() => error = err);
      return;
    }
    extra.isManager = false;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => StudentScreen(studentId: data.studentId),
      ),
    );
  }

  Future<void> _managerLogin() async {
    if (pinC.text.trim().isEmpty) {
      setState(() => error = 'পিন লিখুন');
      return;
    }
    setState(() {
      busy = true;
      error = '';
    });
    final err = await data.loginManager(pinC.text.trim());
    if (!mounted) return;
    setState(() => busy = false);
    if (err != null) {
      setState(() => error = err);
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
    return ListenableBuilder(
      listenable: data,
      builder: (context, _) {
        if (data.hallId == null) return const HallPickerScreen();
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
                  const SizedBox(height: 14),
                  InkWell(
                    borderRadius: BorderRadius.circular(99),
                    onTap: () => leaveToPicker(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: tintC(context),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.apartment, size: 16, color: priC(context)),
                          const SizedBox(width: 6),
                          Text(data.hallName.isEmpty ? 'হল' : data.hallName,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: priC(context))),
                          const SizedBox(width: 6),
                          Text('· বদলান',
                              style: TextStyle(
                                  fontSize: 12, color: mutC(context))),
                        ],
                      ),
                    ),
                  ),
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
      },
    );
  }
}
