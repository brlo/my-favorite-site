<script setup>
import { ref } from "vue"
// import {_} from 'vue-underscore';
import { api } from '@/libs/api.js'
import AutoComplete from 'primevue/autocomplete';

// https://vuejs.org/guide/components/v-model.html
const model = defineModel()

const props = defineProps({
  fetchKey: String,
})

const selectedOption = ref(model.value)
const pages = ref([])
const errors = ref('')
const isLoading = ref()

// _ через функцию debounce откладывает все попытки выполнить указанную функцию
// на 300 сек, превращая все эти попытки в одну.
// const lazyAutoSearch = _.debounce(autoSearch, 300);

function autoSearch(event) {
  isLoading.value = true;
  const searchTerm = event.query;

  if (searchTerm.length < 3) return;

  api.get('/pages/list', { term: searchTerm }).then(data => {
    isLoading.value = false;
    console.log(data)
    if (data.success == 'ok') {
      pages.value = data.items;
    } else {
      errors.value = data.errors;
    }
  })
}

// СМОТРИ ВКЛАДКУ API / EMITS в https://primevue.org/autocomplete/
function onUpdate(origEvent) {
  // В origEvent.value лежит выбранный объект из data.items
  model.value = selectedOption.value?.[props.fetchKey];
}
function onClear() {
  model.value = selectedOption.value;
}
</script>

<template>
<AutoComplete
  v-model="selectedOption"
  optionLabel="title"
  :suggestions="pages"
  @complete="autoSearch"
  :delay="300"
  :minLength="3"
  :placeholder="`Выбор статьи (${fetchKey})`"
  emptySearchMessage="Нет результатов"
  @clear="onClear"
  @item-select="onUpdate"
  :loading="isLoading"
/>
</template>

<style scoped>
</style>
