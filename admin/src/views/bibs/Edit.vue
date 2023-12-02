<script setup>
import { ref } from 'vue'
import Tiptap from "@/components/Tiptap.vue"

const props = defineProps({
  id: String
})

const position = ref(10)
const subject = ref('A')
const title = ref('')
const meta = ref('')
const url = ref('')
const text = ref('123')

const subjects = ref([
  { text: 'One', value: 'A' },
  { text: 'Two', value: 'B' },
  { text: 'Three', value: 'C' }
])

// console.log('props', props.id)
</script>

<template>
<router-link :to="{ name: 'Bibs'}">← Назад</router-link>

<h1>Редактирование статьи</h1>

<input type="submit" value="Применить изменения" class="pretty btn"/>

<p>
  <label>Позиция</label>
  <input v-model="position" type="number" />
</p>

<p>
  <label>Заголовок</label>
  <input v-model="title" type="text" />
</p>

<p>
  <label>Тема</label>
  <select v-model="subject">
  <option v-for="subj in subjects" :value="subj.value">
    {{ subj.text }}
  </option>
</select>
</p>

<p>
  <label>Meta-описание</label>
  <textarea v-model="meta" />
</p>

<p>
  <label>URL-путь</label>
  <input v-model="url" type="text" />
</p>

<p>
  <label>Статья: {{text}}</label>
  <tiptap :content="text" @change="(d) => { text = d; }"/>
</p>
</template>
