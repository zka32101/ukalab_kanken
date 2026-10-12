// 解説読み物（Flutter Web）を Playwright で操作して、入口 → 一覧 → 詳細を確認する。
//   node check.js [スクリーンショットの保存先]
//   E2E_READING=入口の文言|読み物の題名(一部)|最初の節の見出し
// Flutter Web は文字をキャンバスに描くので、semantics を有効にして文字とボタンを拾う。
const { chromium } = require('playwright');

const shots = process.argv[2] || '.';
const reading = (process.env.E2E_READING || '').split('|').filter(Boolean);
if (reading.length !== 3) throw new Error('E2E_READING は「入口|題名|見出し」の3つ');
const failures = [];
function check(name, ok) {
  console.log(`${ok ? 'ok  ' : 'FAIL'} ${name}`);
  if (!ok) failures.push(name);
}

(async () => {
  const browser = await chromium.launch({ executablePath: process.env.CHROMIUM_PATH || undefined, args: ['--no-sandbox'] });
  const page = await browser.newPage({ locale: 'ja-JP', viewport: { width: 420, height: 1000 } });
  const errors = [];
  page.on('pageerror', e => errors.push(String(e)));
  const text = async () =>
    page.evaluate(() =>
      [...document.querySelectorAll('flt-semantics')]
        .map(e => `${e.innerText || ''}\n${e.getAttribute('aria-label') || ''}`)
        .join('\n'));
  const waitText = async (s, timeout = 8000) => {
    const end = Date.now() + timeout;
    while (Date.now() < end) {
      if ((await text()).includes(s)) return true;
      await page.waitForTimeout(200);
    }
    return false;
  };
  const click = async (name) => {
    await page.getByRole('button', { name, exact: false }).first().click({ force: true });
    await page.waitForTimeout(700);
  };

  await page.goto('http://localhost:8099/');
  await page.waitForSelector('flt-semantics-placeholder', { state: 'attached', timeout: 90000 });
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder').click());
  await page.waitForTimeout(1500);

  const [entry, title, heading] = reading;
  check(`学習メニューに「${entry}」`, await waitText(entry, 20000));
  await click(entry);
  check(`読み物の一覧に「${title}」`, await waitText(title));
  await page.screenshot({ path: `${shots}/reading-list.png` });
  await click(title);
  check(`読み物を開くと節「${heading}」が出る`, await waitText(heading));
  await page.screenshot({ path: `${shots}/reading-detail.png` });

  check('ページエラーなし', errors.length === 0);
  if (errors.length) console.log(errors.join('\n'));
  await browser.close();
  if (failures.length) {
    console.log(`\n${failures.length} 件失敗`);
    process.exitCode = 1;
  }
})();
