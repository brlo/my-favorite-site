<script setup>
import { ref, watchEffect } from 'vue';
import {_} from 'vue-underscore';
import { api } from '@/libs/api.js';
import Dropdown from 'primevue/dropdown';
import InputText from 'primevue/inputtext';
import IconField from 'primevue/iconfield';
import InputIcon from 'primevue/inputicon';

const props = defineProps({
  limit: Number,
  currentUser: Object,
})

// ЯЗЫКИ
const langs = {
  ar: '🇦🇪',  // Арабский (ОАЭ)
  cn: '🇨🇳',  // Китайский
  de: '🇩🇪',  // Немецкий
  cp: '🇪🇬',  // Коптский
  en: '🇬🇧',  // Английский (Великобритания)
  es: '🇪🇸',  // Испанский
  fr: '🇫🇷',  // Французский
  gr: '🇬🇷',  // Греческий
  il: '🇮🇱',  // Иврит
  in: '🇮🇳',  // Хинди
  ir: '🇮🇷',  // Персидский
  it: '🇮🇹',  // Итальянский
  jp: '🇯🇵',  // Японский
  ke: '🇰🇪',  // Суахили
  kr: '🇰🇷',  // Корейский
  ru: '🇷🇺',  // Русский
  rs: '🇷🇸',  // Сербский
  tr: '🇹🇷',  // Турецкий
  tm: '🇹🇲',  // Туркменский
  uz: '🇺🇿',  // Узбекский
  vn: '🇻🇳',  // Вьетнамский
};

const dict = ref('')
const dicts = [
  { name: 'Вейсман GR-RU', code: 'w' },
  { name: 'Дворецкий GR-RU', code: 'd' },
  { name: 'Bibleox', code: 'bbx' },
  { name: 'Test JP-RU', code: 't' },
]

const searchTerm = ref('')

const dictWords = ref([])
const errors = ref('')
const isLoading = ref(false)

// _ через функцию debounce откладывает все попытки выполнить указанную функцию
// на 300 сек, превращая все эти попытки в одну.
const lazyAutoSearch = _.debounce(autoSearch, 300);
function autoSearch() {
  isLoading.value = true;
  let params = { term: searchTerm.value };
  if (dict.value.length) params.dict = dict.value;
  if (props.limit) params.limit = props.limit;

  api.get('/dict_words/list', params).then(data => {
    isLoading.value = false;
    console.log(data)
    if (data.success == 'ok') {
      dictWords.value = data.items;
    } else {
      errors.value = data.errors;
    }
  })
}

watchEffect(
  function() {
    // перечисляем переменные, при измении которых надо вызывать эту функцию
    searchTerm.value;
    dict.value;
    lazyAutoSearch();
  }
)
</script>

<template>
<h2>Словарные слова</h2>

<router-link :to="{ name: 'NewDictWord'}">
  ＋ Новое слово
</router-link>

<div style="margin: 10px 0 20px 0">
  <div class="group-fields">
    <div class="field">
      <label>Поиск</label>
      <IconField iconPosition="left">
        <InputIcon :class="`pi ${ isLoading ? 'pi-spin pi-spinner' : 'pi-search' }`" />
        <InputText v-model="searchTerm" placeholder='Фильтр' autofocus autocomplete="off" id="search-field" />
      </IconField>
    </div>

    <div class="field">
      <label>Словарь</label>
      <Dropdown
        v-model="dict"
        :options="dicts"
        optionLabel="name"
        optionValue="code"
        placeholder="Словарь"
      />
    </div>
  </div>
</div>

<div v-if="errors.length">{{ errors }}</div>

<div v-if="dictWords.length == 0">
  <div class='word'>Ничего не найдено</div>
</div>

<div id="words">
  <div class="word" v-for="word in dictWords">
    <div class="top">
      {{ langs[word.src_lang] }}
      <router-link :to="{ name: 'EditDictWord', params: { id: word.id }}">
        {{ word.word }}
      </router-link>
      <span class="transcription">
        {{ [word.transcription, word.transcription_lat].filter((n) => n != null ).join(', ') }}
      </span>
      {{ word.translation_short?.length ? ' — ' : '' }}
      <span class="translation-short">{{ word.translation_short }}</span>
    </div>
    <div class="desc" v-if="word.desc" v-html="word.desc" />
  </div>
</div>
</template>

<style scoped>
#words {
  margin: 30px 0 0 0;
}
.word {
  margin: 0 0 25px 0;
  color: #3a3a3a;
}
.word a {
  color: white;
  background-color: #af7777;
  border-radius: 5px;
  padding: 5px 10px;
  text-decoration: none;
}
.word a:hover {
  background-color:#68b182;
}
.word .translation-short { font-weight: 500; }
.word .transcription { margin: 0 0 0 8px; }
.word .desc {
  font-size: 0.8em;
  margin: 15px 0 30px 31px;
}
</style>
