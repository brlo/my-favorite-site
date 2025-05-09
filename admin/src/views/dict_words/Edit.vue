<script setup>
import { ref, computed } from "vue";
import Tiptap from "@/components/Tiptap.vue";
import router from "@/router/index";
import Dropdown from 'primevue/dropdown';
import InputText from 'primevue/inputtext';
import Button from 'primevue/button';
import Textarea from 'primevue/textarea';
import AutocompleteDictWord from "@/components/AutocompleteDictWord.vue";

import { useToast } from "primevue/usetoast";
import { api } from '@/libs/api.js';

const toast = useToast();
const toastError = (t, msg) => { toast.add({ severity: 'error', summary: t, detail: msg, life: 5000 }) }
const toastSuccess = (t, msg) => { toast.add({ severity: 'success', summary: t, detail: msg, life: 5000 }) }
const toastInfo = (t, msg) => { toast.add({ severity: 'info', summary: t, detail: msg, life: 5000 }) }

const props = defineProps({
  id: String,
  currentUser: Object,
})

// Параметры из URL query
const urlParams = new URLSearchParams(window.location.search);
const wordFromParam = urlParams.get('word')

const errors = ref('');
const dictWord = ref({word: wordFromParam});
const wordsWaitings = ref();
const lexemasWaitings = ref();
const listDict = ref();

// переменная для установки текста в редакторе
// редактор подгрузит данные в себя и затрёт эту перменную.
// Если опять надо изменить текст в редакторе, то опять задай текст в эту перменную
const sendTextToEditor = ref('')


// ПОЛУЧАЕМ СЛОВО
function getDictWord() {
  api.get(`/dict_words/${props.id}`).then(data => {
    console.log(data);
    dictWord.value = data.item;
    sendTextToEditor.value = data.item.desc;
  })
}

if (props.id) {
  getDictWord();
}

// ПОЛУЧАЕМ СПИСОК ОЖИДАЮЩИХ ОПРЕДЕЛЕНИЯ СЛОВ
function getWordsWaitings() {
  const dict = listDict.value;
  api.get(`/dict_words/list_waitings`, { dict }).then(data => {
    console.log(data);
    wordsWaitings.value = data.items.words;
    lexemasWaitings.value = data.items.lexemas;
  })
}
getWordsWaitings();

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
  { name: '', code: '' },
  { name: 'Вейсман GR-RU', code: 'w' },
  { name: 'Дворецкий GR-RU', code: 'd' },
  { name: 'Bibleox', code: 'bbx' },
  { name: 'Test JP-RU', code: 't' },
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
      toastSuccess('Успех', 'Слово создано');
      errors.value = '';
      if (dictWord.value.id) {
        // а после обновления возвращаемся к общему списку слов
        router.push({ name: 'DictWords' });
      } else {
        // после создания, даём возможность добавить новое слово в этот же словарь
        dictWord.value = {dict: data.item.dict};
        sendTextToEditor.value = '';
      }
      // обновляем список слов ожидающих опредения
      getWordsWaitings();
    } else {
      toastError('Ошибка', 'Не удалось создать слово');
      console.log('FAIL!', data);
      errors.value = data;
    }
  })
}

function destroy() {
  if(confirm("Удалить слово? \n" + dictWord.value.word)){
    api.delete(`/dict_words/${dictWord.value.id}`).then(data => {
      if (data.success == 'ok') {
        toastSuccess('Успех', 'Слово удалено');
        errors.value = '';
        router.push({ name: "DictWords" });
      } else {
        console.log('FAIL!', data);
        toastError('Ошибка', 'Не удалось удалить слово');
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
    <AutocompleteDictWord v-model="dictWord.word" fetchKey="word" placeholder="Слово" />
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

  <div class="field">
    <label>Перевод одним словом</label>
    <InputText v-model="dictWord.translation_short" placeholder="Перевод" />
  </div>

  <div class="field">
    <label>Другие переводы</label>
    <Textarea v-model="dictWord.translation" autoResize rows="1" cols="30"  placeholder="Другие переводы" />
  </div>

  <div class="field">
    <label>Описание:</label>
    <tiptap v-model="sendTextToEditor" @change="(d) => { dictWord.desc = d; }" />
  </div>

  <div class="group-fields">
    <div class="field">
      <label>Синоним</label>
      <InputText v-model="dictWord.sinonim" placeholder="Синоним" />
    </div>
    <div class="field">
      <label>Лексема</label>
      <InputText v-model="dictWord.lexema" placeholder="Лексема" />
    </div>
  </div>

  <div v-if="!dictWord.id">
    <hr/>
    <Button @click.prevent="getWordsWaitings" label="Обновить список ожиданий"/>
    <div class="field">
      <label>Недостающие слова из словаря:</label>
      <Dropdown
        v-model="listDict"
        :options="dicts"
        optionLabel="name"
        optionValue="code"
        placeholder="Словарь"
      />
    </div>

    <div class="words-hints">
      <div class="words-waitings">
        <div class="word-waiting">Слова:</div>
        <div v-for="word in wordsWaitings" class="word-waiting">
          <a @click.prevent="dictWord = {dict: 'w', word: word.word}">{{ word.word }}</a>
          <i>{{ word.counts }}</i>
        </div>
      </div>

      <div class="words-waitings">
        <div class="word-waiting">Лексемы:</div>
        <div v-for="word in lexemasWaitings" class="word-waiting">
          <a @click.prevent="dictWord = {dict: 'w', word: word.word}">{{ word.word }}</a>
          <i>{{ word.counts }}</i>
        </div>
      </div>
    </div>

  </div>
</div>
</template>

<style scoped>
.words-waitings {
  display: inline-block;
  vertical-align: top;
  max-width: 300px;
  margin: 10px 0;
}

.word-waiting {
  font-size: 2.3rem;
  margin: 5px 0;
}

.word-waiting a {
  cursor: pointer;
}

.word-waiting i {
  margin: 0 10px;
  font-size: 1rem;
  color: #aaa;
}
</style>
