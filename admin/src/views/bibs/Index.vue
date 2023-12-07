<script setup>
import { ref } from 'vue'

function getFirstUpcaseLetter(str) {
  str = String(str)
  str = Array.from(str)[0]
  return str.toUpperCase()
}

const searchTerm = ref('')

let quotesPages = ref({})

const path = `/ru/api/quotes/list`
const params = { session_key: 'test', term: searchTerm.value }
const url = 'http://bibleox.lan' + path + '?' + new URLSearchParams(params)
console.log('GET: ' + url)
fetch(url).then(response => response.json())
.then(data => quotesPages.value = data.items)

</script>

<template>
<h1>Страницы цитат</h1>
<br>
<router-link :to="{ name: 'NewBib'}">
  ＋ Новая страница
</router-link>
<br>

<div>
  <input v-model="searchTerm" type="text" placeholder='Фильтр' autofocus />
</div>
<br>
<br>
<div id="quotes_pages" v-for="bib in quotesPages">
  <div class='q_page'>
    {{ bib.test  }} - {{ getFirstUpcaseLetter(bib.title) }} |
    <router-link :to="{ name: 'EditBib', params: { id: bib.id }}">
      <b>{{ bib.title }}</b>
    </router-link>
    ({{ bib.position }}) | {{ bib.lang }}
  </div>
</div>
</template>

<style scoped>
</style>
