# يضيف سطر «عملياتي السابقة» في أعلى صفحة الإعدادات (يشتغل داخل GitHub Actions فقط).
# إن لم يجد المكان المناسب لا يغيّر شيئًا ويكتب تحذيرًا.
import glob, os, re, sys

TARGET = 'lib/features/history/history_page.dart'
cands = [f for f in glob.glob('lib/**/*.dart', recursive=True)
         if re.search(r'settings', os.path.basename(f), re.I)]
cands.sort(key=lambda f: (0 if re.search(r'settings_page', f, re.I) else 1, f))

def warn(m):
    print('::warning title=settings patch::' + m)

if not cands:
    warn('لم أجد ملف الإعدادات في lib')
    sys.exit(0)

for f in cands:
    s = open(f, encoding='utf-8').read()
    if 'OpsHistoryTile' in s:
        print('already patched:', f)
        sys.exit(0)
    if 'extends StatelessWidget' not in s and 'extends State<' not in s:
        continue
    m = re.search(r'(ListView|Column)\(', s)
    if not m:
        continue
    c = re.search(r'children:\s*(?:const\s*)?(?:<Widget>)?\[', s[m.end():m.end() + 1500])
    if not c:
        continue
    pos = m.end() + c.end()
    s2 = s[:pos] + '\n          const OpsHistoryTile(),' + s[pos:]
    rel = os.path.relpath(TARGET, os.path.dirname(f)).replace(os.sep, '/')
    imp = "import '%s';\n" % rel
    last = list(re.finditer(r'^import .*;\s*$', s2, re.M))
    if last:
        e = last[-1].end()
        s2 = s2[:e] + '\n' + imp.rstrip('\n') + s2[e:]
    else:
        s2 = imp + s2
    open(f + '.orig', 'w', encoding='utf-8').write(s)
    open(f, 'w', encoding='utf-8').write(s2)
    open('/tmp/patched_file', 'w').write(f)
    print('patched:', f)
    sys.exit(0)

warn('لم أجد مكانًا مناسبًا في ملفات الإعدادات: ' + ', '.join(cands))
