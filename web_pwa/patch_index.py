# يعدّل web/index.html الناتج من flutter create: عنوان عربي، لون الشريط، وتسجيل SW احتياطي.
import re, sys
p = 'web/index.html'
h = open(p, encoding='utf-8').read()
h = re.sub(r'<title>.*?</title>', '<title>أدواتي اليومية</title>', h, count=1, flags=re.S)
h = re.sub(r'(<meta name="apple-mobile-web-app-title" content=")[^"]*(")', r'\1أدواتي\2', h, count=1)
h = re.sub(r'(<meta name="description" content=")[^"]*(")', r'\1كل أدواتك اليومية في مكان واحد\2', h, count=1)
add = ''
if 'name="theme-color"' not in h:
    add += '  <meta name="theme-color" content="#0F1814">\n'
if 'rel="manifest"' not in h:
    add += '  <link rel="manifest" href="manifest.json">\n'
if 'apple-touch-icon' not in h:
    add += '  <link rel="apple-touch-icon" href="icons/Icon-192.png">\n'
if add:
    h = h.replace('</head>', add + '</head>', 1)
if 'mt_bg.js' not in h:
    h = h.replace('</head>', '  <script type="module" src="mt_bg.js"></script>\n</head>', 1)
if 'mt_media.js' not in h:
    h = h.replace('</head>', '  <script type="module" src="mt_media.js"></script>\n</head>', 1)
if 'my_tools_sw.js' not in h:
    sw = """  <script>
    // نسجّل خدمة العمل الخاصة بنا (شرط التثبيت). نطاقها /my-tools/ فقط.
    window.addEventListener('load', function () {
      if (!('serviceWorker' in navigator)) return;
      setTimeout(async function () {
        try {
          // نسجّل خدمتنا دائمًا: لها معالج fetch (شرط التثبيت)، وخدمة Flutter قد تكون بلا معالج فيرفض Chrome التثبيت.
          await navigator.serviceWorker.register('my_tools_sw.js', { scope: './' });
        } catch (e) {}
      }, 3000);
    });
  </script>
"""
    h = h.replace('</body>', sw + '</body>', 1)
open(p, 'w', encoding='utf-8').write(h)
print('index.html patched')
