<script setup>
import { ref, watchEffect } from 'vue'
import {_} from 'vue-underscore'
import { getCookie } from '@/libs/cookies.js'

// function getFirstUpcaseLetter(str) {
//   str = String(str)
//   str = Array.from(str)[0]
//   return str.toUpperCase()
// }


const apiUrl = import.meta.env.VITE_API_URL

const searchTerm = ref('')

let pages = ref({})

// _ через функцию debounce откладывает все попытки выполнить указанную функцию
// на 300 сек, превращая все эти попытки в одну.
const lazyAutoSearch = _.debounce(autoSearch, 300);
function autoSearch() {
  const path = `/ru/api/pages/list`
  const params = { session_key: 'test', term: searchTerm.value }
  const url = apiUrl + path + '?' + new URLSearchParams(params)
  const headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'X-API-TOKEN': getCookie('api_token')
  }
  console.log('GET: ' + url)
  fetch(url, { headers: headers })
  .then(response => response.json())
  .then(data => pages.value = data.items)
}

autoSearch()


watchEffect(
  function() {
    if (searchTerm.value.length > 2) lazyAutoSearch();
  }
)

</script>

<template>
<h1>Страницы цитат</h1>

<router-link :to="{ name: 'NewPage'}">
  ＋ Новая страница
</router-link>

<div style="margin: 10px 0 20px 0">
  <input v-model="searchTerm" type="text" placeholder='Фильтр' autofocus />
</div>

<div id="pages" v-for="page in pages">
  <div class='page'>
    <router-link :to="{ name: 'EditPage', params: { id: page.id }}">
      <b>{{ page.title }}</b>
    </router-link>
    | {{ page.lang }} | {{ page.updated_at_word  }}
  </div>
</div>
</template>

<style scoped>
</style>
