<script setup>
import { ref } from 'vue';
import { api } from '@/libs/api.js';

let pages = ref({})
let errors = ref('')

api.get('/pages/list').then(data => {
  console.log(data)
  if (data.success == 'ok') {
    pages.value = data.items;
  } else {
    errors.value = data.errors;
  }
})
</script>

<template>
<div v-if="pages.length" class="block">
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

<div v-if="errors.length" class="block">{{ errors }}</div>
</template>

<style scoped>
.block {
  margin: 0 0 30px 0;
}
</style>
