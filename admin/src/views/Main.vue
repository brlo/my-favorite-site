<script setup>
import { ref } from 'vue';
import { api } from '@/libs/api.js';

let pages = ref({})

api.get('/pages/list').then(data => pages.value = data.items)
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
