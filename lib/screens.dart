// ---------------------------------------------------------------
// screens.dart  (lib/screens.dart নামে নতুন ফাইল)
// নতুন প্রফেশনাল ডিজাইন: ডিজাইন-কিট + সব স্ক্রিন
// ---------------------------------------------------------------
import 'package:flutter/material.dart';

import 'extras.dart';
import 'main.dart';

part 'screens_b.dart';
part 'screens_c.dart';
part 'screens_d.dart';

// ---------------------------------------------------------------
// ডিজাইন-কিট: রং, কার্ড, ছোট উইজেট
// ---------------------------------------------------------------
class K {
  static const pri = Color(0xFF0F6B5C);
  static const priDark = Color(0xFF0A3F36);
  static const ok = Color(0xFF168A5B);
  static const bad = Color(0xFFC8412F);
  static const warn = Color(0xFFB7791F);
}

bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color bgC(BuildContext c) =>
    isDark(c) ? const Color(0xFF0C1513) : const Color(0xFFF3F6F5);
Color sfC(BuildContext c) => isDark(c) ? const Color(0xFF15211E) : Colors.white;
Color lnC(BuildContext c) =>
    isDark(c) ? const Color(0xFF26362F) : const Color(0xFFE2E9E6);
Color mutC(BuildContext c) =>
    isDark(c) ? const Color(0xFF9AAEA8) : const Color(0xFF60706B);
Color inkC(BuildContext c) =>
    isDark(c) ? const Color(0xFFE8F1EE) : const Color(0xFF0F1F1C);
Color tintC(BuildContext c) =>
    isDark(c) ? const Color(0xFF17382F) : const Color(0xFFE3F1ED);
Color priC(BuildContext c) => isDark(c) ? const Color(0xFF37AE98) : K.pri;
Color okC(BuildContext c) => isDark(c) ? const Color(0xFF4CC38A) : K.ok;
Color badC(BuildContext c) => isDark(c) ? const Color(0xFFEF6B5B) : K.bad;
Color warnC(BuildContext c) => isDark(c) ? const Color(0xFFE3B04B) : K.warn;
Color warnTint(BuildContext c) =>
    isDark(c) ? const Color(0xFF3A2F12) : const Color(0xFFFCF3DC);
Color okTint(BuildContext c) =>
    isDark(c) ? const Color(0xFF14301F) : const Color(0xFFE2F4EA);
Color badTint(BuildContext c) =>
    isDark(c) ? const Color(0xFF3A1E1B) : const Color(0xFFFBE9E5);

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.color,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(16);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? sfC(context),
        borderRadius: r,
        border: Border.all(color: borderColor ?? lnC(context)),
        boxShadow: isDark(context)
            ? null
            : const [
                BoxShadow(
                    color: Color(0x0D0F2823),
                    blurRadius: 10,
                    offset: Offset(0, 3)),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: r,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

// kind: pri, ok, bad, warn, mut
Widget pill(BuildContext c, String t, {String kind = 'pri'}) {
  Color bg;
  Color fg;
  switch (kind) {
    case 'ok':
      bg = okTint(c);
      fg = okC(c);
      break;
    case 'bad':
      bg = badTint(c);
      fg = badC(c);
      break;
    case 'warn':
      bg = warnTint(c);
      fg = warnC(c);
      break;
    case 'mut':
      bg = lnC(c);
      fg = mutC(c);
      break;
    default:
      bg = tintC(c);
      fg = priC(c);
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
    child: Text(t,
        style:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
  );
}

Widget pageHeader(BuildContext c, String title,
    {String? sub, List<Widget> actions = const []}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: inkC(c))),
              if (sub != null)
                Text(sub, style: TextStyle(fontSize: 13, color: mutC(c))),
            ],
          ),
        ),
        ...actions,
      ],
    ),
  );
}

Widget iconBox(BuildContext c, IconData icon, VoidCallback onTap,
    {int badge = 0}) {
  return Padding(
    padding: const EdgeInsets.only(left: 8),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: sfC(c),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: lnC(c)),
        ),
        child: Badge(
          isLabelVisible: badge > 0,
          label: Text('$badge'),
          child: Icon(icon, size: 20, color: inkC(c)),
        ),
      ),
    ),
  );
}

Widget bellBtn(BuildContext context, {required bool manager}) => iconBox(
      context,
      Icons.notifications_none,
      () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NoticesScreen(isManager: manager)),
      ),
      badge: data.notices.length,
    );

Widget moreMenu(BuildContext context, {Map<String, dynamic>? student}) {
  return Padding(
    padding: const EdgeInsets.only(left: 8),
    child: PopupMenuButton<String>(
      onSelected: (v) {
        if (v == 'dark') data.setDark(!isDark(context));
        if (v == 'pin' && student != null) {
          showStudentPinDialog(context, student);
        }
        if (v == 'hall') leaveToPicker(context);
        if (v == 'out') goLogin(context);
      },
      itemBuilder: (_) => [
        PopupMenuItem(
            value: 'dark',
            child: Text(isDark(context) ? 'লাইট মোড' : 'ডার্ক মোড')),
        if (student != null)
          const PopupMenuItem(value: 'pin', child: Text('পিন পরিবর্তন')),
        const PopupMenuItem(value: 'hall', child: Text('হল বদলান')),
        const PopupMenuItem(value: 'out', child: Text('লগআউট')),
      ],
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: sfC(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: lnC(context)),
        ),
        child: Icon(Icons.more_vert, size: 20, color: inkC(context)),
      ),
    ),
  );
}

Widget segControl(BuildContext c, List<String> labels, int sel,
    void Function(int) onTap) {
  return Container(
    padding: const EdgeInsets.all(3),
    margin: const EdgeInsets.only(bottom: 12),
    decoration:
        BoxDecoration(color: lnC(c), borderRadius: BorderRadius.circular(12)),
    child: Row(
      children: [
        for (int i = 0; i < labels.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: i == sel ? sfC(c) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(labels[i],
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: i == sel ? inkC(c) : mutC(c))),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

Widget searchField(BuildContext c, String hint, ValueChanged<String> onChanged,
    {TextEditingController? controller}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor: sfC(c),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lnC(c)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lnC(c)),
        ),
      ),
    ),
  );
}

InputDecoration inputDeco(BuildContext c, String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 20),
    filled: true,
    fillColor: sfC(c),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: lnC(c)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: lnC(c)),
    ),
  );
}

Widget avatar(BuildContext c, String t, {double r = 20}) => CircleAvatar(
      radius: r,
      backgroundColor: tintC(c),
      foregroundColor: priC(c),
      child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
    );

Widget segBar(int total, int done, Color on, Color off) {
  return Row(
    children: [
      for (int i = 0; i < total; i++)
        Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 4),
            decoration: BoxDecoration(
              color: i < done ? on : off,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
    ],
  );
}

Widget sectionLabel(BuildContext c, String t) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
      child: Text(t,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: mutC(c))),
    );

Widget iconTile(BuildContext c, IconData i, {Color? bg, Color? fg}) =>
    Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg ?? tintC(c),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(i, color: fg ?? priC(c)),
    );

// ---------------------------------------------------------------
// সাহায্যকারী: বেলা, মেয়াদ
// ---------------------------------------------------------------
// মিলের তারিখ-চক্র: সকাল আগের দিনের চক্রের অংশ
bool hasSlot(Map<String, dynamic> s, String k, DateTime date) {
  final cycle = k == 'b' ? addDays(date, -1) : date;
  return (mapOf(s['meals'])[isoOf(cycle)] ?? '').contains(k);
}

bool ateSlot(Map<String, dynamic> s, String k, DateTime date) {
  final cycle = k == 'b' ? addDays(date, -1) : date;
  return (mapOf(s['eaten'])[isoOf(cycle)] ?? '').contains(k);
}

class PeriodInfo {
  final int days;
  final DateTime start;
  final DateTime end;
  final int dn;
  final bool over;
  PeriodInfo(this.days, this.start, this.end, this.dn, this.over);
}

PeriodInfo periodInfo() {
  final days = extra.periodDays;
  final start = DateTime.parse(data.periodStart);
  final end = addDays(start, days - 1);
  final today = todayDate();
  int dn = today.difference(start).inDays + 1;
  if (dn < 1) dn = 1;
  if (dn > days) dn = days;
  return PeriodInfo(days, start, end, dn, today.isAfter(end));
}

String slotName(String k) => k == 'b' ? 'সকাল' : (k == 'l' ? 'দুপুর' : 'রাত');

// ---------------------------------------------------------------
// শিক্ষার্থীর স্ক্রিন
// ---------------------------------------------------------------
class StudentScreen extends StatelessWidget {
  final int studentId;
  const StudentScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([data, extra]),
      builder: (context, _) {
        Map<String, dynamic>? found;
        for (final x in data.students) {
          if (x['id'] == studentId) found = x;
        }
        if (found == null) {
          return Scaffold(
            backgroundColor: bgC(context),
            body: const Center(child: Text('আপনার তথ্য পাওয়া যায়নি।')),
          );
        }
        final Map<String, dynamic> s = found;

        return Scaffold(
          backgroundColor: bgC(context),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                _studentHeader(context, s),
                _noticeCard(context),
                _managerCard(context),
                _hero(context, s),
                _nextMeal(context, s),
                _permissionBanner(context, s),
                _mealGrid(context, s),
                _scheduleBlock(context),
                _priceBlock(context),
                AppCard(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => HistoryScreen(studentId: studentId)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.history, color: priC(context)),
                      const SizedBox(width: 12),
                      const Expanded(
                          child: Text('আগের সব হিসাব দেখুন (ইতিহাস)',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      Icon(Icons.chevron_right, color: mutC(context)),
                    ],
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

Widget _studentHeader(BuildContext context, Map<String, dynamic> s) {
  final name = s['name'].toString();
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: K.pri,
          foregroundColor: Colors.white,
          child: Text(name.isEmpty ? '?' : name.substring(0, 1),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: inkC(context))),
              Text('রুম ${s['room']} · ${s['year']}',
                  style: TextStyle(fontSize: 13, color: mutC(context))),
            ],
          ),
        ),
        bellBtn(context, manager: false),
        moreMenu(context, student: s),
      ],
    ),
  );
}

Widget _noticeCard(BuildContext context) {
  if (data.notices.isEmpty) return const SizedBox.shrink();
  final t = (data.notices.last['text'] ?? '').toString();
  return AppCard(
    color: warnTint(context),
    borderColor: warnC(context).withOpacity(0.5),
    padding: const EdgeInsets.all(12),
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NoticesScreen(isManager: false)),
    ),
    child: Row(
      children: [
        Icon(Icons.campaign_outlined, color: warnC(context)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(t,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: inkC(context))),
        ),
        Icon(Icons.chevron_right, color: mutC(context)),
      ],
    ),
  );
}

Widget _managerCard(BuildContext context) {
  return AppCard(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        Icon(Icons.admin_panel_settings_outlined, color: priC(context)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            data.managerRoom.isEmpty
                ? 'বর্তমান ম্যানেজার এখনও নির্ধারণ করা হয়নি'
                : 'বর্তমান ম্যানেজার: রুম ${data.managerRoom} এর ভাইয়েরা',
            style: TextStyle(color: inkC(context)),
          ),
        ),
      ],
    ),
  );
}

Widget _hero(BuildContext context, Map<String, dynamic> s) {
  final p = periodInfo();
  final cl = balOf(s);
  final due = cl < 0;
  Widget mini(String a, String b) => Expanded(
        child: Column(
          children: [
            Text(a,
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 2),
            Text(b,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
      );
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: K.priDark,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(due ? 'আপনার বকেয়া' : 'আপনার পাওনা',
                style: const TextStyle(fontSize: 13, color: Colors.white70)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0x29FFFFFF),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text('চলমান হিসাব',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(money(cl.abs()),
            style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: due ? const Color(0xFFFFB4A8) : Colors.white)),
        const SizedBox(height: 12),
        segBar(p.days, p.dn, Colors.white, const Color(0x38FFFFFF)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(shortDate(p.start),
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
            Text('দিন ${bnDigits('${p.dn}')}/${bnDigits('${p.days}')}',
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
            Text(shortDate(p.end),
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        const SizedBox(height: 14),
        const Divider(color: Color(0x2EFFFFFF), height: 1),
        const SizedBox(height: 12),
        Row(
          children: [
            mini('শুরুর', money(numOf(s['op']))),
            mini('জমা', '+${money(numOf(s['pd']))}'),
            mini('খরচ', '−${money(numOf(s['pc']))}'),
          ],
        ),
        if (numOf(s['po']) > 0)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ফেরত পেয়েছেন',
                    style: TextStyle(fontSize: 12, color: Colors.white70)),
                Text(money(numOf(s['po'])),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
          ),
      ],
    ),
  );
}

Widget _nextMeal(BuildContext context, Map<String, dynamic> s) {
  final n = nowMinutes();
  String key = 'b';
  DateTime date = todayDate();
  bool ongoing = false;
  int left = 0;
  bool found = false;
  for (final k in ['b', 'l', 'd']) {
    final sc = data.schedule[k]!;
    if (n < sc[1]) {
      key = k;
      ongoing = n >= sc[0];
      left = ongoing ? sc[1] - n : sc[0] - n;
      found = true;
      break;
    }
  }
  if (!found) {
    key = 'b';
    date = addDays(todayDate(), 1);
    left = 24 * 60 - n + data.schedule['b']![0];
  }
  final on = hasSlot(s, key, date);
  final h = left ~/ 60;
  final m = left % 60;
  final dur =
      '${h > 0 ? '${bnDigits('$h')} ঘণ্টা ' : ''}${bnDigits('$m')} মিনিট';
  final when = found ? 'আজ' : 'আগামীকাল';
  return AppCard(
    child: Row(
      children: [
        iconTile(context, Icons.schedule),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('পরের খাবার: ${slotName(key)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: inkC(context))),
              Text(
                  '$when ${fmtRange(key)} · ${ongoing ? 'এখন চলছে, শেষ হতে আর ' : 'আর '}$dur',
                  style: TextStyle(fontSize: 13, color: mutC(context))),
            ],
          ),
        ),
        const SizedBox(width: 8),
        pill(context, on ? 'মিল চালু' : 'মিল বন্ধ', kind: on ? 'ok' : 'mut'),
      ],
    ),
  );
}

Widget _permissionBanner(BuildContext context, Map<String, dynamic> s) {
  if (extra.mealOpen) {
    return AppCard(
      color: okTint(context),
      borderColor: okC(context),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: okC(context), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.check, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('মিল চালুর অনুমতি আছে',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: inkC(context))),
                Text('কয়দিন, কোন বেলা — নিজেই বেছে নিন',
                    style: TextStyle(fontSize: 13, color: mutC(context))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: K.pri,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => showMealDialog(context, s, self: true),
            child: const Text('চালু করুন'),
          ),
        ],
      ),
    );
  }
  return AppCard(
    child: Row(
      children: [
        iconTile(context, Icons.lock_outline,
            bg: lnC(context), fg: mutC(context)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('মিল চালুর অনুমতি বন্ধ',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: inkC(context))),
              Text('ম্যানেজার অনুমতি দিলে এখানে বাটন আসবে',
                  style: TextStyle(fontSize: 13, color: mutC(context))),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _mealGrid(BuildContext context, Map<String, dynamic> s) {
  final today = todayDate();
  final dates = List.generate(extra.periodDays, (i) => addDays(today, i));
  final meals = mapOf(s['meals']);
  Widget head(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Center(
            child: Text(t,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: mutC(context)))),
      );
  Widget cell(bool on) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: on
              ? Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                      color: priC(context), shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                )
              : Text('—', style: TextStyle(color: lnC(context))),
        ),
      );
  return AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('আমার মিল',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: inkC(context))),
        const SizedBox(height: 12),
        Table(
          columnWidths: const {0: FlexColumnWidth(2.4)},
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(children: [
              const SizedBox.shrink(),
              head('দুপুর'),
              head('রাত'),
              head('সকাল'),
            ]),
            for (final d in dates)
              TableRow(
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: lnC(context)))),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                        '${kWeekdays[d.weekday % 7]} ${shortDate(d)}',
                        style: TextStyle(fontSize: 13, color: inkC(context))),
                  ),
                  cell((meals[isoOf(d)] ?? '').contains('l')),
                  cell((meals[isoOf(d)] ?? '').contains('d')),
                  cell((meals[isoOf(d)] ?? '').contains('b')),
                ],
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text('সকাল = ওই তারিখের পরদিন সকাল',
            style: TextStyle(fontSize: 12, color: mutC(context))),
      ],
    ),
  );
}

Widget _infoRow(BuildContext context, String a, String b) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(a, style: TextStyle(color: mutC(context))),
          Text(b,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: inkC(context))),
        ],
      ),
    );

Widget _scheduleBlock(BuildContext context) {
  return AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('খাবারের সময়',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: inkC(context))),
        const SizedBox(height: 6),
        for (final k in ['b', 'l', 'd']) _infoRow(context, slotName(k), fmtRange(k)),
      ],
    ),
  );
}

Widget _priceBlock(BuildContext context) {
  return AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('মূল্য তালিকা (প্রতি দিন)',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: inkC(context))),
        const SizedBox(height: 6),
        for (final it in ExtraData.kPriceNames)
          _infoRow(context, it[1], '৳ ${bnDigits('${extra.prices[it[0]]}')}'),
      ],
    ),
  );
}

// ---------------------------------------------------------------
// হিসাবের ইতিহাস
// ---------------------------------------------------------------
PreferredSizeWidget plainBar(BuildContext context, String title,
        {List<Widget>? actions}) =>
    AppBar(
      actions: actions,
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.bold, color: inkC(context))),
      backgroundColor: bgC(context),
      foregroundColor: inkC(context),
      elevation: 0,
      scrolledUnderElevation: 0,
    );

class HistoryScreen extends StatelessWidget {
  final int studentId;
  const HistoryScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([data, extra]),
      builder: (context, _) {
        Map<String, dynamic>? found;
        for (final x in data.students) {
          if (x['id'] == studentId) found = x;
        }
        if (found == null) {
          return Scaffold(
            backgroundColor: bgC(context),
            appBar: plainBar(context, 'হিসাবের ইতিহাস'),
            body: const Center(child: Text('তথ্য পাওয়া যায়নি।')),
          );
        }
        final Map<String, dynamic> st = found;
        final all = (st['history'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        final p = periodInfo();

        return Scaffold(
          backgroundColor: bgC(context),
          appBar: plainBar(context, 'হিসাবের ইতিহাস', actions: [
            if (all.isNotEmpty)
              TextButton(
                onPressed: () => confirmDialog(
                  context,
                  'সব ইতিহাস মুছবেন?',
                  'আপনার আগের সব হিসাব স্থায়ীভাবে মুছে যাবে। এটা ফেরত আনা যাবে না।',
                  () => data.clearHistory(st),
                ),
                child: Text('সব মুছুন', style: TextStyle(color: badC(context))),
              ),
          ]),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              AppCard(
                borderColor: priC(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('চলমান হিসাব',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: inkC(context))),
                        pill(context,
                            '${shortDate(p.start)} – ${shortDate(p.end)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    accountRows(numOf(st['op']), numOf(st['pd']),
                        numOf(st['pc']), balOf(st),
                        po: numOf(st['po'])),
                  ],
                ),
              ),
              sectionLabel(
                  context, 'আগের হিসাব (${bnDigits('${all.length}')}টি)'),
              if (all.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                      child: Text('এখনও কোনো আগের হিসাব নেই।',
                          style: TextStyle(color: mutC(context)))),
                ),
              for (int i = all.length - 1; i >= 0; i--)
                AppCard(
                  padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${shortDate(DateTime.parse(all[i]['from'] as String))} – ${shortDate(DateTime.parse(all[i]['to'] as String))}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: inkC(context)),
                            ),
                          ),
                          Text(
                            'বেলা ${bnDigits('${all[i]['slots'] ?? 0}')} | খেয়েছে ${bnDigits('${all[i]['ate'] ?? 0}')}',
                            style:
                                TextStyle(fontSize: 12, color: mutC(context)),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline,
                                color: badC(context)),
                            onPressed: () => confirmDialog(
                              context,
                              'এই হিসাব মুছবেন?',
                              'এই হিসাবটি স্থায়ীভাবে মুছে যাবে। এটা ফেরত আনা যাবে না।',
                              () => data.deleteHistory(st, i),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: accountRows(
                            numOf(all[i]['op']),
                            numOf(all[i]['pd']),
                            numOf(all[i]['pc']),
                            numOf(all[i]['cl']),
                            po: numOf(all[i]['po'])),
                      ),
                    ],
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
          backgroundColor: bgC(context),
          appBar: plainBar(context, 'নোটিফিকেশন'),
          floatingActionButton: isManager
              ? FloatingActionButton.extended(
                  onPressed: () => _compose(context),
                  backgroundColor: K.pri,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.send),
                  label: const Text('নতুন নোটিফিকেশন'),
                )
              : null,
          body: items.isEmpty
              ? Center(
                  child: Text('কোনো নোটিফিকেশন নেই।',
                      style: TextStyle(color: mutC(context))))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                  children: [
                    if (isManager)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          'পাঠানো নোটিফিকেশন সবার অ্যাপে দেখা যাবে (অ্যাপ খুললে বা খোলা থাকলে)। ফোনে আলাদা পপআপ আসবে না।',
                          style:
                              TextStyle(fontSize: 12, color: mutC(context)),
                        ),
                      ),
                    for (final n in items)
                      AppCard(
                        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text((n['text'] ?? '').toString(),
                                      style: TextStyle(
                                          color: inkC(context))),
                                  const SizedBox(height: 4),
                                  Text(fmtNoticeTime(n['at'].toString()),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: mutC(context))),
                                ],
                              ),
                            ),
                            if (isManager)
                              IconButton(
                                icon: Icon(Icons.delete_outline,
                                    color: badC(context)),
                                onPressed: () =>
                                    data.deleteNotice(n['id'].toString()),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}
