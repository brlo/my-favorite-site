<script setup>
import { ref } from 'vue'

function getFirstUpcaseLetter(str) {
  str = String(str)
  str = Array.from(str)[0]
  return str.toUpperCase()
}

const quotesPages = [
  {id: 1, title: 'test1', position: 10, lang: 'ru'},
  {id: 10, title: 'BARABA 2', position: 12, lang: 'ru'},
  {id: 15, title: 'GIGAta 5', position: 16, lang: 'ru'},
]

const showBibs = ref(
  ...quotesPages
)
</script>

<template>
<h1>Страницы цитат</h1>
<br>
<router-link :to="{ name: 'NewBib'}">
  ＋ Новая страница
</router-link>
<br>
<br>
<input type='text' class='filter' oninput='window.filterQueryPages(this.value);' value='' placeholder='Фильтр' autofocus>
<br>
<br>
<div id="quotes_pages" v-for="bib in showBibs">
  <div class='q_page'>
    {{ getFirstUpcaseLetter(bib.title) }} |
    <router-link :to="{ name: 'EditBib', params: { id: bib.id }}">
      <b>{{ bib.title }}</b>
    </router-link>
    ({{ bib.position }}) | {{ bib.lang }}
  </div>
</div>
</template>

<style scoped>
</style>
