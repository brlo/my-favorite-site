<script setup>
import { ref, computed } from "vue";
import Tiptap from "@/components/Tiptap.vue";
import router from "@/router/index";
import EditMenu from "@/components/EditMenu.vue";
import AutocompletePage from "@/components/AutocompletePage.vue";
import IndexMergeRequests from "@/views/merge_requests/Index.vue";
import InputSwitch from 'primevue/inputswitch';
import Dropdown from 'primevue/dropdown';
import InputText from 'primevue/inputtext';
import Checkbox from 'primevue/checkbox';
import Button from 'primevue/button';
import SplitButton from 'primevue/splitbutton';
import Textarea from 'primevue/textarea';
import FileUpload from 'primevue/fileupload';
import { getCookie } from '@/libs/cookies'

import { api } from '@/libs/api.js';

const apiUrl = import.meta.env.VITE_API_URL

// <div v-if="false" class="field">
//   <label>Тэги (через запятую)</label>
//   <Chips v-model="page.tags_str" separator="," placeholder="Тэги (через запятую)" />
// </div>

// import InputNumber from 'primevue/inputnumber';
// <div class="field">
//   <label for="page-priority">Приоритет (не обязательно)</label>
//   <InputNumber v-model="page.priority" inputId="page-priority" placeholder="Приоритет" />
// </div>


import ConfirmDialog from 'primevue/confirmdialog';
import { useConfirm } from "primevue/useconfirm";
const pconfirm = useConfirm();

import Dialog from 'primevue/dialog';


import { useToast } from "primevue/usetoast";
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
const pathFromParam = urlParams.get('page_path')
const langFromParam = urlParams.get('lang')

const errors = ref('');
const page = ref({page_type: 1, path: pathFromParam, lang: langFromParam || 'ru', is_published: true});
const mr = ref({});
const user = ref();
const isCreateMRVisible = ref()

// переменная для установки текста в редакторе
// редактор подгрузит данные в себя и затрёт эту перменную.
// Если опять надо изменить текст в редакторе, то опять задай текст в эту перменную
const sendTextToBody = ref('')
const sendTextToReferences = ref('')

let pageMenu = null

// СТАТЬЯ
function getPage() {
  api.get(`/pages/${props.id}`).then(data => {
    page.value = data.item;
    sendTextToBody.value = data.item.body;
    sendTextToReferences.value = data.item.references;
    pageMenu = data.menu
  })
}

if (props.id) {
  getPage();
}

const userClean = () => user.value = { privs: {} };

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

// ЯЗЫКИ
const langs = [
  { name: '🇷🇺 RU', code: 'ru' },
  { name: '🇺🇸 EN', code: 'en' },
  { name: '🇬🇷 GR', code: 'gr' },
  { name: '🇮🇱 IL', code: 'il' },
  { name: '🇪🇬 AR', code: 'ar' },
  { name: '🇯🇵 JP', code: 'jp' },
  { name: '🇨🇳 CN', code: 'cn' },
  { name: '🇩🇪 DE', code: 'de' },
]

const pageTypes = [
  { name: 'Статья', code: 1 },
  { name: 'Список', code: 4 },
  // { name: 'Комментарий на библ. стих', code: 3 },
  { name: 'Книга с разбивкой на стихи', code: 5 },
]

const editModes = [
  { name: 'Админы', code: 1 },
  { name: 'Модераторы', code: 2 },
  { name: 'Автор и редакторы', code: 3 },
]

const editModesDesc = {
  1: 'Редактировать могут только админы.',
  2: 'Редактировать могут только админы и модераторы.',
  3: 'Редактировать могут админы, модераторы, автор статьи и редакторы (те, от кого одобрена хотя бы одна правка к этой статье).',
}

const pageTypesDesc = {
  1: 'Просто какая-то статья. Обычно, статья — это разбор какого-то поняти или одной темы.',
  3: 'Библейский стих — это режим публикации апологетичиских разборов того или иного стиха Библии. В названии статьи надо указать только адрес библейского стиха: Быт. 1:5. Тогда он привяжется к стиху на сайте и каждый увидит, что к данному стиху есть комментарий.',
  4: 'Список — это режим публикации статьи, к которой можно добавить меню из ссылок на другие статьи. Эта возможность появится только после создания статьи-списка и повторного перехода к редактированию статьи.',
  5: 'Книга стихами — режим публикации небольших книг (например, древних писателей). Книга автоматически разобъётся на стихи.',
}

let seen = computed(() => {
  return (props.id == undefined || page.value.id) ? true : false;
})

let seenMenu = computed(() => {
  return (page.value.id && page.value.page_type == '4') ? true : false
})

function submit() {
  let httpMethod = '', path = '';
  if (page.value.id) {
    httpMethod = 'put'
    path = `/pages/${page.value.id}/`
  } else {
    httpMethod = 'post'
    path = '/pages/'
  }

  api[httpMethod](path, { page: page.value }).then(data => {
    console.log(data)
    if (data.success == 'ok') {
      page.value = data.item;
      sendTextToBody.value = data.item.body;
      sendTextToReferences.value = data.item.references;
      toastSuccess('Успех', 'Статья создана');
      errors.value = '';
      router.push({ name: 'Pages' });
    } else {
      toastError('Ошибка', 'Не удалось создать статью');
      console.log('FAIL!', data);
      errors.value = data.errors ? data.errors : data;
    }
  })
}

function submitToReview() {
  // прячем окошко с вопросом
  isCreateMRVisible.value = false;

  const params = { mr: { comment: mr.value.comment }, page: page.value }
  api.post('/merge_requests', params).then(data => {
    console.log(data)
    if (data.success == 'ok') {
      toastSuccess('Успех', 'Статья отправлена на проверку');
      errors.value = '';
      router.push({ name: 'ShowMergeRequest', params: { id: data.item.id } });
    } else {
      toastError('Ошибка', 'Не удалось отправить изменения на проверку');
      console.log('FAIL!', data);
      errors.value = data.errors ? data.errors : data;
    }
  })
}

function destroy() {
  pconfirm.require({
    message: 'Точно хотите удалить статью с названием: "' + page.value.title + '"?',
    header: 'Удаление статьи',
    acceptLabel: 'Да', rejectLabel: 'Нет',
    rejectClass: 'p-button-text p-button-text',
    acceptClass: 'p-button-danger p-button-text',
    icon: 'pi pi-exclamation-triangle',
    accept: () => {
      api.delete(`/pages/${page.value.id}`).then(data => {
        if (data.success == 'ok') {
          toastSuccess('Успех', 'Статья удалена');
          errors.value = '';
          router.push({ name: "Pages" });
        } else {
          console.log('FAIL!', data);
          toastError('Ошибка', 'Не удалось удалить статью');
          errors.value = data.errors ? data.errors : data;
        }
      })
    }
  })
}

function restore() {
  pconfirm.require({
    message: 'Точно хотите восстановить статью с названием: "' + page.value.title + '"?',
    header: 'Восстановление статьи',
    acceptLabel: 'Да', rejectLabel: 'Нет',
    rejectClass: 'p-button-text p-button-text',
    acceptClass: 'p-button-danger p-button-text',
    icon: 'pi pi-exclamation-triangle',
    accept: () => {
      api.post(`/pages/${page.value.id}/restore`).then(data => {
        if (data.success == 'ok') {
          page.value = data.item;
          toastSuccess('Успех', 'Статья восстановлена!');
          errors.value = '';
        } else {
          console.log('FAIL!', data);
          toastError('Ошибка', 'Не удалось восстановить статью');
          errors.value = data.errors ? data.errors : data;
        }
      })
    }
  })
}

function onBeforeCoverSend(event) {
  // плагин prime сам загружает картинку на сервер, показывает процесс загрузки.
  // но мы должны задать в шапке токен для авторизации на сервере.
  // поэтому понадобился этот хук в колбэке перед запросом:
  return event.xhr.setRequestHeader('X-API-TOKEN', getCookie('api_token'));
}

// Ответ после загрузки картинки для шапки
function onCoverUpload(event) {
  if (event.xhr.status === 200) {
    let responseJson = JSON.parse(event.xhr.responseText);
    if (responseJson.success == 'ok') {
      page.value.cover = responseJson.cover;
    }
  } else {
    console.log('Error in onCoverUpload, event.xhr:', event.xhr)
  }
  return true;
}

// удаление картинки для шапки
function clickRemoveCover() {
  pconfirm.require({
    message: '',
    header: 'Удалить изображение для шапки?',
    acceptLabel: 'Да', rejectLabel: 'Нет',
    rejectClass: 'p-button-text p-button-text',
    acceptClass: 'p-button-danger p-button-text',
    accept: () => {
      api.post(`/pages/${page.value.id}/cover`, {file: null}).then(data => {
        if (data.success == 'ok') {
          page.value.cover = data.cover;
          toastSuccess('Удалено', 'Изображение для шапки удалено!');
          errors.value = '';
        } else {
          console.log('FAIL!', data);
          toastError('Ошибка', 'Не удалось удалить изображение для шапки');
          errors.value = data.errors ? data.errors : data;
        }
      })
    }
  })
  return true;
}

const submitBtnItems = [
  {
    label: 'Сохранить',
    icon: 'pi pi-check',
    command: () => {
      submit()
    }
  },
];

function addLink() {
  page.value.links.push(['', '']);
};
function removeLink(index) {
  page.value.links.splice(index, 1);
};
</script>

<template>
<ConfirmDialog/>
<Toast />

<Dialog v-model:visible="isCreateMRVisible" modal header="Отправка на проверку" :style="{ width: '25rem' }">
    <div class="field">
      <label for="mr-comment">Пояснительный комментарий:</label>
      <Textarea v-model="mr.comment" id="mr-comment" autoResize rows="1" cols="30" autocomplete="off" />
    </div>
    <div class="field">
      <label>Правки будут отправлены на проверку. Продолжить?</label>
      <Button type="button" label="Отмена" severity="secondary" @click="isCreateMRVisible = false" style="margin-right: 10px;"/>
      <Button type="button" label="Отправить!" @click="submitToReview" />
    </div>
</Dialog>

<router-link :to="{ name: 'Pages'}">← Назад</router-link>
<a style='margin: 0 10px;' v-if="page.id" :href="`${apiUrl}/${page.lang}/${page.lang}/w/${page.path}`">Статья на сайте</a>

<h1 v-if="page.id">Редактирование статьи</h1>
<h1 v-else>Новая статья</h1>

<h2 v-if="page.is_deleted" class="page-deleted-label">СТАТЬЯ УДАЛЕНА!</h2>

<IndexMergeRequests v-if="page.id" :pageId="page.id" :isPartial="true"/>

<div class="flex action-bar">
  <Button v-if="!page.id" @click.prevent="submit" label="Опубликовать статью" icon="pi pi-check" />
  <SplitButton
    v-else-if="currentUser?.privs?.pages_create"
    label="Предложить правки"
    icon="pi pi-send"
    @click="isCreateMRVisible = true"
    :model="submitBtnItems"
    :disabled="page.is_deleted"
  />
  <Button v-else @click.prevent="isCreateMRVisible = true" label="Предложить правки" icon="pi pi-check" />


  <div class="field fields-published">
    <label for="page-published" id="label-is-page-published">
      {{ page.is_published ? 'Доступно для чтения' : 'Скрыто' }}
    </label>
    <InputSwitch v-model="page.is_published" :disabled="page.is_deleted" inputId="page-published"/>
  </div>

  <Button v-if="page.id && !page.is_deleted" @click.prevent="destroy" label="Удалить" text severity="danger" style='margin-left: auto' icon="pi pi-trash" />
  <Button v-if="page.id && page.is_deleted" @click.prevent="restore" label="Восстановить" text style='margin-left: auto' icon="pi pi-undo" />
</div>

<div class="errors">{{ errors }}</div>

<div v-if="seen" class="form">
  <div v-if="user.privs.super">
    <div class="field">
      <label>Тип документа</label>
      <Dropdown
        v-model="page.page_type"
        :options="pageTypes"
        optionLabel="name"
        optionValue="code"
        placeholder="Тип документа"
        :disabled="page.is_deleted"
      />
    </div>

    <div class="field-hint">
      {{ pageTypesDesc[page.page_type] }}
    </div>
  </div>

  <div class="field">
    <label>Заголовок</label>
    <Textarea v-model="page.title" placeholder="Заголовок" class="page-field-title" :disabled="page.is_deleted" autoResize rows="1" cols="30" />
  </div>

  <div class="field">
    <label>Подзаголовок (не обязательно)</label>
    <Textarea v-model="page.title_sub" placeholder="Подзаголовок" class="page-field-subtitle" :disabled="page.is_deleted" autoResize rows="1" cols="30" />
  </div>

  <div v-if="user.privs.super" class="field">
    <label>Адрес (название статьи в URL)</label>
    <InputText v-model="page.path" placeholder="Адрес" :disabled="page.is_deleted" />
  </div>

  <div v-if="user.privs.super" class="group-fields">
    <div class="field">
      <label>ID родителя (не обязательно)</label>
      <AutocompletePage v-model="page.parent_id" fetchKey="id" :disabled="page.is_deleted" />
    </div>
  </div>

  <div v-if="seenMenu" class="tree-menu">
    <EditMenu :pageId="page.id" :pageMenu="pageMenu"/>
  </div>

  <div class="field">
    <label>Статья:</label>
    <tiptap v-model="sendTextToBody" @change="(d) => { page.body = d; }" :disabled="page.is_deleted" />
  </div>

  <div class="field">
    <label>Примечания:</label>
    <tiptap v-model="sendTextToReferences" @change="(d) => { page.references = d; }" :disabled="page.is_deleted" />
  </div>

  <div v-if="user.privs.super">
    <div class="field">
      <label>Кто может редактировать</label>
      <Dropdown
        v-model="page.edit_mode"
        :options="editModes"
        optionLabel="name"
        optionValue="code"
        placeholder="Кто редактирует"
        :disabled="page.is_deleted"
      />
    </div>

    <div class="field-hint">
      {{ editModesDesc[page.edit_mode] }}
    </div>
  </div>

  <div v-if="user.privs.super" class="group-fields">
    <div class="field">
      <label>Язык статьи</label>
      <Dropdown
        v-model="page.lang"
        :options="langs"
        optionLabel="name"
        optionValue="code"
        placeholder="Язык статьи"
        :disabled="page.is_deleted"
      />
    </div>

    <div class="field">
      <label>ID для группировки переводов (не обязательно)</label>
      <AutocompletePage v-model="page.group_lang_id" fetchKey="group_lang_id" :disabled="page.is_deleted" />
    </div>
  </div>

  <div v-if="user.privs.super" class="group-fields">
    <div class="field">
      <label>Описание для поискововой системы</label>
      <Textarea v-model="page.meta_desc" placeholder="Meta-описание" :disabled="page.is_deleted" autoResize rows="1" cols="30" />
    </div>
  </div>

  <div v-if="user.privs.super" class="group-fields">
    <div class="field">
      <label>Аудио-файл (не обязательно)</label>
      <InputText v-model="page.audio" placeholder="Аудио-файл" :disabled="page.is_deleted" />
    </div>
  </div>

  <div v-if="user.privs.super" class="group-fields">
    <div class="field">
      <label for="issearch">Поисковое поле</label>
      <Checkbox v-model="page.is_search" inputId="issearch" :binary="true" />
    </div>
  </div>

  <div v-if="user.privs.super" class="group-fields">
    <div class="field">
      <label for="isshowparent">Показывать родителя над заголовком?</label>
      <Checkbox v-model="page.is_show_parent" inputId="isshowparent" :binary="true" />
    </div>
  </div>

  <div v-if="user.privs.super" class="group-fields">
    <h2>Изображение для шапки</h2>
    <div v-if="page.cover" class="cover">
      <img :src="page.cover?.large"/>
      <div class="cover-btn-rm">
        <Button v-if="page.cover?.large"
          @click.prevent="clickRemoveCover"
          label="Удалить изображение для шапки"
          text
          severity="danger"
          icon="pi pi-trash" />
      </div>
    </div>

    <div class="field">
      <FileUpload name="file" :url="`${apiUrl}/ru/api/pages/${id}/cover`" @upload="onCoverUpload($event)" :onBeforeSend="onBeforeCoverSend" :multiple="false" accept="image/*" :maxFileSize="9000000">
        <template #empty>
          <p>Перенесите сюда файл для загрузки.</p>
        </template>
      </FileUpload>
    </div>
  </div>

  <div class="field">
    <h2>Ссылки (сразу под названием)</h2>
    <div v-for="(link, index) in page.links" :key="index">
      <InputText v-model="link[0]" placeholder="Название ссылки" class="link-name"/>
      <AutocompletePage v-model="link[1]" fetchKey="path" placeholder="Ссылка" :disabled="page.is_deleted" class="link-path"/>
      <Button @click.prevent="removeLink(index)" label="Удалить" text severity="danger" class="link-btn-rm"/>
    </div>
    <Button @click.prevent="addLink" label="Добавить ссылку" />
  </div>

</div>
</template>

<style scoped>
.link-name, .link-path, .link-btn-rm {
  margin: 0 5px 5px 0;
}

.cover {
  margin: 10px 0;
}

.cover img {
  max-width: 100%;
}

h1 {
  margin: 15px 0;
}

h2 {
  width: 100%;
  margin: 15px 0 5px 0;
  border-bottom: 1px solid grey;
}

.fields-published {
  margin: 0 0 0 15px;
}

.fields-published label {
  display: block;
  font-size: 0.75em;
  padding: 0;
  margin: 3px 0;
}

.field-hint {
  font-size: 0.6em;
  margin: 0 0 20px 0;
  min-height: 20px;
  max-width: 500px;
}

.page-field-title {
  width: 100%;
}
.page-field-subtitle {
  width: 100%;
}
.p-chips-input-token input[type='text'] {
  border-width: 0 !important;
}

.page-deleted-label {
  background-color: #e1e1e1;
  color: #555;
  border-radius: 5px;
  padding: 50px 10px;
  text-align: center;
}
</style>
