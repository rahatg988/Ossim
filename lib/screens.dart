// ---------------------------------------------------------------
// screens.dart  (lib/screens.dart নামে নতুন ফাইল)
// নতুন প্রফেশনাল ডিজাইন: ডিজাইন-কিট + সব স্ক্রিন
// ---------------------------------------------------------------
import 'package:flutter/material.dart';

import 'extras.dart';
import 'main.dart';

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

// ---------------------------------------------------------------
// ম্যানেজারের হোম: নিচে ৪টা ট্যাব
// ---------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgC(context),
      body: SafeArea(
        child: IndexedStack(
          index: tab,
          children: [
            _DashboardTab(onGo: (i) => setState(() => tab = i)),
            const _AttendanceTab(),
            const _StudentsTab(),
            const _SettingsTab(),
          ],
        ),
      ),
      floatingActionButton: tab == 2
          ? FloatingActionButton.extended(
              onPressed: () => showAddStudentDialog(context),
              backgroundColor: K.pri,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add),
              label: const Text('স্টুডেন্ট'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'হোম'),
          NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check),
              label: 'খাবার'),
          NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups),
              label: 'শিক্ষার্থী'),
          NavigationDestination(
              icon: Icon(Icons.tune),
              selectedIcon: Icon(Icons.tune),
              label: 'সেটিংস'),
        ],
      ),
    );
  }
}

// ---- হোম ট্যাব: ড্যাশবোর্ড ----
class _DashboardTab extends StatelessWidget {
  final void Function(int) onGo;
  const _DashboardTab({required this.onGo});

  Widget _kpi(BuildContext c, String value, String label, {Color? color}) {
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: color ?? inkC(c))),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: mutC(c))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([data, extra]),
      builder: (context, _) {
        final st = data.students;
        final today = todayDate();
        final onCount = st.where((s) => activeLines(s).isNotEmpty).length;
        final lunch = st.where((s) => hasSlot(s, 'l', today)).length;
        double due = 0;
        int dues = 0;
        for (final s in st) {
          final b = balOf(s);
          if (b < 0) {
            due += -b;
            dues++;
          }
        }
        final p = periodInfo();
        double depSum = 0;
        double costSum = 0;
        double poSum = 0;
        for (final s in st) {
          depSum += numOf(s['pd']);
          costSum += numOf(s['pc']);
          poSum += numOf(s['po']);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            pageHeader(
              context,
              'ম্যানেজার ড্যাশবোর্ড',
              sub:
                  '${dateLabel(today)}${data.managerRoom.isEmpty ? '' : ' · রুম ${data.managerRoom}'}',
              actions: [
                bellBtn(context, manager: true),
                moreMenu(context),
              ],
            ),
            Row(
              children: [
                Expanded(
                    child: _kpi(context,
                        '${bnDigits('$onCount')}/${bnDigits('${st.length}')}',
                        'মিল চালু')),
                const SizedBox(width: 8),
                Expanded(child: _kpi(context, bnDigits('$lunch'), 'আজ দুপুরে')),
                const SizedBox(width: 8),
                Expanded(
                    child: _kpi(context, money(due), 'মোট বকেয়া',
                        color: badC(context))),
              ],
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('আজকের খাবার',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: inkC(context))),
                  const SizedBox(height: 8),
                  for (final k in ['l', 'd', 'b'])
                    Builder(builder: (context) {
                      final list =
                          st.where((s) => hasSlot(s, k, today)).toList();
                      final ate = list.where((s) => ateSlot(s, k, today)).length;
                      return InkWell(
                        onTap: () => onGo(1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                            k == 'b'
                                                ? 'আজ সকাল'
                                                : slotName(k),
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: inkC(context))),
                                        Text(
                                            '${bnDigits('$ate')}/${bnDigits('${list.length}')} জন',
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: mutC(context))),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: LinearProgressIndicator(
                                        value: list.isEmpty
                                            ? 0
                                            : ate / list.length,
                                        minHeight: 6,
                                        backgroundColor: lnC(context),
                                        color: priC(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.chevron_right,
                                  color: mutC(context)),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
            AppCard(
              borderColor: p.over ? warnC(context) : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'চলমান ${bnDigits('${p.days}')} দিনের হিসাব',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: inkC(context))),
                            Text(
                                '${shortDate(p.start)} – ${shortDate(p.end)} · ${p.over ? '${bnDigits('${p.days}')} দিন পূর্ণ' : 'দিন ${bnDigits('${p.dn}')}/${bnDigits('${p.days}')}'}',
                                style: TextStyle(
                                    fontSize: 13, color: mutC(context))),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: K.warn,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => confirmNewPeriod(context),
                        child: const Text('নতুন হিসাব'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  segBar(p.days, p.over ? p.days : p.dn, priC(context),
                      lnC(context)),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'এ পর্যন্ত: ${bnDigits('$onCount')} জন মিল চালু · জমা ${money(depSum)} · খরচ ${money(costSum)}${poSum > 0 ? ' · ফেরত ${money(poSum)}' : ''}',
                      style: TextStyle(fontSize: 12, color: mutC(context)),
                    ),
                  ),
                  if (p.over)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                          '${bnDigits('${p.days}')} দিন পূর্ণ হয়েছে। নতুন হিসাব শুরু করুন।',
                          style: TextStyle(
                              fontSize: 12, color: warnC(context))),
                    ),
                ],
              ),
            ),
            if (dues > 0)
              AppCard(
                child: Row(
                  children: [
                    iconTile(context, Icons.warning_amber_rounded,
                        bg: badTint(context), fg: badC(context)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${bnDigits('$dues')} জনের বকেয়া আছে',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: inkC(context))),
                          Text('মোট ${money(due)}',
                              style: TextStyle(
                                  fontSize: 13, color: mutC(context))),
                        ],
                      ),
                    ),
                    TextButton(
                        onPressed: () => onGo(2), child: const Text('দেখুন')),
                  ],
                ),
              ),
            AppCard(
              borderColor: extra.mealOpen ? okC(context) : null,
              color: extra.mealOpen ? okTint(context) : null,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('শিক্ষার্থীদের মিল চালুর অনুমতি',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: inkC(context))),
                        Text(
                            extra.mealOpen
                                ? 'চালু · শিক্ষার্থীরা নিজে মিল চালু করতে পারছে'
                                : 'বন্ধ',
                            style: TextStyle(
                                fontSize: 13, color: mutC(context))),
                      ],
                    ),
                  ),
                  Switch(
                    value: extra.mealOpen,
                    activeColor: Colors.white,
                    activeTrackColor: okC(context),
                    onChanged: (v) {
                      extra.setOpen(v);
                      messengerKey.currentState?.showSnackBar(SnackBar(
                          content: Text(v
                              ? 'সবাইকে নোটিফিকেশন পাঠানো হয়েছে'
                              : 'অনুমতি বন্ধ করা হয়েছে')));
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---- খাবার ট্যাব: খাবার চিহ্নিত করা ----
class _AttendanceTab extends StatefulWidget {
  const _AttendanceTab();

  @override
  State<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<_AttendanceTab> {
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
      listenable: Listenable.merge([data, extra]),
      builder: (context, _) {
        final all = data.students;
        final on = all.where(_hasMeal).toList();
        final off = all.where((s) => !_hasMeal(s)).toList();
        final nq = normSearch(q);
        final shown = nq.isEmpty
            ? on
            : on
                .where((s) =>
                    normSearch(s['name'].toString()).contains(nq) ||
                    normSearch(noOf(s).toString()).contains(nq))
                .toList();
        final ateCount = on.where(_ate).length;
        final lastDay = extra.periodDays - 1;
        final canPrev = cycle.isAfter(addDays(today, -1));
        final canNext = cycle.isBefore(addDays(today, lastDay));
        final mealDate = slot == 2 ? addDays(cycle, 1) : cycle;
        final timeKey = ['l', 'd', 'b'][slot];

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            pageHeader(
              context,
              'খাবার চিহ্নিত করুন',
              sub: 'মিল দিন: ${dateLabel(cycle)}',
              actions: [
                pill(context,
                    '${bnDigits('$ateCount')}/${bnDigits('${on.length}')} খেয়েছে',
                    kind: 'ok'),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: canPrev
                      ? () => setState(() => cycle = addDays(cycle, -1))
                      : null,
                ),
                Expanded(
                  child: Center(
                    child: Text('দুপুর থেকে পরদিন সকাল পর্যন্ত',
                        style:
                            TextStyle(fontSize: 12, color: mutC(context))),
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
            segControl(
              context,
              const ['দুপুর', 'রাত', 'পরদিন সকাল'],
              slot,
              (i) => setState(() => slot = i),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'খাবারের তারিখ: ${dateLabel(mealDate)} · সময়: ${fmtRange(timeKey)}',
                style: TextStyle(fontSize: 12, color: mutC(context)),
              ),
            ),
            searchField(context, 'নাম বা নম্বর দিয়ে খুঁজুন',
                (v) => setState(() => q = v),
                controller: qC),
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
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: on.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(18),
                      child: Center(
                          child: Text('এই বেলায় কারও মিল চালু নেই।',
                              style: TextStyle(color: mutC(context)))),
                    )
                  : shown.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(18),
                          child: Center(
                              child: Text('কাউকে খুঁজে পাওয়া যায়নি।',
                                  style: TextStyle(color: mutC(context)))),
                        )
                      : Column(
                          children: [
                            for (int i = 0; i < shown.length; i++) ...[
                              if (i > 0)
                                Divider(height: 1, color: lnC(context)),
                              InkWell(
                                onTap: () =>
                                    _setAte(shown[i], !_ate(shown[i])),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    children: [
                                      avatar(context, bnDigits('${noOf(shown[i])}')),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(shown[i]['name'].toString(),
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: inkC(context))),
                                            Text('রুম: ${shown[i]['room']}',
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: mutC(context))),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: _ate(shown[i])
                                              ? okC(context)
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(9),
                                          border: Border.all(
                                              color: _ate(shown[i])
                                                  ? okC(context)
                                                  : lnC(context),
                                              width: 2),
                                        ),
                                        child: _ate(shown[i])
                                            ? const Icon(Icons.check,
                                                size: 18, color: Colors.white)
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
            ),
            if (off.isNotEmpty && nq.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'এই বেলায় মিল বন্ধ: ${off.map((s) => s['name']).join(', ')}',
                  style: TextStyle(fontSize: 12, color: mutC(context)),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ---- শিক্ষার্থী ট্যাব: কার্ড / টেবিল ----
class _StudentsTab extends StatefulWidget {
  const _StudentsTab();

  @override
  State<_StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<_StudentsTab> {
  String q = '';
  bool table = false;
  int? exp;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([data, extra]),
      builder: (context, _) {
        final nq = normSearch(q);
        final list = data.students.where((s) {
          if (nq.isEmpty) return true;
          return normSearch(s['name'].toString()).contains(nq) ||
              normSearch(noOf(s).toString()).contains(nq) ||
              normSearch(s['room'].toString()).contains(nq);
        }).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            pageHeader(context, 'শিক্ষার্থী',
                sub: 'মোট ${bnDigits('${data.students.length}')} জন'),
            segControl(context, const ['কার্ড', 'টেবিল'], table ? 1 : 0,
                (i) => setState(() => table = i == 1)),
            if (table)
              const StudentTable()
            else ...[
              searchField(context, 'স্টুডেন্ট নম্বর, নাম বা রুম দিয়ে খুঁজুন...',
                  (v) => setState(() => q = v)),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Center(
                    child: Text(
                      data.students.isEmpty
                          ? 'কোনো স্টুডেন্ট নেই।\nনিচের "স্টুডেন্ট" বাটন চাপুন।'
                          : 'কাউকে খুঁজে পাওয়া যায়নি।',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: mutC(context)),
                    ),
                  ),
                )
              else
                AppCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      for (int i = 0; i < list.length; i++) ...[
                        if (i > 0) Divider(height: 1, color: lnC(context)),
                        _studentRow(context, list[i]),
                      ],
                    ],
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _studentRow(BuildContext context, Map<String, dynamic> s) {
    final b = balOf(s);
    final d = activeDays(s);
    final open = exp == s['id'];
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => exp = open ? null : s['id'] as int),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                avatar(context, bnDigits('${noOf(s)}')),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['name'].toString(),
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: inkC(context))),
                      Text('রুম ${s['room']} · ${s['year']}',
                          style:
                              TextStyle(fontSize: 13, color: mutC(context))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(money(b),
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: b >= 0 ? okC(context) : badC(context))),
                    const SizedBox(height: 2),
                    pill(
                        context,
                        d > 0
                            ? 'মিল ${bnDigits('$d')} দিন'
                            : (activeLines(s).isNotEmpty
                                ? 'মিল চালু'
                                : 'মিল বন্ধ'),
                        kind: activeLines(s).isNotEmpty ? 'pri' : 'mut'),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (open)
          Padding(
            padding: const EdgeInsets.only(left: 52, bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => showDepositDialog(context, s),
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: const Text('জমা দিন'),
                ),
                if (b > 0)
                  OutlinedButton.icon(
                    onPressed: () => showPayoutDialog(context, s),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('পাওনা মেটান'),
                  ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: K.warn, foregroundColor: Colors.white),
                  onPressed: () => showMealDialog(context, s),
                  icon: const Icon(Icons.restaurant, size: 18),
                  label: const Text('মিল চালু/বন্ধ'),
                ),
                OutlinedButton.icon(
                  onPressed: () => showRenameDialog(context, s),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('নাম/নম্বর'),
                ),
                IconButton(
                  tooltip: 'পিন রিসেট',
                  icon: Icon(Icons.lock_reset, color: priC(context)),
                  onPressed: () => showResetPinDialog(context, s),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: badC(context)),
                  onPressed: () => confirmDeleteStudent(context, s),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---- সেটিংস ট্যাব ----
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  Widget _row(BuildContext c, String title,
      {String? value, VoidCallback? onTap, Widget? trailing, bool last = false}) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              children: [
                Expanded(
                    child: Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w500, color: inkC(c)))),
                if (value != null)
                  Text(value,
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: mutC(c))),
                if (trailing != null) trailing,
                if (onTap != null && trailing == null)
                  Icon(Icons.chevron_right, color: mutC(c), size: 20),
              ],
            ),
          ),
        ),
        if (!last) Divider(height: 1, color: lnC(c)),
      ],
    );
  }

  Widget _group(BuildContext c, List<Widget> rows) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        margin: const EdgeInsets.only(bottom: 4),
        child: Column(children: rows),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([data, extra]),
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            pageHeader(context, 'সেটিংস'),
            sectionLabel(context, 'ম্যানেজার'),
            _group(context, [
              _row(context, 'ম্যানেজারের রুম',
                  value: data.managerRoom.isEmpty
                      ? 'বেছে নিন'
                      : 'রুম ${data.managerRoom}',
                  onTap: () => pickManagerRoom(context)),
              _row(context, 'ম্যানেজার পিন পরিবর্তন',
                  onTap: () => changeManagerPin(context), last: true),
            ]),
            sectionLabel(context, 'খাবারের সময়'),
            _group(context, [
              for (final k in ['b', 'l', 'd'])
                _row(context, slotName(k),
                    value: fmtRange(k),
                    onTap: () => editSchedule(context, k, slotName(k)),
                    last: k == 'd'),
            ]),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  data.schedule = copyDefaultSchedule();
                  data.saveConfig();
                },
                child: const Text('সময় ডিফল্টে ফিরুন'),
              ),
            ),
            sectionLabel(context, 'হিসাবের মেয়াদ'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('কত দিন পরপর হিসাব শেষ করে নতুন হিসাব শুরু হবে',
                      style: TextStyle(fontSize: 13, color: mutC(context))),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: extra.periodDays > 1
                            ? () => extra.setPeriodDays(extra.periodDays - 1)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Expanded(
                        child: Center(
                          child: Text('${bnDigits('${extra.periodDays}')} দিন',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: inkC(context))),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: extra.periodDays < 15
                            ? () => extra.setPeriodDays(extra.periodDays + 1)
                            : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text('১ থেকে ১৫ দিনের মধ্যে যেকোনো',
                            style: TextStyle(
                                fontSize: 12, color: mutC(context))),
                      ),
                      TextButton(
                        onPressed: () => extra.setPeriodDays(4),
                        child: const Text('ডিফল্ট (৪ দিন)'),
                      ),
                    ],
                  ),
                  Text(
                      'মিল চালুর সময় আজ থেকে পরের ${bnDigits('${extra.periodDays}')} দিনের বেলা বাছা যাবে।',
                      style: TextStyle(fontSize: 12, color: mutC(context))),
                ],
              ),
            ),
            sectionLabel(context, 'খাবারের মূল্য (প্রতি দিন)'),
            _group(context, [
              for (int i = 0; i < ExtraData.kPriceNames.length; i++)
                _row(context, ExtraData.kPriceNames[i][1],
                    value:
                        '৳ ${bnDigits('${extra.prices[ExtraData.kPriceNames[i][0]]}')}',
                    onTap: () =>
                        showPriceDialog(context, ExtraData.kPriceNames[i]),
                    last: i == ExtraData.kPriceNames.length - 1),
            ]),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                        'নতুন দাম শুধু এরপর যোগ হওয়া মিলে লাগবে, আগে যোগ করা মিলের খরচ বদলাবে না।',
                        style: TextStyle(fontSize: 12, color: mutC(context))),
                  ),
                  TextButton(
                    onPressed: extra.resetPrices,
                    child: const Text('ডিফল্ট দাম'),
                  ),
                ],
              ),
            ),
            sectionLabel(context, 'হল ও ইতিহাস'),
            _group(context, [
              _row(context, data.hallName.isEmpty ? 'হল' : data.hallName,
                  value: 'বর্তমান হল'),
              _row(context, 'ইতিহাস (মোট হিসাব)',
                  value: '${bnDigits('${data.periods.length}')}টি',
                  onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PeriodHistoryScreen()),
                      )),
              _row(context, 'হল বদলান',
                  onTap: () => leaveToPicker(context), last: true),
            ]),
            sectionLabel(context, 'অ্যাপ'),
            _group(context, [
              _row(context, 'ডার্ক মোড',
                  trailing: Switch(
                    value: isDark(context),
                    activeColor: Colors.white,
                    activeTrackColor: okC(context),
                    onChanged: (v) => data.setDark(v),
                  )),
              _row(context, 'লগআউট',
                  onTap: () => goLogin(context), last: true),
            ]),
          ],
        );
      },
    );
  }
}

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
                searchFi