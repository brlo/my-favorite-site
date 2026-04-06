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
const titleFromParam = urlParams.get('page_title')
const menuIdFromParam = urlParams.get('menu_id')
const parentIdFromParam = urlParams.get('parent_id')
const pathFromParam = urlParams.get('page_path')
const langFromParam = urlParams.get('lang')

const errors = ref('');
const page = ref({
  page_type: 1,
  title: titleFromParam,
  path: pathFromParam,
  lang: langFromParam || 'ru',
  is_bibleox: false,
  is_menu_icons: false,
  is_published: true,
  is_search: true,
  is_show_parent: true,
  parent_id: parentIdFromParam,
  menu_id: menuIdFromParam,
});
const user = ref();

// переменная для установки текста в редакторе
// редактор подгрузит данные в себя и затрёт эту перменную.
// Если опять надо изменить текст в редакторе, то опять задай текст в эту перменную
const sendTextToBody = ref('')
const sendTextToReferences = ref('')

let pageMenu = null

// СТАТЬЯ
function getPage() {
  api.get(`/pages/${props.id}/`).then(data => {
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
  api.get('/users/me/').then(data => {
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
  { name: '🇸🇦 AR - Арабский', code: 'ar' },
  { name: '🇦🇲 HY - Армянский', code: 'hy' },
  { name: '🇨🇳 zh-Hans - Китайский упр.', code: 'zh-Hans' },
  { name: '🇨🇳 zh-Hant - Китайский традиц.', code: 'zh-Hant' },
  { name: '🇩🇪 DE - Немецкий', code: 'de' },
  { name: '🇺🇸 EN - Английский', code: 'en' },
  { name: '🇪🇸 ES - Испанский', code: 'es' },
  { name: '🇫🇷 FR - Французский', code: 'fr' },
  { name: '🇬🇷 EL - Греческий', code: 'el' },
  { name: '🇮🇱 HE - Иврит', code: 'he' },
  { name: '🇮🇳 HI - Хинди', code: 'hi' },
  { name: '🇮🇷 FA - Персидский', code: 'fa' },
  { name: '🇮🇹 IT - Итальянский', code: 'it' },
  { name: '🇯🇵 JA - Японский', code: 'ja' },
  { name: '🇰🇪 SW - Суахили', code: 'sw' },
  { name: '🇰🇷 KO - Корейский', code: 'ko' },
  { name: '🇷🇺 RU - Русский', code: 'ru' },
  { name: '🇷🇸 SR - Сербский', code: 'sr' },
  { name: '🇹🇷 TR - Турецкий', code: 'tr' },
  { name: '🇹🇲 TK - Туркменский', code: 'tk' },
  { name: '🇺🇿 UZ - Узбекский', code: 'uz' },
  { name: '🇻🇳 VI - Вьетнамский', code: 'vi' },
  // ---
  { name: '📜 CU - Церковнославянский', code: 'cu' },
  { name: '🏛️ GRC - Древнегреческий', code: 'grc' },
  { name: '🇻🇦 LA - Латынь', code: 'la' },
  { name: '🇫🇷 FRM - Средневековый французский (Medieval ~1400–1600)', code: 'frm' },
  { name: '🇫🇷 FRO - Старофранцузский (до XIV века)', code: 'fro' },
  { name: '🇪🇬 COP - Коптский', code: 'cop' },
  { name: '🇦🇲 XCL - Древнеармянский (грабар)', code: 'xcl' },
]

const pageTypes = [
  { name: 'Статья', code: 1 },
  { name: 'Список', code: 4 },
  { name: 'Комментарий к библ. стиху', code: 3 },
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

const langsWithoutLocales = {
 'la':  'it', // # Латынь (ISO 639-1/2)
 'grc': 'el', // # Древнегреческий (классический) (ISO 639-3)
 'frm': 'fr', // # Средневековый французский (ISO 639-3, French, Medieval ~1400–1600)
 'fro': 'fr', // # Старофранцузский (до XIV века) (ISO 639-3)
 'cop': 'en', // # Коптский (ISO 639-2/3)
 'cu':  'ru', // # Церковнославянский (ISO 639-1/2, код означает "Old Church Slavonic")
 'xcl': 'ru', // # Древнеармянский
}
// Для древних языков, которым не сделана локализация UI, принимаем решение какую локализацию включать:
function localeForPage(pageLang) {
  return langsWithoutLocales[pageLang] || pageLang || 'ru';
}

let seen = computed(() => {
  return (props.id == undefined || page.value.id) ? true : false;
})

let seenMenu = computed(() => {
  return (page.value.id && page.value.page_type == '4') ? true : false
})

let isPageOwner = computed(() => {
  // Проверяем, что массив pages_owner существует и не пуст
  if (!props.currentUser?.pages_owner?.length) return false;

  // Если передан props.id и он есть в массиве — true
  if (props.id && props.currentUser.pages_owner.includes(Number(props.id))) return true;

  // Если передан page.value.parent_id и он есть в массиве — true
  if (page.value?.parent_id && props.currentUser.pages_owner.includes(page.value.parent_id)) return true;

  // Иначе — false
  return false;
});

function submit() {
  pconfirm.require({
    message: 'Точно хотите сохранить статью с названием: "' + page.value.title + '"?',
    header: 'Сохранение статьи',
    acceptLabel: 'Сохранить', rejectLabel: 'Отмена',
    rejectClass: 'p-button-danger p-button-text p-button-text',
    acceptClass: 'p-button-text',
    accept: () => {
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
      api.delete(`/pages/${page.value.id}/`).then(data => {
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
      api.post(`/pages/${page.value.id}/restore/`).then(data => {
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
      api.post(`/pages/${page.value.id}/cover/`, {file: null}).then(data => {
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

// Обработчик перед отправкой PDF
function onBeforePdfSend(event) {
  event.xhr.setRequestHeader('X-API-TOKEN', getCookie('api_token'));
  return true;
}

// Обработчик после загрузки PDF
function onPdfUpload(event) {
  if (event.xhr.status === 200) {
    const response = JSON.parse(event.xhr.responseText);
    if (response.success === 'ok') {
      page.value.is_pdf = true;
      toastSuccess('Успех', 'PDF-файл успешно загружен');
    } else {
      toastError('Ошибка', response.message || 'Не удалось загрузить PDF');
    }
  } else {
    toastError('Ошибка', 'Ошибка при загрузке PDF');
  }
}

// Удаление PDF
function removePdf() {
  pconfirm.require({
    message: 'Вы точно хотите удалить прикрепленный PDF-файл?',
    header: 'Удаление PDF',
    acceptLabel: 'Да',
    rejectLabel: 'Нет',
    icon: 'pi pi-exclamation-triangle',
    accept: () => {
      api.delete(`/pages/${page.value.id}/pdf/`).then(data => {
        if (data.success === 'ok') {
          page.value.is_pdf = false;
          toastSuccess('Успех', 'PDF-файл удален');
        } else {
          toastError('Ошибка', data.message || 'Не удалось удалить PDF');
        }
      });
    }
  });
}

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

<router-link :to="{ name: 'Pages'}">← Назад</router-link>
<a style='margin: 0 10px;' v-if="page.id" :href="`${apiUrl}/${localeForPage(page.lang)}/${page.lang}/w/${page.path}`">Статья на сайте</a>

<h1 v-if="page.id">Редактирование статьи</h1>
<h1 v-else>Новая статья</h1>


<div v-if="currentUser">
  <!-- Режим создания страницы -->
  <div v-if="!page.id">
    <div v-if="currentUser?.privs?.pages_create" class="can-info can-edit">
      <i class="pi pi-check-circle"></i> Вы можете создавать новые страницы
    </div>
    <div v-else class="cannot-edit">
      <i class="pi pi-times-circle"></i> Вы не можете создавать новые страницы
    </div>
  </div>

  <!-- Режим редактирования страницы -->
  <div v-else>
    <div v-if="currentUser?.privs?.pages_update || isPageOwner" class="can-info can-edit">
      <i class="pi pi-check-circle"></i> Вы можете редактировать эту страницу
    </div>
    <div v-else-if="currentUser?.privs?.mrs_create" class="can-info can-suggest">
      <i class="pi pi-send"></i> Вы можете предлагать правки к этой странице (временно не работает)
    </div>
    <div v-else class="can-info cannot-edit">
      <i class="pi pi-times-circle"></i> Вы не можете редактировать эту страницу
    </div>
  </div>
</div>


<h2 v-if="page.is_deleted" class="page-deleted-label">СТАТЬЯ УДАЛЕНА!</h2>

<IndexMergeRequests v-if="page.id" :pageId="page.id" :isPartial="true"/>
<div class="flex action-bar">
  <Button v-if="!page.id" @click.prevent="submit" label="Опубликовать статью" icon="pi pi-check" />
  <Button v-else-if="currentUser?.privs?.pages_update || isPageOwner" @click.prevent="submit" label="Сохранить" icon="pi pi-check" />

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
    <div v-if="!parentIdFromParam || page.is_deleted" class="field">
      <label>ID родителя (не обязательно)</label>
      <AutocompletePage v-model="page.parent_id" fetchKey="id" :parentIdFromParam />
    </div>
    <div v-else  class="field">
      <label>ID родителя</label>
      <InputText v-model="page.parent_id" :disabled="!!parentIdFromParam" />
    </div>

    <div v-if="!!menuIdFromParam" class="field">
      <label>Пункт меню для привязки</label>
      <InputText v-model="page.menu_id" :disabled="!!menuIdFromParam" />
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
    <div class="field one-line">
      <Checkbox v-model="page.is_search" inputId="issearch" :binary="true" />
      <label for="issearch">Поисковое поле</label>
    </div>
  </div>

  <div v-if="user.privs.super" class="group-fields">
    <div class="field one-line">
      <Checkbox v-model="page.is_bibleox" inputId="isbbx" :binary="true" />
      <label for="isbbx">Это текст сообщества bibleox?</label>
    </div>
  </div>

  <div v-if="user.privs.super" class="group-fields">
    <div class="field one-line">
      <Checkbox v-model="page.is_menu_icons" inputId="ismi" :binary="true" />
      <label for="ismi">Показывать в меню мини-иконки?</label>
    </div>
  </div>

  <div v-if="user.privs.super" class="group-fields">
    <div class="field one-line">
      <Checkbox v-model="page.is_show_parent" inputId="isshowparent" :binary="true" />
      <label for="isshowparent">Показывать родителя над заголовком?</label>
    </div>
  </div>

  <div v-if="page.id && (user.privs.super || isPageOwner)" class="group-fields">
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
      <FileUpload name="file" :url="`${apiUrl}/ru/api/pages/${id}/cover/`" @upload="onCoverUpload($event)" :onBeforeSend="onBeforeCoverSend" :multiple="false" accept="image/*" :maxFileSize="9000000">
        <template #empty>
          <p>Перенесите сюда файл для загрузки.</p>
        </template>
      </FileUpload>
    </div>
  </div>


  <div v-if="page.id && (user.privs.super || isPageOwner)" class="group-fields">
    <h2>Загрузка PDF-файла</h2>

    <div class="field">
      <FileUpload
        name="pdf_file"
        :url="`${apiUrl}/ru/api/pages/${page.id}/pdf`"
        @upload="onPdfUpload($event)"
        :onBeforeSend="onBeforePdfSend"
        :multiple="false"
        accept="application/pdf"
        :maxFileSize="100000000"
      >
        <template #empty>
          <p>Перенесите сюда PDF-файл для загрузки (макс. 100MB).</p>
        </template>
      </FileUpload>
    </div>

    <div v-if="page.is_pdf" class="pdf-info">
      <p>PDF уже прикреплён? ({{ page.is_pdf }})</p>
      <Button
        @click.prevent="removePdf"
        label="Удалить PDF"
        text
        severity="danger"
        icon="pi pi-trash"
      />
    </div>
  </div>

  <div v-if="page.id" class="field">
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

.field.one-line {
  display: flex;
  align-items: center;
  gap: 0.5rem;
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

/* ПРО ПРАВА РЕДАКТИРОВАНИЯ СТРАНИЦЫ label */

.can-info {
  display: inline-block;
  margin: 0;
  font-size: 0.9em;
  border-radius: 4px;
  border: 1px solid;
}

.can-edit {
  padding: 10px;
  color: #22C55E;
  background-color: #f0fdf467;
  border-color: #22c55e4e;
}

.can-suggest {
  padding: 10px;
  color: #3B82F6;
  background-color: #f0f9ff56;
  border-color: #3b83f650;
}

.cannot-edit {
  padding: 10px;
  color: #EF4444;
  background-color: #fef2f252;
  border-color: #ef44444a;
}

.can-info .pi {
  margin-right: 4px;
  font-size: 1em;
}
</style>
