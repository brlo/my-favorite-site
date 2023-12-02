<script setup>
import Tiptap from "@/components/Tiptap.vue";
</script>

<template>
<router-link :to="{ name: 'Bibs'}">← Назад</router-link>
<h1>Новая статья</h1>
<p>
  <label>Позиция</label>
  <input type="text" />
</p>
<p>
  <tiptap />
</p>
</template>
