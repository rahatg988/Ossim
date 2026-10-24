part of 'screens.dart';

// ---------------------------------------------------------------
// হল বাছা ও নতুন হল তৈরি
// ---------------------------------------------------------------
class HallPickerScreen extends StatefulWidget {
  const HallPickerScreen({super.key});

  @override
  State<HallPickerScreen> createState() => _HallPickerScreenState();
}

class _HallPickerScreenState extends State<HallPickerScreen> {
  String q = '';

  Future<void> _pick(String id) async {
    await data.selectHall(id);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen2()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: data,
      builder: (context, _) {
        final nq = normSearch(q);
        final list = data.halls
            .where((h) =>
                nq.isEmpty || normSearch(h['name'].toString()).contains(nq))
            .toList();
        return Scaffold(
          backgroundColor: bgC(context),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                pageHeader(context, 'আপনার হল বেছে নিন',
                    sub: 'প্রতিটা হলের শিক্ষার্থী ও হিসাব আলাদা থাকে'),
                searchField(
                    context, 'হলের নাম দিয়ে খুঁজুন', (v) => setState(() => q = v)),
                if (!data.hallsLoaded)
                  const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        data.halls.isEmpty
                            ? 'এখনও কোনো হল নেই।\nনিচের বাটনে নতুন হল তৈরি করুন।'
                            : 'কোনো হল পাওয়া যায়নি।',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: mutC(context)),
                      ),
                    ),
                  ),
                for (final h in list)
                  AppCard(
                    onTap: () => _pick(h['id'].toString()),
                    child: Row(
                      children: [
                        iconTile(context, Icons.apartment),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(h['name'].toString(),
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: inkC(context))),
                        ),
                        Icon(Icons.chevron_right, color: mutC(context)),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed: () => showCreateHallDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('নতুন হল তৈরি করুন (ম্যানেজারের জন্য)'),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'আপনার হল তালিকায় না থাকলে ম্যানেজার নতুন হল তৈরি করে শিক্ষার্থী যোগ করবেন।',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: mutC(context)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> showCreateHallDialog(BuildContext context) async {
  final legacy = await data.legacyExists();
  if (!context.mounted) return;
  final nameC = TextEditingController();
  final pinC = TextEditingController();
  String err = '';
  bool busy = false;
  bool importLegacy = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: const Text('নতুন হল তৈরি করুন'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'নিজের হলের শিক্ষার্থী ও হিসাব এখানে আলাদাভাবে তৈরি হবে।',
                style: TextStyle(fontSize: 13),
              ),
              TextField(
                controller: nameC,
                decoration: const InputDecoration(labelText: 'হলের নাম'),
              ),
              TextField(
                controller: pinC,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'ম্যানেজার পিন (কমপক্ষে ৪ অক্ষর)'),
              ),
              if (legacy)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: importLegacy,
                  onChanged: busy
                      ? null
                      : (v) => setD(() => importLegacy = v ?? false),
                  title: const Text('আগের ডেটা এই হলে আনুন',
                      style: TextStyle(fontSize: 14)),
                  subtitle: const Text(
                      'আগের শিক্ষার্থী, নোটিশ, দাম ও সময় কপি হবে',
                      style: TextStyle(fontSize: 12)),
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
                    final name = nameC.text.trim();
                    final pin = pinC.text.trim();
                    if (name.isEmpty) {
                      setD(() => err = 'হলের নাম লিখুন');
                      return;
                    }
                    if (pin.length < 4) {
                      setD(() => err = 'পিন কমপক্ষে ৪ অক্ষরের হতে হবে');
                      return;
                    }
                    setD(() {
                      busy = true;
                      err = '';
                    });
                    final id = await data.createHall(name, pin,
                        importLegacy: importLegacy);
                    if (id == null) {
                      setD(() {
                        busy = false;
                        err = 'হল তৈরি করা যায়নি। ইন্টারনেট দেখে আবার চেষ্টা করুন';
                      });
                      return;
                    }
                    await data.selectHall(id);
                    await data.openAsManager();
                    extra.isManager = true;
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (r) => false,
                      );
                    }
                  },
            child: busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('হল তৈরি করুন'),
          ),
        ],
      ),
    ),
  );
}

// ম্যানেজার শিক্ষার্থীর জন্য নতুন পিন বসান (পিন ভুলে গেলে)
void showResetPinDialog(BuildContext context, Map<String, dynamic> student) {
  final c = TextEditingController(text: '1234');
  String err = '';
  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: Text('${student['name']} - নতুন পিন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'আগের পিন আর কাজ করবে না। নতুন পিনটা শিক্ষার্থীকে জানান, সে ঢুকে নিজের পিন বদলে নেবে।',
              style: TextStyle(fontSize: 13),
            ),
            TextField(
              controller: c,
              autofocus: true,
              decoration: const InputDecoration(
                  labelText: 'নতুন পিন (কমপক্ষে ৪ অক্ষর)'),
            ),
            if (err.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(err,
                    style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () async {
              final p = c.text.trim();
              if (p.length < 4) {
                setD(() => err = 'পিন কমপক্ষে ৪ অক্ষরের হতে হবে');
                return;
              }
              try {
                await data.resetStudentPin((student['id'] as num).toInt(), p);
              } catch (_) {
                setD(() => err = 'পিন বদলানো যায়নি, আবার চেষ্টা করুন');
                return;
              }
              if (ctx.mounted) Navigator.pop(ctx);
              messengerKey.currentState?.showSnackBar(
                  const SnackBar(content: Text('নতুন পিন বসানো হয়েছে')));
            },
            child: const Text('বসান'),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------
// পাওনা মেটানো: ম্যানেজার শিক্ষার্থীকে টাকা ফেরত দেওয়ার পর হিসাব শেষ করেন
// ---------------------------------------------------------------
void showPayoutDialog(BuildContext context, Map<String, dynamic> student) {
  final bal = balOf(student);
  if (bal <= 0) {
    messengerKey.currentState
        ?.showSnackBar(const SnackBar(content: Text('কোনো পাওনা নেই')));
    return;
  }
  final c = TextEditingController(
      text: bal.toStringAsFixed(bal == bal.roundToDouble() ? 0 : 2));
  String err = '';
  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: Text('${student['name']} - পাওনা মেটান'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'শিক্ষার্থীকে টাকা ফেরত দেওয়ার পর এখানে হিসাব শেষ করুন।',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 10),
              Text('বর্তমান পাওনা: ${money(bal)}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(
                controller: c,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'ফেরত দেওয়া টাকা (৳)'),
              ),
              const SizedBox(height: 6),
              const Text('কিছুটা দিলে সেটুকু লিখুন, বাকিটা পাওনাই থাকবে।',
                  style: TextStyle(fontSize: 12)),
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
              final a = double.tryParse(normSearch(c.text)) ?? 0.0;
              if (a <= 0 || a > bal + 0.0001) {
                setD(() => err = 'সঠিক পরিমাণ লিখুন (সর্বোচ্চ ${money(bal)})');
                return;
              }
              data.payOut(student, a);
              Navigator.pop(ctx);
              final left = bal - a;
              messengerKey.currentState?.showSnackBar(SnackBar(
                  content: Text(left > 0.0001
                      ? '${money(a)} ফেরত দেওয়া হয়েছে · বাকি পাওনা ${money(left)}'
                      : 'পাওনা পুরো মিটেছে · ${money(a)} ফেরত')));
            },
            child: const Text('টাকা দিয়েছি, মেটান'),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------
// নাম ও নম্বর বদলানো (পিন, হিসাব ও ইতিহাস আগের মতোই থাকে)
// ---------------------------------------------------------------
void showRenameDialog(BuildContext context, Map<String, dynamic> student) {
  final nameC = TextEditingController(text: student['name'].toString());
  final noC = TextEditingController(text: '${noOf(student)}');
  String err = '';
  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: const Text('নাম ও নম্বর বদলান'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('পিন, হিসাব ও ইতিহাস আগের মতোই থাকবে।',
                  style: TextStyle(fontSize: 13)),
              TextField(
                controller: nameC,
                decoration: const InputDecoration(labelText: 'নাম'),
              ),
              TextField(
                controller: noC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'নম্বর'),
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
              final n = nameC.text.trim();
              final no = int.tryParse(normSearch(noC.text));
              if (n.isEmpty) {
                setD(() => err = 'নাম লিখুন');
                return;
              }
              if (no == null || no <= 0) {
                setD(() => err = 'সঠিক নম্বর লিখুন');
                return;
              }
              final clash = data.students
                  .any((x) => x['id'] != student['id'] && noOf(x) == no);
              if (clash) {
                setD(() => err = 'এই নম্বর অন্য শিক্ষার্থীর আছে');
                return;
              }
              data.renameStudent(student, n, no);
              Navigator.pop(ctx);
              messengerKey.currentState?.showSnackBar(
                  const SnackBar(content: Text('নাম ও নম্বর বদলানো হয়েছে')));
            },
            child: const Text('সেভ করুন'),
          ),
        ],
      ),
    ),
  );
}
