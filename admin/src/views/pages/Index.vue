<script setup>
import { ref, watchEffect } from 'vue';
import {_} from 'vue-underscore';
import { api } from '@/libs/api.js';
import InputText from 'primevue/inputtext';
import IconField from 'primevue/iconfield';
import InputIcon from 'primevue/inputicon';

const apiUrl = import.meta.env.VITE_API_URL

const props = defineProps({
  isListOnly: Boolean,
  limit: Number,
  currentUser: Object,
})

// ЯЗЫКИ
const langs = {
  ar: '🇸🇦',  // Арабский (ОАЭ)
  hy: '🇦🇲',  // Армянский
  'zh-Hans': '🇨🇳',  // Китайский
  'zh-Hant': '🇨🇳',  // Китайский
  de: '🇩🇪',  // Немецкий
  en: '🇺🇸',  // Английский (Великобритания)
  es: '🇪🇸',  // Испанский
  fr: '🇫🇷',  // Французский
  el: '🇬🇷',  // Греческий
  he: '🇮🇱',  // Иврит
  hi: '🇮🇳',  // Хинди
  fa: '🇮🇷',  // Персидский
  it: '🇮🇹',  // Итальянский
  ja: '🇯🇵',  // Японский
  sw: '🇰🇪',  // Суахили
  ko: '🇰🇷',  // Корейский
  ru: '🇷🇺',  // Русский
  sr: '🇷🇸',  // Сербский
  tr: '🇹🇷',  // Турецкий
  tk: '🇹🇲',  // Туркменский
  uz: '🇺🇿',  // Узбекский
  vi: '🇻🇳',  // Вьетнамский
  // ---
  cu:  '📜', // Церковнославянский
  grc: '🏛️', // Древнегреческий
  la:  '🇻🇦', // Латынь
  frm: '🇫🇷', // Средневековый французский (Medieval ~1400–1600)
  fro: '🇫🇷', // Старофранцузский (до XIV века)
  cop: '🇪🇬', // Коптский
  xcl: '🇦🇲', // Древнеармянский (грабар)
};

const langsWithoutLocales = {
 'la':  'it', // # Латынь (ISO 639-1/2)
 'grc': 'el', // # Древнегреческий (классический) (ISO 639-3)
 'frm': 'fr', // # Средневековый французский (ISO 639-3, French, Medieval ~1400–1600)
 'fro': 'fr', // # Старофранцузский (до XIV века) (ISO 639-3)
 'cop': 'en', // # Коптский (ISO 639-2/3)
 'cu':  'ru', // # Церковнославянский (ISO 639-1/2, код означает "Old Church Slavonic")
 'xcl': 'ru', // # Древнеармянский
}
// Для древних языков, которым не сделана локализация UI, принимаем решение какую локализацию включать:
function localeForPage(pageLang) {
  return langsWithoutLocales[pageLang] || pageLang || 'ru';
}

const searchTerm = ref('')

const pages = ref({})
const isLoading = ref(false)
const errors = ref('')

// _ через функцию debounce откладывает все попытки выполнить указанную функцию
// на 300 сек, превращая все эти попытки в одну.
const lazyAutoSearch = _.debounce(autoSearch, 300);
function autoSearch() {
  isLoading.value = true;
  let params = { term: searchTerm.value };
  if (props.limit) params.limit = props.limit;
  api.get('/pages/list/', params).then(data => {
    isLoading.value = false;
    console.log(data)
    if (data.success == 'ok') {
      pages.value = data.items;
    } else {
      errors.value = data.errors;
    }
  })
}

watchEffect(
  function() {
    if (searchTerm.value.length == 0 || searchTerm.value.length > 2) lazyAutoSearch();
  }
)
</script>

<template>
<h2 v-if="isListOnly">Недавно изменённые статьи</h2>
<h2 v-else="isListOnly">Статьи</h2>

<router-link v-if="currentUser?.privs?.pages_create && !isListOnly" :to="{ name: 'NewPage' }">
  ＋ Новая страница
</router-link>

<div v-if="!isListOnly" style="margin: 10px 0 20px 0">
  <IconField iconPosition="left">
    <InputIcon :class="`pi ${ isLoading ? 'pi-spin pi-spinner' : 'pi-search' }`" />
    <InputText v-model="searchTerm" placeholder='Фильтр' autofocus autocomplete="off" id="search-field" />
  </IconField>
</div>

<div v-if="pages.length == 0">
  <div class='page'>Ничего не найдено</div>
</div>

<div id="pages" v-for="page in pages">
  <div class='page'>
    {{ langs[page.lang] }}
    <router-link :to="{ name: 'EditPage', params: { id: page.id }}">
      {{ page.title }}
    </router-link>
    <i class="badge black" v-if="page.is_deleted">удалено</i>
    <i class="badge grey" v-else-if="!page.is_published">скрыто</i>
    <a style='margin: 0;' v-if="page.id" :href="`${apiUrl}/${localeForPage(page.lang)}/${page.lang}/w/${page.path}`">
      <i class="pi pi-external-link" style="font-size: 0.8rem"></i>
    </a>

    <div class="hint">
      {{ page.updated_at_word  }},
      {{ page.author?.name  }},
      <i class="pi pi-eye" style="font-size: 0.7rem"></i> {{ page.visits }}
    </div>
  </div>
</div>
<div v-if="errors.length">{{ errors }}</div>
</template>

<style scoped>
.page { margin: 15px 0;}
.page a {
  margin: 0 10px;
  color:rgb(116, 108, 80);
}
.page a:hover {
  color:rgb(164, 155, 122);
}
.page .hint {
  margin: 0 0 0 30px;
  color: #999;
}
</style>
