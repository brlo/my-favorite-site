<script setup>
import { ref } from "vue"
// import {_} from 'vue-underscore';
import { api } from '@/libs/api.js'
import AutoComplete from 'primevue/autocomplete';

const props = defineProps({
  modelValue: String,
  fetchKey: String,
})

const pageId = ref(props.modelValue)
const pages = ref([])
const errors = ref('')
const isLoading = ref()

const emit = defineEmits(['update'])

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
      const pagesList = [];
      data.items.forEach(page => pagesList.push({name: page.title, obj: page}) );
      pages.value = pagesList;
    } else {
      errors.value = data.errors;
    }
  })
}

// СМОТРИ ВКЛАДКУ API / EMITS в https://primevue.org/autocomplete/
function onUpdate(origEvent) {
  // В origEvent.value лежит объект, который собирали выше, при получении списка статей:
  // { name: 'имя статьи в выпадающем списке', obj: <Object целиком сам объект статьи> }
  emit('update:modelValue', origEvent.value?.obj[props.fetchKey])
}
function onClear() {
  emit('update:modelValue', undefined)
}
</script>

<template>
<AutoComplete
  v-model="pageId"
  optionLabel="name"
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
