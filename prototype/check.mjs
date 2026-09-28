// Prüft Raster und Zeitlogik aller Sprachen und vergleicht Prototyp mit Swift.
// Aufruf: node prototype/check.mjs
import { createRequire } from "node:module";
import { execFileSync } from "node:child_process";
import { mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";

const require = createRequire(import.meta.url);
const { FACES, LANGS, phrase } = require("./faces.js");
const root = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const errors = [];
const fail = msg => errors.push(msg);

// 1. Raster: 10 Zeilen × 11 Buchstaben, Wörter und Zeichen passen hinein
for (const [name, f] of Object.entries(FACES)) {
  if (f.grid.length !== 10) fail(`${name}: ${f.grid.length} Zeilen statt 10`);
  f.grid.forEach((row, r) => {
    const n = [...row.normalize("NFC")].length;
    if (n !== 11) fail(`${name}: Zeile ${r} hat ${n} Buchstaben statt 11`);
  });
  for (const [w, [r, c, l]] of Object.entries(f.words))
    if (r < 0 || r > 9 || c < 0 || c + l > 11) fail(`${name}: Wort ${w} liegt außerhalb`);
  for (const mk of f.marks)
    if (!f.words[mk.word] || mk.afterCol < 0 || mk.afterCol > 9) fail(`${name}: Zeichen ${mk.glyph} ungültig`);
}

// 2. Jede Minute: Wörter vorhanden, in Lesereihenfolge, ohne Überlappung
const table = [];
for (const lang of Object.keys(LANGS)) {
  const f = FACES[LANGS[lang]];
  for (const intro of [true, false]) for (let h = 0; h < 24; h++) for (let m = 0; m < 60; m++) {
    const p = phrase(h, m, lang, intro);
    let last = -1;
    for (const w of p.words) {
      const pos = f.words[w];
      if (!pos) { fail(`${lang} ${h}:${m}: Wort ${w} fehlt im Raster`); continue; }
      const [r, c, l] = pos, start = r * 11 + c;
      if (start <= last) fail(`${lang} ${h}:${m}: ${w} steht vor dem vorigen Wort oder überlappt`);
      last = start + l - 1;
    }
    table.push(`time ${lang} ${intro ? 1 : 0} ${h}:${m} ${p.words.join(",")} ${p.dots}`);
  }
}

// 3. Beispiele zum Lesen
const say = (lang, h, m) => {
  const f = FACES[LANGS[lang]];
  return phrase(h, m, lang, true).words.map(w => {
    const [r, c, l] = f.words[w];
    return w === "OCLOCK" ? "O’CLOCK" : [...f.grid[r].normalize("NFC")].slice(c, c + l).join("");
  }).join(" ");
};
for (const lang of Object.keys(LANGS)) {
  console.log(`\n${lang}:`);
  for (let m = 0; m < 60; m += 5) console.log(`  3:${String(m).padStart(2, "0")}  ${say(lang, 15, m)}`);
  console.log(`  0:00  ${say(lang, 0, 0)}   ·  1:00  ${say(lang, 13, 0)}   ·  11:55  ${say(lang, 11, 55)}`);
}

// 4. Vergleich mit Swift (Sources/ClockFace.swift)
const js = [];
for (const [name, f] of Object.entries(FACES)) {
  f.grid.forEach(row => js.push(`grid ${name} ${row.normalize("NFC")}`));
  for (const w of Object.keys(f.words).sort((a, b) => a < b ? -1 : a > b ? 1 : 0))
    js.push(`word ${name} ${w} ${f.words[w].join(" ")}`);
  for (const mk of f.marks) js.push(`mark ${name} ${mk.glyph} ${mk.row} ${mk.afterCol} ${mk.word}`);
}
js.push(...table);
mkdirSync(path.join(root, "build"), { recursive: true });
const bin = path.join(root, "build", "phrases");
execFileSync("xcrun", ["swiftc", "-O", "-module-name", "Phrases",
  path.join(root, "Sources/ClockFace.swift"), path.join(root, "Tools/Phrases/main.swift"), "-o", bin]);
const swift = execFileSync(bin, { encoding: "utf8", maxBuffer: 64 << 20 }).trim().split("\n");
const n = Math.max(js.length, swift.length);
let diffs = 0;
for (let i = 0; i < n && diffs < 10; i++)
  if (js[i] !== swift[i]) { fail(`Swift ≠ Prototyp:\n    JS:    ${js[i]}\n    Swift: ${swift[i]}`); diffs++; }

console.log();
if (errors.length) { console.log(errors.map(e => "✗ " + e).join("\n")); process.exit(1); }
console.log(`✓ ${table.length} Zeitansagen geprüft, Swift und Prototyp stimmen überein`);
