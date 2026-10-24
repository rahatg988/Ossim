part of 'screens.dart';

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
