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

// когда что-то выбрали из выпадающего списка
// СМОТРИ ВКЛАДКУ API / EMITS в https://primevue.org/autocomplete/
function onUpdate(origEvent) {
  // Из выбранного в выпадающем списке объекта (page), достаём значение по указанному в props.fetchKey ключу
  // это может быть id, или parent_id, или lang_group_id...
  // В origEvent.value лежит выбранный объект из data.items
  const newVal = origEvent.value ? origEvent.value[props.fetchKey] : '';

  // ТО, ЧТО УЙДЁТ В РОДИТЕЛЬСКИЙ КОМПОНЕНТ
  model.value = newVal;
}

// // когда весь текст стёрли
// function onClear() {
//   model.value = '';
// }
</script>

<template>
<AutoComplete
  v-model="model"
  optionLabel="title"
  :suggestions="pages"
  @complete="autoSearch"
  :delay="300"
  :minLength="3"
  :placeholder="`Выбор статьи (${fetchKey})`"
  emptySearchMessage="Нет результатов"
  @item-select="onUpdate"
  :loading="isLoading"
/>
</template>

<style scoped>
</style>
