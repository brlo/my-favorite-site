<script setup>
import { ref, computed } from 'vue'
import {_} from 'vue-underscore';
import Tiptap from "@/components/Tiptap.vue"
import router from "@/router/index"

const qPage = ref({})
const qSubjects = ref([])

// ТЕМЫ
const path = '/ru/api/quotes_subjects/list'
const url = 'http://bibleox.lan' + path
console.log('GET: ' + url)
fetch(url).then(response => response.json())
.then(data => qSubjects.value = _.map(data.items, function(subj){ return { text: subj.title_ru, value: subj.id } }))

// ЯЗЫКИ
const langs = [
  { text: '🇷🇺 RU', value: 'ru' },
  { text: '🇺🇸 EN', value: 'en' },
  { text: '🇬🇷 GR', value: 'gr' },
  { text: '🇯🇵 JP', value: 'jp' },
]

let seen = computed(() => {
  return (qSubjects.value.length) ? true : false
})

function submit() {
  const path = '/ru/api/quotes'
  const params = { session_key: 'test' }
  const url = 'http://bibleox.lan' + path + '?' + new URLSearchParams(params)
  const headers = {'Accept': 'application/json','Content-Type': 'application/json'}
  const bodyJSON = JSON.stringify({quotes_page: qPage.value})
  console.log('POST: ' + url)
  fetch(url, {method: 'POST', headers: headers, body: bodyJSON})
  .then(response => response.json())
  .then(data => data.success == 'ok' ? router.push({ name: "Bibs" }) : console.log('FAIL!', data))
}
</script>

<template>
<router-link :to="{ name: 'Bibs'}">← Назад</router-link>
<h1>Новая статья</h1>

<button @click.prevent="submit" class="pretty btn">Опубликовать статью</button>

<div v-if="seen" class="form">
  <p>
    <label>Заголовок</label>
    <input v-model="qPage.title" type="text" />
  </p>
  <p>
    <label>Язык</label>
    <select v-model="qPage.lang">
    <option v-for="lang in langs" :value="lang.value">
      {{ lang.text }}
    </option>
  </select>
  </p>
  <p>
    <label>Позиция</label>
    <input v-model="qPage.position" type="number" />
  </p>
  <p>
    <label>Тема</label>
    <select v-model="qPage.s_id">
      <option v-for="subj in qSubjects" :value="subj.value">
        {{ subj.text }}
      </option>
    </select>
  </p>
  <p>
    <label>META-описание</label>
    <input v-model="qPage.meta_desc" type="text" />
  </p>
  <p>
    <label>URL-путь</label>
    <input v-model="qPage.path" type="text" />
  </p>
  <p>
    <label>Статья:</label>
    <tiptap :content="qPage.body" @change="(d) => { qPage.body = d; }"/>
  </p>
</div>
</template>
