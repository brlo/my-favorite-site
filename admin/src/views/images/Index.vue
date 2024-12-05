<script setup>
import { ref, watchEffect } from 'vue';
import {_} from 'vue-underscore';
import { api } from '@/libs/api.js';
import InputText from 'primevue/inputtext';
import IconField from 'primevue/iconfield';
import InputIcon from 'primevue/inputicon';
import FileUpload from 'primevue/fileupload';
import { getCookie } from '@/libs/cookies'

import ConfirmDialog from 'primevue/confirmdialog';
import { useConfirm } from "primevue/useconfirm";
const pconfirm = useConfirm();

import { useToast } from "primevue/usetoast";
const toast = useToast();

const toastError = (t, msg) => { toast.add({ severity: 'error', summary: t, detail: msg, life: 5000 }) }
const toastSuccess = (t, msg) => { toast.add({ severity: 'success', summary: t, detail: msg, life: 5000 }) }
const toastInfo = (t, msg) => { toast.add({ severity: 'info', summary: t, detail: msg, life: 5000 }) }


const apiUrl = import.meta.env.VITE_API_URL

const props = defineProps({
  isListOnly: Boolean,
  limit: Number,
  currentUser: Object,
})

const user = ref();
const image = ref({title: ''});

const searchTerm = ref('')

const images = ref({})
const isLoading = ref(false)
const errors = ref('')

// _ через функцию debounce откладывает все попытки выполнить указанную функцию
// на 300 сек, превращая все эти попытки в одну.
const lazyAutoSearch = _.debounce(autoSearch, 300);
function autoSearch() {
  isLoading.value = true;
  let params = { term: searchTerm.value };
  if (props.limit) params.limit = props.limit;
  api.get('/images/list', params).then(data => {
    isLoading.value = false;
    console.log(data)
    if (data.success == 'ok') {
      images.value = data.items;
    } else {
      errors.value = data.errors;
    }
  })
}

// Авторизуемся
function getUser() {
  api.get('/users/me').then(data => {
    console.log('GET User', data)
    if (data.success == 'ok') {
      user.value = data;
    } else {
      userClean();
    }
  })
}

if (props.currentUser) {
  user.value = props.currentUser;
} else {
  userClean();
  getUser();
}

// Загружаем картинку
function onBeforeImgSend(event) {
  // плагин prime сам загружает картинку на сервер, показывает процесс загрузки.
  // но мы должны задать в шапке токен для авторизации на сервере.
  // поэтому понадобился этот хук в колбэке перед запросом:
  return event.xhr.setRequestHeader('X-API-TOKEN', getCookie('api_token'));
}

// Ответ после загрузки картинки для шапки
function onImgUpload(event) {
  if (event.xhr.status === 200) {
    let responseJson = JSON.parse(event.xhr.responseText);
    if (responseJson.success == 'ok') {
      // image.value.simple = responseJson.simple;
      window.location = window.location.href;
    }
  } else {
    console.log('Error in onCoverUpload, event.xhr:', event.xhr)
  }
  return true;
}

// Удалить
function onDestroy(imgId) {
  console.log(imgId);
  pconfirm.require({
    message: 'Точно хотите удалить картинку с id: "' + imgId + '"?',
    header: 'Удаление картинки',
    acceptLabel: 'Да', rejectLabel: 'Нет',
    rejectClass: 'p-button-text p-button-text',
    acceptClass: 'p-button-danger p-button-text',
    icon: 'pi pi-exclamation-triangle',
    accept: () => {
      api.delete(`/images/${imgId}`).then(data => {
        if (data.success == 'ok') {
          toastSuccess('Успех', 'Картинка удалена');
          errors.value = '';
        } else {
          console.log('FAIL!', data);
          toastError('Ошибка', 'Не удалось удалить картинку');
          errors.value = data.errors ? data.errors : data;
        }
      })
    }
  })
  return true;
}

// Обновить
// function onUpdate(imgId) {
//   console.log(imgId);

//   api.put(`/images/${imgId}`, {name: name}).then(data => {
//     if (data.success == 'ok') {
//       toastSuccess('Успех', 'Картинка обновлена');
//       errors.value = '';
//     } else {
//       console.log('FAIL!', data);
//       toastError('Ошибка', 'Не удалось обновить картинку');
//       errors.value = data.errors ? data.errors : data;
//     }
//   })

//   return true;
// }

watchEffect(
  function() {
    if (searchTerm.value.length == 0 || searchTerm.value.length > 2) lazyAutoSearch();
  }
)
</script>

<template>
<ConfirmDialog/>
<Toast />

<h2 v-if="isListOnly">Недавно изменённые картинки</h2>
<h2 v-else="isListOnly">Картинки</h2>

<div v-if="user.privs.super" class="group-fields">
  <div class="field">
    <label>Название</label>
    <InputText v-model="image.title" placeholder="Название" />
  </div>
</div>

<div v-if="user.privs.super" class="group-fields">
  <div class="field">
    <FileUpload name="file" :url="`${apiUrl}/ru/api/images/`" @upload="onImgUpload($event)" :onBeforeSend="onBeforeImgSend" :multiple="false" accept="image/*" :maxFileSize="9000000">
      <template #empty>
        <p>Перенесите сюда файл для загрузки.</p>
      </template>
    </FileUpload>
  </div>
</div>

<div v-if="!isListOnly" style="margin: 10px 0 20px 0">
  <IconField iconPosition="left">
    <InputIcon :class="`pi ${ isLoading ? 'pi-spin pi-spinner' : 'pi-search' }`" />
    <InputText v-model="searchTerm" placeholder='Фильтр' autofocus autocomplete="off" id="search-field" />
  </IconField>
</div>

<div v-if="images.length == 0">
  <div class='image'>Ничего не найдено</div>
</div>

<div id="images">
  <div class="image" v-for="image in images">
    <a :href="image.urls.m"><img :src="image.urls?.s" /></a>
    [<a :href="image.urls.m">крупнее</a>]
    <br>
    <br>
    <InputText placeholder="Название" autocomplete="off" :value="image.title" />
    <br>
    <a>Обновить</a> |
    <a @click="onDestroy(image.id)">Удалить</a>
  </div>
</div>
<div v-if="errors.length">{{ errors }}</div>
</template>

<style scoped>
#images {
  display: flex;
  flex-wrap: wrap;
}
.image {
  display: inline-block;
  max-width: 200px;
  background-color: #f0f0f0;
  padding: 10px;
  margin: 5px;
  text-align: center;
}

.image img {
  width: 100%;
  display: block;
}
.image input {
  margin: 5px 0;
  max-width: 180px;
}
</style>
