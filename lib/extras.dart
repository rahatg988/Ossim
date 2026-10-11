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
// ম্যানেজারের কার্ড: অনুমতির সুইচ + কতজন মিল চালু করেছে
// ---------------------------------------------------------------
Widget mealPermCard() {
  return ListenableBuilder(
    listenable: Listenable.merge([extra, data]),
    builder: (context, _) {
      final total = data.students.length;
      final on = data.students.where((s) => activeLines(s).isNotEmpty).length;
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('শিক্ষার্থীদের মিল চালুর অনুমতি',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                extra.mealOpen
                    ? 'চালু: শিক্ষার্থীরা এখন নিজের মিল চালু করতে পারবে'
                    : 'বন্ধ: শিক্ষার্থীরা নিজে মিল চালু করতে পারবে না',
                style: const TextStyle(fontSize: 12),
              ),
              value: extra.mealOpen,
              onChanged: (v) {
                extra.setOpen(v);
                if (v) {
                  messengerKey.currentState?.showSnackBar(const SnackBar(
                      content: Text('সবাইকে নোটিফিকেশন পাঠানো হয়েছে')));
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('মিল চালু করেছে'),
                  Text('${bnDigits('$on')} জন / মোট ${bnDigits('$total')} জন',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

// ---------------------------------------------------------------
// মিল চালুর ডায়ালগ (ম্যানেজার ও শিক্ষার্থী দুজনেই ব্যবহার করবে)
// ---------------------------------------------------------------
const int kMealDays = 4;

int xPrice(List<bool> f) {
  // f = [দুপুর, রাত, সকাল]
  final l = f[0], d = f[1], b = f[2];
  if (b && l && d) return 70;
  if (b && l) return 50;
  if (b && d) return 45;
  if (l && d) return 60;
  if (b) return 15;
  if (l) return 35;
  if (d) return 30;
  return 0;
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

// ---------------------------------------------------------------
// শিক্ষার্থীর স্ক্রিনের কার্ড: মিল চালুর বাটন + পিন পরিবর্তন
// ---------------------------------------------------------------
Widget studentMealCard(BuildContext context, Map<String, dynamic> s) {
  return ListenableBuilder(
    listenable: extra,
    builder: (context, _) {
      final open = extra.mealOpen;
      return Column(
        children: [
          Card(
            margin: const EdgeInsets.only(top: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: open ? Colors.green : Colors.transparent, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    open
                        ? '✅ ম্যানেজার মিল চালুর অনুমতি দিয়েছেন'
                        : 'মিল চালুর অনুমতি বন্ধ আছে',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: open ? Colors.green : null),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    open
                        ? 'এখন নিজের মিল চালু করতে পারবেন (কয়দিন, কোন কোন বেলা)।'
                        : 'ম্যানেজার অনুমতি দিলে এখানে মিল চালু করার বাটন আসবে।',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (open)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade800,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () =>
                              showMealDialog(context, s, self: true),
                          icon: const Icon(Icons.restaurant),
                          label: const Text('আমার মিল চালু করুন'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Card(
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.lock, color: Colors.teal),
              title: const Text('আমার পিন পরিবর্তন করুন'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showStudentPinDialog(context, s),
            ),
          ),
        ],
      );
    },
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.rice_bowl, size: 72, color: Colors.teal),
              const SizedBox(height: 8),
              const Text('Ossim-এ স্বাগতম',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                const SizedBox(height: 10),
                TextField(
                  controller: spC,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'আপনার পিন',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'প্রথমবার পিন ১২৩৪। ঢুকে নিজের পিন বদলে নিন।',
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

// ---------------------------------------------------------------
// খাবার চিহ্নিত করা (সার্চবারসহ)
// ---------------------------------------------------------------
class AttendanceScreen2 extends StatefulWidget {
  const AttendanceScreen2({super.key});

  @override
  State<AttendanceScreen2> createState() => _AttendanceScreen2State();
}

class _AttendanceScreen2State extends State<AttendanceScreen2> {
  late final DateTime today;
  late DateTime cycle;
  int slot = 0; // 0 = দুপুর, 1 = রাত, 2 = পরদিন সকাল
  final TextEditingController qC = TextEditingController();
  String q = '';

  @override
  void initState() {
    super.initState();
    today = todayDate();
    final n = nowMinutes();
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

  @override
  void dispose() {
    qC.dispose();
    super.dispose();
  }

  String get _key => isoOf(cycle);
  String get _ch => kCycleKeys[slot];

  bool _hasMeal(Map<String, dynamic> s) =>
      (mapOf(s['meals'])[_key] ?? '').contains(_ch);

  bool _ate(Map<String, dynamic> s) =>
      (mapOf(s['eaten'])[_key] ?? '').contains(_ch);

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
    final nq = normSearch(q);
    final shown = nq.isEmpty
        ? on
        : on
            .where((s) =>
                normSearch(s['name'].toString()).contains(nq) ||
                normSearch(s['id'].toString()).contains(nq))
            .toList();
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
                Text('খেয়েছে: ${bnDigits('$ateCount')}',
                    style: const TextStyle(fontSize: 12, color: Colors.white)),
                Text('বাকি: ${bnDigits('$remaining')}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.amber.shade200)),
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
                      Text('মিল দিন: ${dateLabel(cycle)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Text('দুপুর থেকে পরদিন সকাল পর্যন্ত',
                          style: TextStyle(fontSize: 12)),
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
            const SizedBox(height: 8),
            TextField(
              controller: qC,
              onChanged: (v) => setState(() => q = v),
              decoration: InputDecoration(
                hintText: 'নাম বা নম্বর দিয়ে খুঁজুন...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: q.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          qC.clear();
                          q = '';
                        }),
                      ),
                isDense: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            if (shown.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    for (final s in shown) {
                      _setAte(s, true);
                    }
                  },
                  child: Text(nq.isEmpty
                      ? 'সবাইকে চিহ্নিত করুন'
                      : 'এই ${bnDigits('${shown.length}')} জনকে চিহ্নিত করুন'),
                ),
              ),
            Expanded(
              child: on.isEmpty
                  ? const Center(child: Text('এই বেলায় কারও মিল চালু নেই।'))
                  : shown.isEmpty
                      ? const Center(child: Text('কাউকে খুঁজে পাওয়া যায়নি।'))
                      : ListView(
                          children: [
                            for (final s in shown)
                              Card(
                                child: CheckboxListTile(
                                  value: _ate(s),
                                  onChanged: (v) => _setAte(s, v ?? false),
                                  title: Text(s['name'].toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
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
            if (off.isNotEmpty && nq.isEmpty)
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
