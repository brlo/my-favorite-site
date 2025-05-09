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
  api.get('/pages/list', params).then(data => {
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
    <a style='margin: 0;' v-if="page.id" :href="`${apiUrl}/${page.lang}/${page.lang}/w/${page.path}`">
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
