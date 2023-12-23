<script setup>
import { ref } from 'vue'
import { getCookie } from '@/libs/cookies.js'

const apiUrl = import.meta.env.VITE_API_URL

let pages = ref({})

const path = `/ru/api/pages/list`
const params = { session_key: 'test' }
const url = apiUrl + path + '?' + new URLSearchParams(params)
const headers = {
  'Accept': 'application/json',
  'Content-Type': 'application/json',
  'X-API-TOKEN': getCookie('api_token')
}
console.log('GET: ' + url)
fetch(url).then(response => response.json())
.then(data => {
  console.log(data.items)
  pages.value = data.items
})

</script>

<template>
<div class="block">
  <h2>Статьи: недавно изменённые</h2>
  <div v-for="page in pages">
    <div class='page'>
      <router-link :to="{ name: 'EditPage', params: { id: page.id }}">
        <b>{{ page.title }}</b>
      </router-link>
      | {{ page.lang }} | {{ page.updated_at_word  }}
    </div>
  </div>
</div>

<div class="block">
  <h2>Комментарии</h2>
  Комментарий 1<br>
  Комментарий 2<br>
  Комментарий 3
</div>
</template>

<style scoped>
.block {
  margin: 0 0 30px 0;
}
</style>
