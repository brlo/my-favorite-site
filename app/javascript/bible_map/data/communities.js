// Границы народа Божьего (голубой) и отделившихся или самочинных обществ (красноватые) по годам.
// Области одного рода сливаются в общее поле (см. CommunityLayer); name показывается при наведении мыши.
// circle: [широта, долгота, радиус в градусах] либо poly — многоугольник.
// Запись видна в годы [from, to). morphFrom — из какой записи она «перетекает» цветом:
// так показывается отпадение (например, Северный Израиль в 931 г. до Р. Х.).
import { amToYear } from 'bible_map/chrono';
import { LANDS } from 'bible_map/data/places';
import { REGIONS } from 'bible_map/data/regions';

const am = amToYear;

// До какого года страна остаётся в голубой области (дальше её место занимает отделившаяся Церковь)
const CHURCH_UNTIL = { mesopotamia: 486, persia: 486, egyptLower: 451, egyptUpper: 451, aksum: 451, armenia: 506, osroene: 540, nubia: 580,
  syria: 1000, numidia: 800, africa: 900 };
const fallenRegion = (region, name, color, from, to = 2000) => ({ id: `sep-${region}`, kind: 'fallen', color, name, from, to, poly: REGIONS[region], region: true });

export const COMMUNITIES = [
  // от рая до потопа
  { id: 'paradise', kind: 'church', name: 'Адам и Ева', from: am(0), to: am(0.5), circle: [31.0, 47.2, 0.9] },
  { id: 'adam-family', kind: 'church', name: 'Семья Адама', from: am(0.5), to: am(230), circle: [31.6, 49.2, 0.7] },
  { id: 'cainites-1', kind: 'human', name: 'Сыны человеческие', from: am(130), to: am(1000), circle: [31.6, 50.4, 1.0], hyp: true },
  { id: 'cainites-2', kind: 'human', name: 'Сыны человеческие', from: am(1000), to: am(2122), circle: [31.9, 50.6, 2.2], hyp: true },
  { id: 'sethites-1', kind: 'church', name: 'Сыны Божии', from: am(230), to: am(1000), circle: [31.8, 48.6, 1.0], hyp: true },
  { id: 'sethites-2', kind: 'church', name: 'Сыны Божии', from: am(1000), to: am(2122), circle: [32.0, 48.2, 1.6], hyp: true },
  // перед потопом верные смешались с нечестивыми; остаётся одна семья
  { id: 'mixed', kind: 'human', name: 'Развратившееся человечество', from: am(2122), to: am(2242), circle: [32.0, 49.0, 3.0], hyp: true,
    morphFrom: 'cainites-2' },
  { id: 'noah-family', kind: 'church', name: 'Семья Ноя', from: am(2122), to: am(2242), circle: [32.2, 47.5, 0.35], hyp: true,
    morphFrom: 'sethites-2' },
  // после потопа
  { id: 'noah-ararat', kind: 'church', name: 'Ной и его сыновья', from: am(2243), to: am(2700), circle: [39.4, 44.0, 0.6] },
  { id: 'shinar', kind: 'human', name: 'Строители башни', from: am(2700), to: am(2774), circle: [32.6, 44.4, 1.2] },
  // от Авраама: дом Авраама, Исаака и Иакова кочует, вместе с ним — и область народа Божьего
  { id: 'abram-ur', kind: 'church', name: 'Дом Фарры и Аврама', from: am(3374), to: am(3384), circle: [30.96, 46.1, 0.35] },
  { id: 'abram-haran', kind: 'church', name: 'Дом Аврама', from: am(3384), to: am(3389), circle: [36.86, 39.03, 0.35] },
  { id: 'abram-canaan', kind: 'church', name: 'Дом Авраама', from: am(3389), to: am(3551), circle: [31.7, 35.1, 0.45] },
  { id: 'salem', kind: 'church', name: 'Мелхиседек', from: am(3380), to: am(3420), circle: [31.78, 35.24, 0.12], labelAt: [31.9, 35.6] },
  { id: 'jacob-haran', kind: 'church', name: 'Иаков в Харране', from: am(3551), to: am(3571), circle: [36.86, 39.03, 0.35] },
  { id: 'israel-canaan', kind: 'church', name: 'Дом Израиля', from: am(3571), to: am(3604), circle: [31.7, 35.15, 0.45] },
  { id: 'israel-egypt', kind: 'church', name: 'Израиль в Египте', from: am(3604), to: -1689.5, circle: [30.75, 31.85, 0.45] },
  { id: 'israel-exodus', kind: 'church', name: 'Израиль', from: -1689.5, to: -1689, circle: [29.95, 32.6, 0.4], morphFrom: 'israel-egypt' },
  // Ветхозаветная Церковь: от Синая до плена
  { id: 'israel-sinai', kind: 'church', name: 'Ветхозаветная Церковь', from: -1689, to: -1688, circle: [28.75, 33.95, 0.5], labelAt: [29.3, 34.5] },
  { id: 'israel-desert', kind: 'church', name: 'Израиль в пустыне', from: -1688, to: -1650, circle: [30.5, 34.6, 0.6] },
  { id: 'israel-moab', kind: 'church', name: 'Израиль у Иордана', from: -1650, to: -1649, circle: [31.78, 35.65, 0.25] },
  { id: 'israel-land', kind: 'church', name: 'Израиль', from: -1649, to: -931, poly: LANDS.israel, labelAt: [32.4, 35.6] },
  // после смерти Соломона: Иудея остаётся, Северное царство отпадает (голубое перетекает в красное)
  { id: 'judah', kind: 'church', name: 'Иудея', from: -931, to: -586, poly: LANDS.judah, labelAt: [31.45, 35.0] },
  { id: 'north-israel', kind: 'fallen', name: 'Северное царство', from: -931, to: -722, poly: LANDS.north, labelAt: [32.7, 35.55], morphFrom: 'israel-land' },
  // после 722 г. на месте Израиля — самаряне, смешанная вера переселенцев
  { id: 'samaritans', kind: 'human', name: 'Самаряне', from: -722, to: 2000, poly: LANDS.samaria, labelAt: [32.3, 35.25], morphFrom: 'north-israel' },
  { id: 'exiles', kind: 'church', name: 'Иудеи в плену', from: -586, to: -538, circle: [32.2, 45.0, 0.6], morphFrom: 'judah' },
  // после плена: Иудея вокруг Иерусалима и общины рассеяния (до Креста; дальше — следующий этап)
  { id: 'yehud', kind: 'church', name: 'Иудея', from: -538, to: -164, poly: LANDS.yehud, labelAt: [31.55, 34.85] },
  { id: 'diaspora-babylon', kind: 'church', name: 'Рассеяние', from: -538, to: 33.29, circle: [32.3, 44.9, 0.5] },
  { id: 'diaspora-susa', kind: 'church', name: 'Рассеяние', from: -480, to: 33.29, circle: [32.19, 48.25, 0.25] },
  { id: 'diaspora-alexandria', kind: 'church', name: 'Иудеи Александрии', from: -300, to: 33.29, circle: [31.2, 29.95, 0.3] },
  { id: 'diaspora-antioch', kind: 'church', name: 'Рассеяние', from: -250, to: 33.29, circle: [36.2, 36.16, 0.2] },
  // после Маккавеев Иудея снова охватывает почти всю прежнюю землю Израиля
  { id: 'judea', kind: 'church', name: 'Иудея', from: -164, to: 33.29, poly: LANDS.israel, labelAt: [31.45, 34.85], morphFrom: 'yehud' },
  // круг учеников Христовых — будущая Церковь (ярче, внутри Иудеи)
  { id: 'disciples', kind: 'church', name: 'Ученики Христовы', from: 30.6, to: 33.26, circle: [32.85, 35.55, 0.18], labelAt: [32.98, 35.85] },
  { id: 'disciples-jerusalem', kind: 'church', name: 'Ученики Христовы', from: 33.26, to: 33.29, circle: [31.775, 35.233, 0.06], morphFrom: 'disciples' },

  // Распятие: отвергшие своего Мессию перестают быть народом Божьим (голубое перетекает в красное);
  // народ Божий — Пресвятая Богородица, апостолы и ученики, принявшие Христа
  { id: 'rejected', kind: 'fallen', name: 'Иудеи, отвергшие Христа', from: 33.29, to: 90.5, poly: LANDS.israel, labelAt: [31.45, 34.85], morphFrom: 'judea' },
  { id: 'rabbinic', kind: 'fallen', name: 'Раввинистический иудаизм', from: 90.5, to: 2000, poly: LANDS.israel, labelAt: [31.45, 34.85], morphFrom: 'rejected' },
  { id: 'rejected-babylon', kind: 'fallen', name: 'Иудеи, отвергшие Христа', from: 33.29, to: 2000, circle: [32.3, 44.9, 0.5], morphFrom: 'diaspora-babylon' },
  { id: 'rejected-susa', kind: 'fallen', name: 'Иудеи, отвергшие Христа', from: 33.29, to: 2000, circle: [32.19, 48.25, 0.25], morphFrom: 'diaspora-susa' },
  { id: 'rejected-alexandria', kind: 'fallen', name: 'Иудеи, отвергшие Христа', from: 33.29, to: 2000, circle: [31.2, 29.95, 0.3], morphFrom: 'diaspora-alexandria' },
  { id: 'rejected-antioch', kind: 'fallen', name: 'Иудеи, отвергшие Христа', from: 33.29, to: 2000, circle: [36.2, 36.16, 0.2], morphFrom: 'diaspora-antioch' },
  { id: 'apostles-circle', kind: 'church', name: 'Апостолы и ученики', from: 33.29, to: 33.4, circle: [31.775, 35.233, 0.06], labelAt: [31.85, 35.0], morphFrom: 'disciples-jerusalem' },
  // Пятидесятница: Церковь Христова в Иерусалиме
  { id: 'church-jerusalem', kind: 'church', name: 'Церковь Христова', from: 33.4, to: 66, circle: [31.775, 35.233, 0.18], labelAt: [31.95, 34.95], morphFrom: 'apostles-circle' },
  // перед войной Иерусалимская Церковь уходит в Пеллу и возвращается после 70 г. (Евсевий, ЦИ III.5)
  { id: 'church-pella', kind: 'church', name: 'Иерусалимская Церковь в Пелле', from: 66, to: 73, circle: [32.45, 35.62, 0.15], morphFrom: 'church-jerusalem' },
  { id: 'church-jerusalem-2', kind: 'church', name: 'Иерусалимская Церковь', from: 73, to: 2000, circle: [31.775, 35.233, 0.15], morphFrom: 'church-pella' },

  // Церкви апостольского века: появляются по мере проповеди (подписаны только главные)
  ...[
    ['church-samaria', null, 32.28, 35.2, 35, 0.12],
    ['church-damascus', null, 33.51, 36.29, 36, 0.12],
    ['church-caesarea', null, 32.50, 34.89, 38, 0.1],
    ['church-antioch', 'Антиохия', 36.20, 36.16, 42, 0.25],
    ['church-ethiopia', null, 16.94, 33.75, 36, 0.3],
    ['church-cyprus', null, 35.1, 33.4, 46, 0.25],
    ['church-galatia', 'Галатия', 37.9, 32.0, 47, 0.45],
    ['church-alexandria', 'Александрия', 31.2, 29.92, 45, 0.25],
    ['church-edessa', 'Едесса', 37.16, 38.79, 45, 0.2],
    ['church-armenia', null, 39.95, 44.55, 50, 0.3],
    ['church-macedonia', 'Македония', 40.8, 23.5, 50, 0.45],
    ['church-achaia', 'Ахаия', 37.95, 23.3, 51, 0.35],
    ['church-ephesus', 'Асия', 38.2, 27.8, 52, 0.45],
    ['church-rome', 'Рим', 41.89, 12.49, 50, 0.3],
    ['church-pontus', null, 41.0, 35.5, 55, 0.5],
    ['church-india', 'Индия', 11.0, 77.5, 52, 0.6],
    ['church-crete', null, 35.2, 24.9, 63, 0.25],
    ['church-hierapolis', null, 37.93, 29.12, 55, 0.15],
    ['church-scythia', null, 44.61, 33.49, 60, 0.2],
    ['church-caucasus', null, 43.09, 40.81, 60, 0.2],
  ].map(([id, name, lat, lon, from, r]) => ({ id, kind: 'church', name, from, to: 2000, circle: [lat, lon, r] })),

  // ереси апостольского века. У «наследников Симона» общий оттенок — так видно, что это одна ветвь
  { id: 'simonians', kind: 'human', color: '#d8708a', name: 'Симониане', from: 35, to: 300, circle: [32.4, 34.95, 0.12], labelAt: [32.5, 34.4] },
  { id: 'simon-rome', kind: 'human', color: '#d8708a', name: 'Симониане', from: 45, to: 200, circle: [41.55, 13.3, 0.15] },
  { id: 'menandrians', kind: 'human', color: '#d8708a', name: 'Менандр', from: 80, to: 200, circle: [36.55, 36.65, 0.15] },
  { id: 'cerinthians', kind: 'human', color: '#d8708a', name: 'Керинф', from: 90, to: 200, circle: [38.45, 28.0, 0.15] },
  { id: 'nicolaitans', kind: 'human', color: '#d8708a', name: 'Николаиты', from: 90, to: 150, circle: [39.35, 27.6, 0.15] },
  { id: 'ebionites', kind: 'human', color: '#e8a06a', name: 'Эвиониты', from: 50, to: 400, circle: [32.75, 36.05, 0.25], labelAt: [32.95, 36.6] },

  // Страны и провинции, где христиане стали заметной частью народа (порядка 3%): целиком входят в голубую область.
  // Годы — приблизительные оценки (Малая Азия и Сирия — к концу II в., Египет и Африка — к III в., Запад — к IV в.).
  ...[
    ['asia', 'Асия', 150], ['bithynia', 'Вифиния и Понт', 160], ['syria', 'Сирия', 180], ['osroene', 'Осроена (Едесса)', 190],
    ['africa', 'Африка', 200], ['egyptLower', 'Египет', 200], ['galatia', 'Галатия и Фригия', 200], ['cilicia', 'Киликия, Ликия, Памфилия', 220],
    ['cyprus', 'Кипр', 220], ['italy', 'Италия', 250], ['achaia', 'Ахаия', 250], ['macedonia', 'Македония и Фракия', 260],
    ['cappadocia', 'Каппадокия', 250], ['numidia', 'Нумидия и Мавритания', 260], ['egyptUpper', 'Фиваида', 280], ['crete', 'Крит', 280],
    ['armenia', 'Армения', 301], ['mesopotamia', 'Месопотамия', 300], ['palestine', 'Палестина', 320], ['cyrenaica', 'Киренаика', 300],
    ['tripolitania', 'Триполитания', 300], ['arabia', 'Аравия', 330], ['iberia', 'Иверия (Грузия)', 330], ['aksum', 'Аксум (Эфиопия)', 340],
    ['gaul', 'Галлия', 330], ['hispania', 'Испания', 330], ['illyricum', 'Иллирик', 330], ['moesia', 'Мёзия и Дакия', 330],
    ['britain', 'Британия', 360], ['persia', 'Персия', 380], ['ireland', 'Ирландия', 450], ['nubia', 'Нубия', 550],
  ].map(([region, name, from]) => ({ id: `region-${region}`, kind: 'church', name, from, to: CHURCH_UNTIL[region] ?? 2000, poly: REGIONS[region], region: true })),

  // ветвь Симона во II веке: гностики и Маркион
  { id: 'saturninians', kind: 'human', color: '#d8708a', name: 'Сатурнин', from: 120, to: 300, circle: [36.0, 36.65, 0.15] },
  { id: 'basilidians', kind: 'human', color: '#d8708a', name: 'Василид', from: 130, to: 400, circle: [31.5, 30.35, 0.2] },
  { id: 'valentinians', kind: 'human', color: '#d8708a', name: 'Валентиниане', from: 140, to: 450, circle: [42.25, 12.95, 0.25], labelAt: [42.8, 13.6] },
  { id: 'valentinians-east', kind: 'human', color: '#d8708a', name: 'Валентиниане', from: 150, to: 450, circle: [36.3, 35.6, 0.25] },
  { id: 'marcionites-rome', kind: 'human', color: '#c9609a', name: 'Маркиониты', from: 144, to: 450, circle: [41.5, 12.05, 0.25], labelAt: [41.0, 11.3] },
  { id: 'marcionites-pontus', kind: 'human', color: '#c9609a', name: 'Маркиониты', from: 150, to: 450, circle: [41.6, 35.2, 0.35] },
  { id: 'marcionites-syria', kind: 'human', color: '#c9609a', name: 'Маркиониты', from: 160, to: 450, circle: [35.4, 37.6, 0.4] },
  // своё «откровение»: монтанисты; «чистая» община Новациана; дуализм Мани
  { id: 'montanists', kind: 'human', color: '#e0a05a', name: 'Монтанисты', from: 172, to: 550, circle: [38.95, 29.4, 0.45], labelAt: [39.6, 29.0] },
  { id: 'novatians', kind: 'human', color: '#e09070', name: 'Новациане', from: 251, to: 600, circle: [42.1, 12.1, 0.18], labelAt: [42.6, 11.4] },
  { id: 'manichaeans', kind: 'human', color: '#c0504a', name: 'Манихеи', from: 242, to: 1300, circle: [33.3, 45.4, 0.7], labelAt: [32.4, 46.4] },
  { id: 'manichaeans-asia', kind: 'human', color: '#c0504a', name: 'Манихеи', from: 280, to: 1300, circle: [39.4, 64.5, 1.2] },
  { id: 'manichaeans-egypt', kind: 'human', color: '#c0504a', name: 'Манихеи', from: 280, to: 600, circle: [28.0, 30.8, 0.4] },
  { id: 'manichaeans-africa', kind: 'human', color: '#c0504a', name: 'Манихеи', from: 300, to: 600, circle: [36.5, 10.5, 0.3] },

  // IV–VIII века. Ариане (германские королевства до обращения в Православие)
  { id: 'arians-goths', kind: 'human', color: '#d09060', name: 'Ариане (готы)', from: 341, to: 500, poly: REGIONS.gothia, region: true },
  { id: 'arians-vandals', kind: 'human', color: '#d09060', name: 'Ариане-вандалы', from: 429, to: 533, circle: [36.6, 9.0, 1.0] },
  { id: 'arians-visigoths', kind: 'human', color: '#d09060', name: 'Ариане-вестготы', from: 415, to: 589, circle: [40.0, -3.7, 1.5] },
  { id: 'arians-ostrogoths', kind: 'human', color: '#d09060', name: 'Ариане-остготы', from: 493, to: 553, circle: [44.4, 11.5, 1.2] },
  { id: 'arians-lombards', kind: 'human', color: '#d09060', name: 'Ариане-лангобарды', from: 568, to: 662, circle: [45.3, 9.5, 1.0] },
  // отделившиеся после III и IV Вселенских Соборов
  fallenRegion('mesopotamia', 'Церковь Востока (несториане)', '#d08a5a', 486, 900),
  fallenRegion('persia', 'Церковь Востока (несториане)', '#d08a5a', 486, 900),
  { id: 'east-asia-central', kind: 'fallen', color: '#d08a5a', name: 'Церковь Востока (несториане)', from: 600, to: 1400, circle: [39.6, 66.9, 1.5] },
  { id: 'east-china', kind: 'fallen', color: '#d08a5a', name: 'Церковь Востока в Китае', from: 635, to: 845, circle: [34.27, 108.9, 1.2] },
  fallenRegion('egyptLower', 'Копты (нехалкидониты)', '#d06a7a', 451, 950),
  fallenRegion('egyptUpper', 'Копты (нехалкидониты)', '#d06a7a', 451),
  fallenRegion('aksum', 'Эфиопская Церковь (нехалкидониты)', '#d06a7a', 451),
  fallenRegion('nubia', 'Нубийская Церковь (нехалкидониты)', '#d06a7a', 580),
  fallenRegion('armenia', 'Армянская Церковь (нехалкидониты)', '#d06a7a', 506),
  fallenRegion('osroene', 'Сирийские яковиты (нехалкидониты)', '#d06a7a', 540),
  // православные («мелькиты») в городах, где большинство отделилось
  { id: 'melkites-alexandria', kind: 'church', name: 'Православные Александрии', from: 451, to: 2000, circle: [31.2, 29.92, 0.4] },
  // дуалистическая ветвь: от манихеев к павликианам
  { id: 'paulicians', kind: 'human', color: '#c0504a', name: 'Павликиане', from: 660, to: 880, circle: [38.6, 38.6, 0.8] },
  { id: 'paulicians-thrace', kind: 'human', color: '#c0504a', name: 'Павликиане во Фракии', from: 757, to: 1100, circle: [42.15, 24.75, 0.6] },
  // ислам: страна становится красной, когда мусульмане стали в ней большинством (до этого — христианская под властью халифа)
  { id: 'islam-arabia', kind: 'human', color: '#cf6f3f', name: 'Ислам', from: 630, to: 2000, poly: REGIONS.arabiaPen, region: true },
  { id: 'islam-numidia', kind: 'human', color: '#cf6f3f', name: 'Ислам', from: 800, to: 2000, poly: REGIONS.numidia, region: true },
  { id: 'islam-persia', kind: 'human', color: '#cf6f3f', name: 'Ислам', from: 900, to: 2000, poly: REGIONS.persia, region: true },
  { id: 'islam-mesopotamia', kind: 'human', color: '#cf6f3f', name: 'Ислам', from: 900, to: 2000, poly: REGIONS.mesopotamia, region: true },
  { id: 'islam-transoxiana', kind: 'human', color: '#cf6f3f', name: 'Ислам', from: 900, to: 2000, poly: REGIONS.transoxiana, region: true },
  { id: 'islam-africa', kind: 'human', color: '#cf6f3f', name: 'Ислам', from: 900, to: 2000, poly: REGIONS.africa, region: true },
  { id: 'islam-egypt', kind: 'human', color: '#cf6f3f', name: 'Ислам', from: 950, to: 2000, poly: REGIONS.egyptLower, region: true },
  { id: 'islam-syria', kind: 'human', color: '#cf6f3f', name: 'Ислам', from: 1000, to: 2000, poly: REGIONS.syria, region: true },
  { id: 'islam-spain', kind: 'human', color: '#cf6f3f', name: 'Ислам', from: 950, to: 1250, circle: [37.5, -4.5, 1.6] },
];