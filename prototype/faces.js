/* Letter grids & time logic per language – identical in Sources/ClockFace.swift.
   Loaded by the prototype (index.html) and by the check script (check.mjs). */

// Hour words in the English grid (same for British and American)
const EN_HOURS = { H1:[4,0,3], H2:[4,4,3], H6:[4,8,3], H3:[5,0,5], H7:[5,6,5],
  H4:[6,0,4], H11:[6,5,6], H5:[7,0,4], H0:[7,5,6], H8:[8,0,5], H10:[8,6,3],
  H9:[9,0,4], OCLOCK:[9,5,6] };
const EN_HOUR_ROWS = ["ONEXTWOVSIX","THREEKSEVEN","FOURBELEVEN","FIVEMTWELVE","EIGHTRTENPU","NINEWOCLOCK"];
const OCLOCK_MARK = { glyph:"’", row:9, afterCol:5, word:"OCLOCK" };

const FACES = {
  de: {
    grid: ["ESRISTLZEHN","FÜNFZWANZIG","DREIVIERTEL","NACHQTVORMJ","HALBXSIEBEN",
           "ZWÖLFKEINSA","ZWEIDREIELF","VIERYFÜNFOT","SECHSRACHTN","ZEHNEUNJUHR"],
    words: { ES:[0,0,2], IST:[0,3,3], M5:[1,0,4], M10:[0,7,4], M20:[1,4,7],
      DV:[2,0,11], V:[2,4,7], NACH:[3,0,4], VOR:[3,6,3], HALB:[4,0,4],
      H7:[4,5,6], H0:[5,0,5], EIN:[5,6,3], H1:[5,6,4], H2:[6,0,4], H3:[6,4,4],
      H11:[6,8,3], H4:[7,0,4], H5:[7,5,4], H6:[8,0,5], H8:[8,6,4], H10:[9,0,4],
      H9:[9,3,4], UHR:[9,8,3] },
    marks: [],
  },
  ch: {
    grid: ["ESKISCHAFÜF","VIERTELSZÄH","ZWÄNZGDABLN","VORKHALBIJE","EISRZWÖIDRÜ",
           "VIERIKFÜFIS","SÄCHSISIBNI","ACHTIENÜNIX","ZÄNIKELFIRS","ZWÖLFIKSTOQ"],
    words: { ES:[0,0,2], ISCH:[0,3,4], M5:[0,8,3], V:[1,0,7], M10:[1,8,3],
      M20:[2,0,6], AB:[2,7,2], VOR:[3,0,3], HALBI:[3,4,5],
      H1:[4,0,3], H2:[4,4,4], H3:[4,8,3], H4:[5,0,5], H5:[5,6,4],
      H6:[6,0,6], H7:[6,6,5], H8:[7,0,5], H9:[7,6,4], H10:[8,0,4], H11:[8,5,4], H0:[9,0,6] },
    marks: [],
  },
  en: {
    grid: ["ITLISQHALFP","AZQUARTERCK","TWENTYXFIVE","TENRPASTBTO", ...EN_HOUR_ROWS],
    words: { IT:[0,0,2], IS:[0,3,2], HALF:[0,6,4], A:[1,0,1], QUARTER:[1,2,7],
      M20:[2,0,6], M5:[2,7,4], M10:[3,0,3], PAST:[3,4,4], TO:[3,9,2], ...EN_HOURS },
    marks: [OCLOCK_MARK],
  },
  us: {
    grid: ["ITLISZHALFA","QUARTERPAST","TWENTYXFIVE","TENKAFTERTO", ...EN_HOUR_ROWS],
    words: { IT:[0,0,2], IS:[0,3,2], HALF:[0,6,4], A:[0,10,1], QUARTER:[1,0,7], PAST:[1,7,4],
      M20:[2,0,6], M5:[2,7,4], M10:[3,0,3], AFTER:[3,4,5], TO:[3,9,2], ...EN_HOURS },
    marks: [OCLOCK_MARK],
  },
  fr: {
    grid: ["ILKESTRDEUX","QUATRETROIS","UNECINQSEPT","HUITNEUFSIX","MIDIXMINUIT",
           "ONZEPHEURES","MOINSVLEDIX","ETSQUARTFLN","VINGTCINQHB","ZDEMIEWKLPT"],
    words: { IL:[0,0,2], EST:[0,3,3], H2:[0,7,4], H4:[1,0,6], H3:[1,6,5],
      H1:[2,0,3], H5:[2,3,4], H7:[2,7,4], H8:[3,0,4], H9:[3,4,4], H6:[3,8,3],
      MIDI:[4,0,4], H10:[4,2,3], MINUIT:[4,5,6], H11:[5,0,4], HEURE:[5,5,5], HEURES:[5,5,6],
      MOINS:[6,0,5], LE:[6,6,2], M10:[6,8,3], ET:[7,0,2], QUART:[7,3,5],
      M20:[8,0,5], M5:[8,5,4], M25:[8,0,9], DEMI:[9,1,4], DEMIE:[9,1,5] },
    // hyphen in VINGT-CINQ
    marks: [{ glyph:"-", row:8, afterCol:4, word:"M25" }],
  },
  it: {
    grid: ["SONORLEBSEI","ÈPLUNASETTE","QUATTROOTTO","CINQUEDIECI","UNDICINOVEK",
           "DODICIDUEFG","TREKEMENOZS","UNRQUARTOFT","VENTICINQUE","MEZZAPDIECI"],
    words: { SONO:[0,0,4], LE:[0,5,2], H6:[0,8,3], "È":[1,0,1], H1:[1,2,4], H7:[1,6,5],
      H4:[2,0,7], H8:[2,7,4], H5:[3,0,6], H10:[3,6,5], H11:[4,0,6], H9:[4,6,4],
      H0:[5,0,6], H2:[5,6,3], H3:[6,0,3], E:[6,4,1], MENO:[6,5,4],
      UN:[7,0,2], QUARTO:[7,3,6], M20:[8,0,5], M5:[8,5,6], M25:[8,0,11],
      MEZZA:[9,0,5], M10:[9,6,5] },
    // apostrophe in L'UNA
    marks: [{ glyph:"’", row:1, afterCol:2, word:"H1" }],
  },
  es: {
    grid: ["ESONRLASFKT","UNADOSCINCO","CUATROSIETE","NUEVEPTRESG","OCHONCEDIEZ",
           "SEISRDOCEBU","YMENOSKDIEZ","VEINTICINCO","CUARTOMEDIA","VEINTEHPXLS"],
    words: { ES:[0,0,2], SON:[0,1,3], LA:[0,5,2], LAS:[0,5,3],
      H1:[1,0,3], H2:[1,3,3], H5:[1,6,5], H4:[2,0,6], H7:[2,6,5], H9:[3,0,5], H3:[3,6,4],
      H8:[4,0,4], H11:[4,3,4], H10:[4,7,4], H6:[5,0,4], H0:[5,5,4],
      Y:[6,0,1], MENOS:[6,1,5], M10:[6,7,4], M25:[7,0,11], M5:[7,6,5],
      CUARTO:[8,0,6], MEDIA:[8,6,5], M20:[9,0,6] },
    marks: [],
  },
};

/* language -> grid */
const LANGS = { de:"de", deCH:"ch", deSouth:"de", en:"en", us:"us", es:"es", fr:"fr", it:"it" };

/* Time phrase: intro (optional) and words */
function phrase(h24, m, lang, intro){
  const m5 = Math.floor(m/5)*5, h = h24%12, n = (h+1)%12, H = x=>"H"+x;
  let p;
  switch (lang) {
    case "deCH": {
      // Swiss German: viertel ab drü, halbi vieri
      p = { intro:["ES","ISCH"], words:{
        0:[H(h)], 5:["M5","AB",H(h)], 10:["M10","AB",H(h)], 15:["V","AB",H(h)],
        20:["M20","AB",H(h)], 25:["M5","VOR","HALBI",H(n)], 30:["HALBI",H(n)],
        35:["M5","AB","HALBI",H(n)], 40:["M20","VOR",H(n)], 45:["V","VOR",H(n)],
        50:["M10","VOR",H(n)], 55:["M5","VOR",H(n)] }[m5] };
      break;
    }
    case "en": case "us": {
      const past = lang === "us" ? "AFTER" : "PAST";
      p = { intro:["IT","IS"], words:{
        0:[H(h),"OCLOCK"], 5:["M5",past,H(h)], 10:["M10",past,H(h)],
        15:["A","QUARTER",past,H(h)], 20:["M20",past,H(h)], 25:["M20","M5",past,H(h)],
        30:["HALF","PAST",H(h)], 35:["M20","M5","TO",H(n)], 40:["M20","TO",H(n)],
        45:["A","QUARTER","TO",H(n)], 50:["M10","TO",H(n)], 55:["M5","TO",H(n)] }[m5] };
      break;
    }
    case "fr": {
      // hour (24 h) -> hour word and "heure(s)"; 12:00 = midi, 0:00 = minuit
      const hw = x => x === 0 ? ["MINUIT"] : x === 12 ? ["MIDI"] : [H(x%12), x%12 === 1 ? "HEURE" : "HEURES"];
      const cur = hw(h24), nxt = hw((h24+1)%24);
      const demi = cur.length === 1 ? "DEMI" : "DEMIE";   // midi et demi, trois heures et demie
      p = { intro:["IL","EST"], words:{
        0:cur, 5:[...cur,"M5"], 10:[...cur,"M10"], 15:[...cur,"ET","QUART"],
        20:[...cur,"M20"], 25:[...cur,"M25"], 30:[...cur,"ET",demi],
        35:[...nxt,"MOINS","M25"], 40:[...nxt,"MOINS","M20"], 45:[...nxt,"MOINS","LE","QUART"],
        50:[...nxt,"MOINS","M10"], 55:[...nxt,"MOINS","M5"] }[m5] };
      break;
    }
    case "it": {
      // è l'una / sono le due
      const hw = x => x === 1 ? [H(1)] : ["LE", H(x)];
      const cur = hw(h), nxt = hw(n), hr = m5 < 35 ? h : n;
      p = { intro:[hr === 1 ? "È" : "SONO"], words:{
        0:cur, 5:[...cur,"E","M5"], 10:[...cur,"E","M10"], 15:[...cur,"E","UN","QUARTO"],
        20:[...cur,"E","M20"], 25:[...cur,"E","M25"], 30:[...cur,"E","MEZZA"],
        35:[...nxt,"MENO","M25"], 40:[...nxt,"MENO","M20"], 45:[...nxt,"MENO","UN","QUARTO"],
        50:[...nxt,"MENO","M10"], 55:[...nxt,"MENO","M5"] }[m5] };
      break;
    }
    case "es": {
      // es la una / son las dos
      const hw = x => [x === 1 ? "LA" : "LAS", H(x)];
      const cur = hw(h), nxt = hw(n), hr = m5 < 35 ? h : n;
      p = { intro:[hr === 1 ? "ES" : "SON"], words:{
        0:cur, 5:[...cur,"Y","M5"], 10:[...cur,"Y","M10"], 15:[...cur,"Y","CUARTO"],
        20:[...cur,"Y","M20"], 25:[...cur,"Y","M25"], 30:[...cur,"Y","MEDIA"],
        35:[...nxt,"MENOS","M25"], 40:[...nxt,"MENOS","M20"], 45:[...nxt,"MENOS","CUARTO"],
        50:[...nxt,"MENOS","M10"], 55:[...nxt,"MENOS","M5"] }[m5] };
      break;
    }
    default: {
      const south = lang === "deSouth";
      p = { intro:["ES","IST"], words:{
        0:[h===1?"EIN":H(h),"UHR"], 5:["M5","NACH",H(h)], 10:["M10","NACH",H(h)],
        15: south?["V",H(n)]:["V","NACH",H(h)],
        20: south?["M10","VOR","HALB",H(n)]:["M20","NACH",H(h)],
        25:["M5","VOR","HALB",H(n)], 30:["HALB",H(n)], 35:["M5","NACH","HALB",H(n)],
        40: south?["M10","NACH","HALB",H(n)]:["M20","VOR",H(n)],
        45: south?["DV",H(n)]:["V","VOR",H(n)],
        50:["M10","VOR",H(n)], 55:["M5","VOR",H(n)] }[m5] };
    }
  }
  return { words:(intro?p.intro:[]).concat(p.words), edges:m%5 };
}

/* Words as readable text (for display and checks) */
function spell(lang, words){
  const f = FACES[LANGS[lang]];
  return words.map(w => {
    const [r,c,l] = f.words[w];
    let t = [...f.grid[r].normalize("NFC")].slice(c, c+l);
    for (const mk of f.marks) if (mk.word === w && mk.row === r) t.splice(mk.afterCol - c + 1, 0, mk.glyph);
    return t.join("");
  }).join(" ");
}

if (typeof module !== "undefined") module.exports = { FACES, LANGS, phrase, spell };
