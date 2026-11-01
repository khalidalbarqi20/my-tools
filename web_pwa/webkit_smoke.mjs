// فحص سريع للنسخة الويب على محرك WebKit (محرك Safari على آيفون) داخل GitHub Actions.
// بديل مجاني وغير كامل عن آيفون حقيقي: يتأكد أن التطبيق يفتح، وأن شريط تثبيت الآيفون يظهر، ولا توجد أخطاء صفحة.
import { webkit, devices } from 'playwright';

const base = 'http://localhost:8080/my-tools/';
const fails = [];
const errs = [];

const br = await webkit.launch();
const ctx = await br.newContext({ ...devices['iPhone 13'], locale: 'ar-SA' });
const page = await ctx.newPage();
page.on('pageerror', (e) => errs.push(String((e && e.message) || e)));

await page.goto(base, { waitUntil: 'load', timeout: 90000 });
try {
  await page.waitForSelector('flt-glass-pane, flutter-view', { timeout: 90000 });
} catch (_) {
  fails.push('التطبيق لم يظهر في WebKit (لا يوجد عنصر Flutter)');
}
await page.waitForTimeout(3000);
await page.screenshot({ path: 'home.png' });

const g = await page.evaluate(() => ({
  ua: navigator.userAgent,
  media: !!window.mtMedia,
  html: !!window.mtHtml,
}));
console.log(JSON.stringify(g));
if (!g.media) fails.push('محرك الفيديو (mtMedia) لم يُحمَّل');
if (!g.html) fails.push('مشغّل HTML (mtHtml) لم يُحمَّل');

// نفعّل شجرة الوصول ليظهر نص الواجهة للفحص
try {
  await page.locator('flt-semantics-placeholder').first().click({ force: true, timeout: 5000 });
} catch (_) {}
await page.waitForTimeout(1500);
const texts = () =>
  page.evaluate(() =>
    [...document.querySelectorAll('flt-semantics')]
      .map((e) => (e.getAttribute('aria-label') || e.textContent || '').trim())
      .filter(Boolean)
      .join(' | '));

let t = await texts();
console.log(t.slice(0, 600));
if (!t.includes('إضافة إلى الشاشة الرئيسية')) fails.push('شريط تثبيت الآيفون لم يظهر');

await page.mouse.move(195, 500);
await page.mouse.wheel(0, 5000);
await page.waitForTimeout(1500);
await page.screenshot({ path: 'home-bottom.png' });
t = await texts();
if (!t.includes('أدوات غير متاحة')) {
  console.log('::warning title=WebKit smoke::قائمة «أدوات غير متاحة على جهازك» لم تظهر أسفل الرئيسية');
}

if (errs.length) fails.push('أخطاء في الصفحة: ' + errs.slice(0, 3).join(' ; '));
await br.close();

if (fails.length) {
  for (const f of fails) console.log('::error title=WebKit smoke::' + f.replace(/\n/g, ' '));
  process.exit(1);
}
console.log('WebKit smoke OK');
