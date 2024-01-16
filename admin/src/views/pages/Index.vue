<script setup>
import { ref, watchEffect } from 'vue';
import {_} from 'vue-underscore';
import { api } from '@/libs/api.js';
import InputText from 'primevue/inputtext';

const props = defineProps({
  isListOnly: Boolean
})

// ЯЗЫКИ
const langs = {
  ru: '🇷🇺',
  en: '🇺🇸',
  gr: '🇬🇷',
  il: '🇮🇱',
  ar: '🇪🇬',
  jp: '🇯🇵',
  cn: '🇨🇳',
  de: '🇩🇪',
}

const searchTerm = ref('')

let pages = ref({})
let errors = ref('')

// _ через функцию debounce откладывает все попытки выполнить указанную функцию
// на 300 сек, превращая все эти попытки в одну.
const lazyAutoSearch = _.debounce(autoSearch, 300);
function autoSearch() {
  api.get('/pages/list', { term: searchTerm.value }).then(data => {
    console.log(data)
    if (data.success == 'ok') {
      pages.value = data.items;
    } else {
      errors.value = data.errors;
    }
  })
}

autoSearch()

watchEffect(
  function() {
    if (searchTerm.value.length == 0 || searchTerm.value.length > 2) lazyAutoSearch();
  }
)
</script>

<template>
<h2 v-if="isListOnly">Недавно изменённые статьи</h2>
<h2 v-else="isListOnly">Статьи</h2>

<router-link v-if="!isListOnly" :to="{ name: 'NewPage'}">
  ＋ Новая страница
</router-link>

<div v-if="!isListOnly" style="margin: 10px 0 20px 0">
  <span class="p-input-icon-left">
    <i class="pi pi-search" />
    <InputText v-model="searchTerm" placeholder='Фильтр' autofocus id="search-field" />
  </span>
</div>

<div v-if="pages.length == 0">
  <div class='page'>Ничего не найдено</div>
</div>

<div id="pages" v-for="page in pages">
  <div class='page'>
    {{ langs[page.lang] }}
    <router-link :to="{ name: 'EditPage', params: { id: page.id }}">
      {{ page.title }}
    </router-link><i class="badge grey" v-if="!!page.is_published">скрыто</i>

    <div class="hint">
      {{ page.updated_at_word  }},
      {{ page.author?.name  }}
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
