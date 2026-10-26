// Все данные глобуса в одном месте
import { eventYear } from 'bible_map/chrono';
import { HEXAEMERON } from 'bible_map/data/hexaemeron';
import { ADAM_NOAH } from 'bible_map/data/adam_noah';
import { PATRIARCHS } from 'bible_map/data/patriarchs';
import { MOSES_KINGS } from 'bible_map/data/moses_kings';
import { SECOND_TEMPLE } from 'bible_map/data/second_temple';
import { NATIVITY } from 'bible_map/data/nativity';
import { GOSPEL } from 'bible_map/data/gospel';
import { PASSION } from 'bible_map/data/passion';
import { APOSTLES } from 'bible_map/data/apostles';
import { MARTYRS } from 'bible_map/data/martyrs';
import { COUNCILS } from 'bible_map/data/councils';

export { PERIODS } from 'bible_map/data/periods';
export { PERSONS } from 'bible_map/data/persons';
export { COMMUNITIES } from 'bible_map/data/communities';
export { BOOKS } from 'bible_map/data/books';
export { POLITICS } from 'bible_map/data/politics';

// Обычный мир после Шестоднева
export const WORLD = {
  water: -0.02,   // уровень воды: -0.02 — нынешние берега, 1.05 — вода покрывает всё
  veg: 1,         // растительность: 0 — голая земля
  light: 1,       // сила света
  pulse: 0,       // свет «то разливается, то сжимается» (первый день)
  ambient: 0.16,  // рассеянный свет
  atmo: 1,        // свечение атмосферы
  clouds: 0.45,   // облака
  cloudDark: 0,   // грозовые облака
  sun: 0,         // видимое солнце
  moon: 0,        // видимая луна
  stars: 1,       // звёзды
  birds: 0,       // стаи птиц
  warm: 0,        // тёплый «субботний» оттенок
  sunLight: 0,    // 0 — свет со стороны зрителя, 1 — от солнца
  spin: 0,        // медленное вращение камеры вокруг Земли
};

// События по годам (сортировка устойчивая: события одного года идут в порядке файлов)
export const EVENTS = [...HEXAEMERON, ...ADAM_NOAH, ...PATRIARCHS, ...MOSES_KINGS, ...SECOND_TEMPLE, ...NATIVITY, ...GOSPEL, ...PASSION, ...APOSTLES, ...MARTYRS, ...COUNCILS].map((ev) => ({ ...ev, year: eventYear(ev) }))
  .sort((a, b) => a.year - b.year);
