<script setup>
import { ref, computed } from "vue";
import Tiptap from "@/components/Tiptap.vue";
import router from "@/router/index";
import Dropdown from 'primevue/dropdown';
import InputText from 'primevue/inputtext';
import Button from 'primevue/button';

import { useToast } from "primevue/usetoast";
import { api } from '@/libs/api.js';

const toast = useToast();
const toastError = (t, msg) => { toast.add({ severity: 'error', summary: t, detail: msg, life: 5000 }) }
const toastSuccess = (t, msg) => { toast.add({ severity: 'success', summary: t, detail: msg, life: 5000 }) }
const toastInfo = (t, msg) => { toast.add({ severity: 'info', summary: t, detail: msg, life: 5000 }) }

const props = defineProps({
  id: String
})

const errors = ref('');
const dictWord = ref({})


// СТАТЬЯ
function getDictWord() {
  api.get(`/dict_words/${props.id}`).then(data => {
    console.log(data)
    dictWord.value = data.item
  })
}

if (props.id) {
  getDictWord();
}

// ЯЗЫКИ
// const langs = [
//   { name: '🇷🇺 RU', code: 'ru' },
//   { name: '🇺🇸 EN', code: 'en' },
//   { name: '🇬🇷 GR', code: 'gr' },
//   { name: '🇮🇱 IL', code: 'il' },
//   { name: '🇪🇬 AR', code: 'ar' },
//   { name: '🇯🇵 JP', code: 'jp' },
//   { name: '🇨🇳 CN', code: 'cn' },
//   { name: '🇩🇪 DE', code: 'de' },
// ]

const dicts = [
  { name: 'Test JP-RU', code: 't' },
  { name: 'Дворецкий GR-RU', code: 'd' },
  { name: 'Вейсман GR-RU', code: 'w' },
]

let seen = computed(() => {
  return (props.id == undefined || dictWord.value.id) ? true : false;
})

function submit() {
  let httpMethod = '', path = '';
  if (dictWord.value.id) {
    httpMethod = 'put'
    path = `/dict_words/${dictWord.value.id}/`
  } else {
    httpMethod = 'post'
    path = '/dict_words/'
  }

  api[httpMethod](path, { dict_word: dictWord.value }).then(data => {
    console.log(data)
    if (data.success == 'ok') {
      dictWord.value = data.item;
      toastSuccess('Успех', 'Статья создана');
      errors.value = '';
      router.push({ name: 'DictWords' });
    } else {
      toastError('Ошибка', 'Не удалось создать статью');
      console.log('FAIL!', data);
      errors.value = data;
    }
  })
}

function destroy() {
  if(confirm("Удалить статью? \n" + dictWord.value.title)){
    api.delete(`/dict_words/${dictWord.value.id}`).then(data => {
      if (data.success == 'ok') {
        toastSuccess('Успех', 'Статья удалена');
        errors.value = '';
        router.push({ name: "DictWords" });
      } else {
        console.log('FAIL!', data);
        toastError('Ошибка', 'Не удалось удалить статью');
        errors.value = data;
      }
    })
  }
}
</script>

<template>
<Toast />
<router-link :to="{ name: 'DictWords'}">← Назад</router-link>

<h1 v-if="dictWord.id">Редактирование слова</h1>
<h1 v-else>Новое слово</h1>

<div class="flex action-bar">
  <Button @click.prevent="submit" :label="`${ dictWord.id ? 'Сохранить' : 'Создать' } слово`" icon="pi pi-check" />

  <Button v-if="dictWord.id" @click.prevent="destroy" label="Удалить" text severity="danger" style='margin-left: auto' icon="pi pi-trash" />
</div>

<div class="errors">{{ errors }}</div>

<div v-if="seen" class="form">
  <div class="field">
    <label>Словарь</label>
    <Dropdown
      v-model="dictWord.dict"
      :options="dicts"
      optionLabel="name"
      optionValue="code"
      placeholder="Словарь"
    />
  </div>

  <div class="field">
    <label>Слово</label>
    <InputText v-model="dictWord.word" placeholder="Слово" />
  </div>

  <div class="group-fields">
    <div class="field">
      <label>Транскрипция</label>
      <InputText v-model="dictWord.transcription" placeholder="Транскрипция" />
    </div>
    <div class="field">
      <label>Транскрипция (латиницей)</label>
      <InputText v-model="dictWord.transcription_lat" placeholder="Транскрипция lat" />
    </div>
  </div>

  <div class="field">
    <label>Главный признак</label>
    <InputText v-model="dictWord.tag" placeholder="Главный признак" />
  </div>

  <div class="group-fields">
    <div class="field">
      <label>Перевод одним словом</label>
      <InputText v-model="dictWord.translation_short" placeholder="Перевод" />
    </div>
    <div class="field">
      <label>Другие переводы</label>
      <InputText v-model="dictWord.translation" placeholder="Другие переводы" />
    </div>
  </div>

  <div class="field">
    <label>Описание:</label>
    <tiptap :content="dictWord.desc" @change="(d) => { dictWord.desc = d; }"/>
  </div>
</div>
</template>

<style scoped>
</style>
