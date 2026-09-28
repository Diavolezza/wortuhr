/* Raster & Zeitlogik je Sprache – identisch in Sources/ClockFace.swift.
   Wird vom Prototyp (index.html) und vom Prüfskript (check.mjs) geladen. */

const FACES = {
  de: {
    grid: ["ESRISTLZEHN","FÜNFZWANZIG","DREIVIERTEL","NACHQTVORMJ","HALBXSIEBEN",
           "ZWÖLFKEINSA","ZWEIDREIELF","VIERYFÜNFOT","SECHSRACHTN","NEUNZEHNUHR"],
    words: { ES:[0,0,2], IST:[0,3,3], M5:[1,0,4], M10:[0,7,4], M20:[1,4,7],
      DV:[2,0,11], V:[2,4,7], NACH:[3,0,4], VOR:[3,6,3], HALB:[4,0,4],
      H7:[4,5,6], H0:[5,0,5], EIN:[5,6,3], H1:[5,6,4], H2:[6,0,4], H3:[6,4,4],
      H11:[6,8,3], H4:[7,0,4], H5:[7,5,4], H6:[8,0,5], H8:[8,6,4], H9:[9,0,4],
      H10:[9,4,4], UHR:[9,8,3] },
    intro: ["ES","IST"],
    marks: [],
  },
  en: {
    grid: ["ITLISQHALFP","AZQUARTERCK","TWENTYXFIVE","TENRPASTBTO","ONEXTWOVSIX",
           "THREEKSEVEN","FOURBELEVEN","FIVEMTWELVE","EIGHTRTENPU","NINEWOCLOCK"],
    words: { IT:[0,0,2], IS:[0,3,2], HALF:[0,6,4], A:[1,0,1], QUARTER:[1,2,7],
      M20:[2,0,6], M5:[2,7,4], M10:[3,0,3], PAST:[3,4,4], TO:[3,9,2],
      H1:[4,0,3], H2:[4,4,3], H6:[4,8,3], H3:[5,0,5], H7:[5,6,5],
      H4:[6,0,4], H11:[6,5,6], H5:[7,0,4], H0:[7,5,6], H8:[8,0,5], H10:[8,6,3],
      H9:[9,0,4], OCLOCK:[9,5,6] },
    intro: ["IT","IS"],
    // Apostroph zwischen O und C, leuchtet mit O'CLOCK
    marks: [{ glyph:"’", row:9, afterCol:5, word:"OCLOCK" }],
  },
};

/* Sprache -> Raster */
const LANGS = { hoch:"de", sued:"de", en:"en" };

function phrase(h24, m, lang, intro){
  const m5 = Math.floor(m/5)*5, h = h24%12, n = (h+1)%12, H = x=>"H"+x;
  let T;
  if (lang === "en") {
    T = {
      0:[H(h),"OCLOCK"], 5:["M5","PAST",H(h)], 10:["M10","PAST",H(h)],
      15:["A","QUARTER","PAST",H(h)], 20:["M20","PAST",H(h)], 25:["M20","M5","PAST",H(h)],
      30:["HALF","PAST",H(h)], 35:["M20","M5","TO",H(n)], 40:["M20","TO",H(n)],
      45:["A","QUARTER","TO",H(n)], 50:["M10","TO",H(n)], 55:["M5","TO",H(n)] };
  } else {
    const sued = lang === "sued";
    T = {
      0:[h===1?"EIN":H(h),"UHR"], 5:["M5","NACH",H(h)], 10:["M10","NACH",H(h)],
      15: sued?["V",H(n)]:["V","NACH",H(h)],
      20: sued?["M10","VOR","HALB",H(n)]:["M20","NACH",H(h)],
      25:["M5","VOR","HALB",H(n)], 30:["HALB",H(n)], 35:["M5","NACH","HALB",H(n)],
      40: sued?["M10","NACH","HALB",H(n)]:["M20","VOR",H(n)],
      45: sued?["DV",H(n)]:["V","VOR",H(n)],
      50:["M10","VOR",H(n)], 55:["M5","VOR",H(n)] };
  }
  const face = FACES[LANGS[lang]];
  return { words:(intro?face.intro:[]).concat(T[m5]), dots:m%5 };
}

if (typeof module !== "undefined") module.exports = { FACES, LANGS, phrase };
