import { chromium } from 'playwright';

const browser = await chromium.launch({ headless: false });
const page = await browser.newPage();

// Collect console messages
const consoleMessages = [];
page.on('console', msg => {
  consoleMessages.push({ type: msg.type(), text: msg.text() });
});

page.on('pageerror', err => {
  consoleMessages.push({ type: 'pageerror', text: err.message });
});

await page.goto('http://localhost:5121', { waitUntil: 'networkidle' });
await page.waitForTimeout(2000);

// Get viewport size
const viewport = page.viewportSize();
console.log('Viewport:', JSON.stringify(viewport));

// Find canvas element
const canvas = await page.$('canvas');
const box = canvas ? await canvas.boundingBox() : null;
console.log('Canvas bounding box:', JSON.stringify(box));

if (!box) {
  console.log('No canvas found, using viewport center area');
}

const cx = box ? box.x + box.width / 2 : viewport.width / 2;
const cy = box ? box.y + box.height / 2 : viewport.height / 2;
const left = box ? box.x + 10 : 50;
const right = box ? box.x + box.width - 10 : viewport.width - 50;
const midY = box ? box.y + box.height / 2 : viewport.height / 2;

// Step 1: Move mouse slowly from left to right across canvas
console.log('Moving mouse from left to right...');
const steps = 40;
for (let i = 0; i <= steps; i++) {
  const x = left + (right - left) * (i / steps);
  await page.mouse.move(x, midY);
  await page.waitForTimeout(50);
}

await page.waitForTimeout(500);

// Step 2: Move mouse in a circle
console.log('Moving mouse in a circle...');
const radius = Math.min(box ? box.width : viewport.width, box ? box.height : viewport.height) * 0.3;
const circleSteps = 60;
for (let i = 0; i <= circleSteps; i++) {
  const angle = (i / circleSteps) * 2 * Math.PI;
  const x = cx + radius * Math.cos(angle);
  const y = cy + radius * Math.sin(angle);
  await page.mouse.move(x, y);
  await page.waitForTimeout(40);
}

// Move to center for screenshot
await page.mouse.move(cx, cy);
await page.waitForTimeout(1000);

// Take screenshot
await page.screenshot({ path: '/Users/diederick/Three.js/screenshot-hover.png', fullPage: false });
console.log('Screenshot saved.');

// Print console messages
console.log('\n=== CONSOLE MESSAGES ===');
for (const msg of consoleMessages) {
  console.log(`[${msg.type}] ${msg.text}`);
}
console.log('=== END CONSOLE MESSAGES ===');

await browser.close();
