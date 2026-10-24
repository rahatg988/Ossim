part of 'screens.dart';

// ---------------------------------------------------------------
// ডায়ালগ ও কাজ (আগে HomeScreen/SettingsScreen-এর ভেতরে ছিল)
// ---------------------------------------------------------------
void showAddStudentDialog(BuildContext context) {
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
              TextField(
                controller: yearC,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'বর্ষ',
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  errorText:
                      (tried && yearC.text.isEmpty) ? 'বর্ষ বেছে নিন' : null,
                ),
                onTap: () async {
                  final v = await pickOption(ctx, 'বর্ষ বেছে নিন', kYears);
                  if (v != null) setDialogState(() => yearC.text = v);
                },
              ),
              TextField(
                controller: roomC,
                decoration: const InputDecoration(labelText: 'রুম নম্বর'),
              ),
              TextField(
                controller: depositC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'শুরুর জমা (৳)'),
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
              final deposit =
                  double.tryParse(normSearch(depositC.text)) ?? 0.0;
              int nextId = 1;
              int nextNo = 1;
              for (final s in data.students) {
                final id = (s['id'] as num).toInt();
                if (id >= nextId) nextId = id + 1;
                final no = noOf(s);
                if (no >= nextNo) nextNo = no + 1;
              }
              final s = <String, dynamic>{
                'id': nextId,
                'no': nextNo,
                'name': name,
                'year': yearC.text,
                'room': roomC.text.trim(),
                'op': 0.0,
                'pd': deposit,
                'pc': 0.0,
                'po': 0.0,
                'slots': 0,
                'meals': <String, String>{},
                'eaten': <String, String>{},
                'history': <Map<String, dynamic>>[],
              };
              data.students.add(s);
              data.addStudent(s);
              if (deposit > 0) data.bumpDeposit(deposit);
              Navigator.pop(ctx);
            },
            child: const Text('যোগ করুন'),
          ),
        ],
      ),
    ),
  );
}

void showDepositDialog(BuildContext context, Map<String, dynamic> student) {
  final amountC = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('${student['name']} - টাকা জমা'),
      content: TextField(
        controller: amountC,
        autofocus: true,
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
            final amount = double.tryParse(normSearch(amountC.text)) ?? 0.0;
            if (amount <= 0) return;
            data.addDeposit(student, amount);
            Navigator.pop(ctx);
          },
          child: const Text('জমা দিন'),
        ),
      ],
    ),
  );
}

void confirmDeleteStudent(BuildContext context, Map<String, dynamic> student) {
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

void confirmNewPeriod(BuildContext context) {
  final p = periodInfo();
  int crN = 0;
  double crS = 0;
  for (final s in data.students) {
    final bl = balOf(s) + advanceRefund(s);
    if (bl > 0) {
      crN++;
      crS += bl;
    }
  }
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('নতুন ${bnDigits('${p.days}')} দিনের হিসাব শুরু করবেন?'),
      content: Text(
        'চলমান হিসাব (${shortDate(p.start)} – ${shortDate(p.end)}) ইতিহাসে জমা হবে: কতজন মিল চালু করেছে আর কত টাকা উঠেছে, তার মোট হিসাব ম্যানেজারের ইতিহাসে, আর প্রত্যেকের নিজের হিসাব তার নিজের ইতিহাসে।\n\nনতুন হিসাবে সবার মিল বন্ধ হয়ে যাবে (যে বেলা খাওয়া হয়নি তার টাকা ফেরত যাবে), আর মিলের খরচ ও পাওনা/বকেয়া সব ৳০ থেকে শুরু হবে। আগে নগদ টাকা মিটিয়ে নিন।${crN > 0 ? '\n\nএখনো ফেরত না দেওয়া পাওনা আছে ${bnDigits('$crN')} জনের, মোট ${money(crS)}। আগে "পাওনা মেটান" দিয়ে মিটিয়ে নিন।' : ''}',
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

void pickManagerRoom(BuildContext context) {
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
              final room = c.text.trim().isNotEmpty ? c.text.trim() : selected;
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

Future<void> editSchedule(BuildContext context, String key, String name) async {
  final cur = data.schedule[key]!;
  final start = await showTimePicker(
    context: context,
    helpText: '$name - শুরুর সময়',
    initialTime: TimeOfDay(hour: cur[0] ~/ 60, minute: cur[0] % 60),
  );
  if (start == null || !context.mounted) return;
  final end = await showTimePicker(
    context: context,
    helpText: '$name - শেষের সময়',
    initialTime: TimeOfDay(hour: cur[1] ~/ 60, minute: cur[1] % 60),
  );
  if (end == null || !context.mounted) return;
  final s = start.hour * 60 + start.minute;
  final e = end.hour * 60 + end.minute;
  if (e <= s) {
    messengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('শেষের সময় শুরুর পরে হতে হবে')));
    return;
  }
  data.schedule[key] = [s, e];
  data.saveConfig();
}

void changeManagerPin(BuildContext context) {
  showOwnPinDialog(context, 'ম্যানেজার পিন পরিবর্তন');
}

void showPriceDialog(BuildContext context, List<String> item) {
  final c = TextEditingController(text: '${extra.prices[item[0]]}');
  String err = '';
  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: Text(item[1]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: c,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'নতুন দাম (৳)'),
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
            onPressed: () {
              final v = int.tryParse(normSearch(c.text));
              if (v == null || v < 0) {
                setD(() => err = 'সঠিক দাম লিখুন');
                return;
              }
              extra.setPrice(item[0], v);
              Navigator.pop(ctx);
            },
            child: const Text('সেভ করুন'),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------
// এক্সেল স্টাইল টেবিল: নীল ঘরে ট্যাপ করলে অপশন আসবে (বর্ষ, রুম, মিল)
// ---------------------------------------------------------------
class StudentTable extends StatefulWidget {
  const StudentTable({super.key});

  @override
  State<StudentTable> createState() => _StudentTableState();
}

class _StudentTableState extends State<StudentTable> {
  int sortCol = 0;
  bool asc = true;

  Comparable _val(Map<String, dynamic> s, int c) {
    switch (c) {
      case 0:
        return noOf(s);
      case 1:
        return s['name'].toString();
      case 2:
        return s['year'].toString();
      case 3:
        return s['room'].toString();
      case 4:
        return numOf(s['op']);
      case 5:
        return numOf(s['pd']);
      case 6:
        return numOf(s['pc']);
      case 7:
        return balOf(s);
      default:
        return activeDays(s);
    }
  }

  Future<void> _editYear(Map<String, dynamic> s) async {
    final v = await pickOption(context, '${s['name']} - বর্ষ বেছে নিন', kYears);
    if (v == null) return;
    s['year'] = v;
    data.saveStudent(s);
  }

  Future<void> _editRoom(Map<String, dynamic> s) async {
    final rooms = <String>{};
    for (final x in data.students) {
      final r = x['room'].toString();
      if (r.isNotEmpty) rooms.add(r);
    }
    final list = rooms.toList()..sort();
    const other = 'নতুন নম্বর লিখুন…';
    final v = await pickOption(
        context, '${s['name']} - রুম বেছে নিন', [...list, other]);
    if (v == null || !mounted) return;
    if (v != other) {
      s['room'] = v;
      data.saveStudent(s);
      return;
    }
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('রুম নম্বর'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'রুম নম্বর'),
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
              s['room'] = t;
              data.saveStudent(s);
              Navigator.pop(ctx);
            },
            child: const Text('সেভ করুন'),
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
        final rows = List<Map<String, dynamic>>.from(data.students);
        rows.sort((a, b) {
          final r = _val(a, sortCol).compareTo(_val(b, sortCol));
          return asc ? r : -r;
        });

        double tOp = 0, tPd = 0, tPc = 0, tBal = 0;
        for (final s in rows) {
          tOp += numOf(s['op']);
          tPd += numOf(s['pd']);
          tPc += numOf(s['pc']);
          tBal += balOf(s);
        }

        DataColumn col(String t, {bool num = false}) => DataColumn(
              label:
                  Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
              numeric: num,
              onSort: (c, a) => setState(() {
                sortCol = c;
                asc = a;
              }),
            );

        DataCell cell(String t, {Color? color, bool bold = false}) => DataCell(
              Text(t,
                  style: TextStyle(
                      color: color,
                      fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
            );

        DataCell tapCell(String t, VoidCallback onTap) => DataCell(
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: tintC(context),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t, style: TextStyle(color: priC(context))),
                    Icon(Icons.arrow_drop_down,
                        size: 18, color: priC(context)),
                  ],
                ),
              ),
              onTap: onTap,
            );

        if (rows.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(28),
            child: Center(
                child: Text('কোনো স্টুডেন্ট নেই।',
                    style: TextStyle(color: mutC(context)))),
          );
        }

        final dark = isDark(context);
        final sumColor = dark ? Colors.white : Colors.black87;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                  'রঙিন ঘরে ট্যাপ করলে অপশন আসবে (বর্ষ, রুম, মিল)। হেডারে ট্যাপ করলে সর্ট হবে।',
                  style: TextStyle(fontSize: 12, color: mutC(context))),
            ),
            Container(
              decoration: BoxDecoration(
                color: sfC(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: lnC(context)),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  sortColumnIndex: sortCol,
                  sortAscending: asc,
                  columnSpacing: 18,
                  headingRowHeight: 44,
                  dataRowMinHeight: 46,
                  dataRowMaxHeight: 46,
                  headingRowColor: WidgetStatePropertyAll(tintC(context)),
                  columns: [
                    col('নং', num: true),
                    col('নাম'),
                    col('বর্ষ'),
                    col('রুম'),
                    col('শুরুর', num: true),
                    col('জমা', num: true),
                    col('খরচ', num: true),
                    col('পাওনা/বকেয়া', num: true),
                    col('মিল', num: true),
                  ],
                  rows: [
                    for (final s in rows)
                      DataRow(cells: [
                        cell(bnDigits('${noOf(s)}')),
                        cell(s['name'].toString(), bold: true),
                        tapCell(s['year'].toString(), () => _editYear(s)),
                        tapCell(bnDigits(s['room'].toString()),
                            () => _editRoom(s)),
                        cell(money(numOf(s['op']))),
                        cell(money(numOf(s['pd']))),
                        cell(money(numOf(s['pc']))),
                        cell(
                          money(balOf(s)),
                          color: balOf(s) >= 0 ? okC(context) : badC(context),
                          bold: true,
                        ),
                        tapCell(
                          activeDays(s) > 0
                              ? '${bnDigits('${activeDays(s)}')} দিন'
                              : (activeLines(s).isNotEmpty ? 'চালু' : 'বন্ধ'),
                          () => showMealDialog(context, s),
                        ),
                      ]),
                    DataRow(
                      color: WidgetStatePropertyAll(warnTint(context)),
                      cells: [
                        cell(''),
                        cell('সর্বমোট', color: sumColor, bold: true),
                        cell(''),
                        cell(''),
                        cell(money(tOp), color: sumColor, bold: true),
                        cell(money(tPd), color: sumColor, bold: true),
                        cell(money(tPc), color: sumColor, bold: true),
                        cell(money(tBal), color: sumColor, bold: true),
                        cell(''),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------
// ছোট সাহায্যকারী: নিশ্চিতকরণ, হল বদলানো
// ---------------------------------------------------------------
void confirmDialog(
    BuildContext context, String title, String text, VoidCallback onYes,
    {String yes = 'হ্যাঁ, মুছুন'}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('না'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: K.bad, foregroundColor: Colors.white),
          onPressed: () {
            Navigator.pop(ctx);
            onYes();
          },
          child: Text(yes),
        ),
      ],
    ),
  );
}

Future<void> leaveToPicker(BuildContext context) async {
  await data.leaveHall();
  if (!context.mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const HallPickerScreen()),
    (r) => false,
  );
}

// ---------------------------------------------------------------
// ম্যানেজারের ইতিহাস: প্রতিটা হিসাবের মোট হিসাব (কতজন, কত টাকা)
// ---------------------------------------------------------------
class PeriodHistoryScreen extends StatelessWidget {
  const PeriodHistoryScreen({super.key});

  Widget _stat(BuildContext c, String value, String label, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: tintC(c),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color ?? inkC(c))),
            ),
            Text(label, style: TextStyle(fontSize: 11, color: mutC(c))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: data,
      builder: (context, _) {
        final list = data.periods;
        return Scaffold(
          backgroundColor: bgC(context),
          appBar: plainBar(context, 'ইতিহাস · মোট হিসাব', actions: [
            if (list.isNotEmpty)
              TextButton(
                onPressed: () => confirmDialog(
                  context,
                  'সব ইতিহাস মুছবেন?',
                  '${data.hallName}-এর আগের সব হিসাব স্থায়ীভাবে মুছে যাবে। শিক্ষার্থীদের নিজেদের ইতিহাস ঠিক থাকবে।',
                  data.clearPeriods,
                ),
                child:
                    Text('সব মুছুন', style: TextStyle(color: badC(context))),
              ),
          ]),
          body: list.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Text(
                      'এখনও কোনো সম্পন্ন হিসাব নেই।\nনতুন হিসাব শুরু করলে আগেরটা এখানে জমা হবে।',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: mutC(context)),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    for (final e in list) _periodCard(context, e),
                  ],
                ),
        );
      },
    );
  }

  Widget _periodCard(BuildContext context, Map<String, dynamic> e) {
    final from = DateTime.parse(e['from'].toString());
    final to = DateTime.parse(e['to'].toString());
    final dd = (e['dd'] as List? ?? const [])
        .map((v) => (v as num).toDouble())
        .toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${shortDate(from)} – ${shortDate(to)} · ${bnDigits('${e['days'] ?? dd.length}')} দিন',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: inkC(context)),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: badC(context)),
                onPressed: () => confirmDialog(
                  context,
                  'এই হিসাব মুছবেন?',
                  '${shortDate(from)} – ${shortDate(to)} এর হিসাব স্থায়ীভাবে মুছে যাবে। শিক্ষার্থীদের নিজেদের ইতিহাস ঠিক থাকবে।',
                  () => data.deletePeriod(e['id'].toString()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _stat(context, '${bnDigits('${e['students'] ?? 0}')} জন',
                  'মিল চালু করেছে'),
              const SizedBox(width: 8),
              _stat(context, bnDigits('${e['slots'] ?? 0}'), 'মোট বেলা'),
              const SizedBox(width: 8),
              _stat(context, money(numOf(e['deposit'])), 'জমা উঠেছে',
                  color: okC(context)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
              'মিলের খরচ ${money(numOf(e['cost']))}${numOf(e['po']) > 0 ? ' · ফেরত দেওয়া ${money(numOf(e['po']))}' : ''}',
              style: TextStyle(fontSize: 13, color: mutC(context))),
          if (dd.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              [
                for (int i = 0; i < dd.length; i++)
                  'দিন ${bnDigits('${i + 1}')}: ${money(dd[i])}'
              ].join(' · '),
              style: TextStyle(fontSize: 12, color: mutC(context)),
            ),
          ],
        ],
      ),
    );
  }
}
