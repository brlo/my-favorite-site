// Хронология: годы храним астрономически (отрицательные — до Р. Х.).
// До Авраама включительно даты выводятся из лет от сотворения мира по Септуагинте
// (сотворение — 5508 г. до Р. Х., как в византийском летосчислении).

export const CREATION_BC = 5508;

export const amToYear = (am) => -(CREATION_BC - am);
export const yearToAm = (year) => CREATION_BC + year;

// Год события: явный year либо пересчитанный из am
export const eventYear = (ev) => (ev.year ?? amToYear(ev.am ?? 0));

// Рождество Христово для простоты считаем 0-м годом: так и подписываем
export function formatYear(year, approx = true) {
  const y = Math.round(year);
  const p = approx ? 'ок. ' : '';
  if (y === 0) return 'Рождество Христово';
  if (y < 0) return `${p}${-y} г. до Р. Х.`;
  return `${p}${y} г. по Р. Х.`;
}

export const formatAm = (year) => `${Math.round(yearToAm(year))} г. от сотворения мира`;
