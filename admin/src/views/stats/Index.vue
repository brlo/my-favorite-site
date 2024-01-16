<script setup>
import { ref } from 'vue';
import { api } from '@/libs/api.js';

let stats = ref({})
let errors = ref()

function getStats() {
  api.get('/stats/visits').then(data => {
    console.log(data)
    if (data.success == 'ok') {
      stats.value = data.week_visits;
    } else {
      errors.value = data;
    }
  })
}

getStats()
</script>

<template>
<div v-if="stats">
  <h2>Статистика</h2>
  {{ errors }}
  <div class="stats">
    <div v-for="(stat,key) in stats" class="stats-col">
      <div class='title'>{{ key }}:</div>
      <div class="stats-data" v-for="(visits,date) in stat">
        {{ date }}: {{ visits }}
      </div>
    </div>
  </div>
</div>
</template>

<style scoped>
.stats {
  display: flex;
  color: #777;
}
.stats-col {
  min-width: 130px;
  max-width: 180px;
}
.stats .title {
  font-size: 0.8em;
}
.stats-data {
  font-size: 0.6em;
}
</style>
