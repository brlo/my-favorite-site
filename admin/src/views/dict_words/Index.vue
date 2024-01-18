<script setup>
import { ref, watchEffect } from 'vue';
import {_} from 'vue-underscore';
import { api } from '@/libs/api.js';
import InputText from 'primevue/inputtext';

const props = defineProps({
  limit: Number,
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

const dictWords = ref([])
const errors = ref('')

// _ через функцию debounce откладывает все попытки выполнить указанную функцию
// на 300 сек, превращая все эти попытки в одну.
const lazyAutoSearch = _.debounce(autoSearch, 300);
function autoSearch() {
  let params = { term: searchTerm.value }
  if (props.limit) params.limit = props.limit;
  api.get('/dict_words/list', params).then(data => {
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
    if (searchTerm.value.length == 0 || searchTerm.value.length > 2) lazyAutoSearch();
  }
)
</script>

<template>
<h2>Словарные слова</h2>

<router-link :to="{ name: 'NewDictWord'}">
  ＋ Новое слово
</router-link>

<div style="margin: 10px 0 20px 0">
  <span class="p-input-icon-left">
    <i class="pi pi-search" />
    <InputText v-model="searchTerm" placeholder='Фильтр' autofocus autocomplete="off" id="search-field" />
  </span>
</div>

<div v-if="dictWords.length == 0">
  <div class='word'>Ничего не найдено</div>
</div>

<div id="words" v-for="word in dictWords">
  <div class='word'>
    <div class="top">
      {{ langs[word.src_lang] }}
      <router-link :to="{ name: 'EditDictWord', params: { id: word.id }}">
        {{ word.word }}
      </router-link>

      {{ word.translation_short ? ' — ' + word.translation_short : '' }}
      {{ word.transcription ? ', ' + word.transcription : ''  }}
    </div>

    <div class="desc" v-html="word.desc" />
  </div>
</div>
<div v-if="errors.length">{{ errors }}</div>
</template>

<style scoped>
#words {
  margin: 30px 0 0 0;
}
.word {
  margin: 0 0 40px 0;
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
.word .desc {
  margin: 15px 0 0 30px;
  color: #3a3a3a;
}

</style>
