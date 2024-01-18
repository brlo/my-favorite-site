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
import Button from 'primevue/button';
import SplitButton from 'primevue/splitbutton';

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

// <div class="field">
//   <label>Сноски:</label>
//   <tiptap :content="page.references" @change="(d) => { page.references = d; }"/>
// </div>

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
const page = ref({page_type: 1, lang: 'ru', is_published: true})

let pageMenu = null

// СТАТЬЯ
function getPage() {
  api.get(`/pages/${props.id}`).then(data => {
    console.log(data)
    page.value = data.item
    pageMenu = data.menu
  })
}

if (props.id) {
  getPage();
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
      toastSuccess('Успех', 'Статья создана');
      errors.value = '';
      router.push({ name: 'Pages' });
    } else {
      toastError('Ошибка', 'Не удалось создать статью');
      console.log('FAIL!', data);
      errors.value = data;
    }
  })
}

function submitToReview() {
  if(confirm("Правки будут отправлены на проверку. Продолжить?")) {
    api.post('/merge_requests', { page: page.value }).then(data => {
      console.log(data)
      if (data.success == 'ok') {
        toastSuccess('Успех', 'Статья отправлена на проверку');
        errors.value = '';
        router.push({ name: 'ShowMergeRequest', params: { id: data.item.id } });
      } else {
        toastError('Ошибка', 'Не удалось отправить изменения на проверку');
        console.log('FAIL!', data);
        errors.value = data;
      }
    })
  }
}

function destroy() {
  if(confirm("Удалить статью? \n" + page.value.title)){
    api.delete(`/pages/${page.value.id}`).then(data => {
      if (data.success == 'ok') {
        toastSuccess('Успех', 'Статья удалена');
        errors.value = '';
        router.push({ name: "Pages" });
      } else {
        console.log('FAIL!', data);
        toastError('Ошибка', 'Не удалось удалить статью');
        errors.value = data;
      }
    })
  }
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
</script>

<template>
<Toast />
<router-link :to="{ name: 'Pages'}">← Назад</router-link>
<a style='margin: 0 10px;' v-if="page.id" :href="`${apiUrl}/${page.lang}/${page.lang}/w/${page.path}`">Статья на сайте</a>

<h1 v-if="page.id">Редактирование статьи</h1>
<h1 v-else>Новая статья</h1>

<IndexMergeRequests v-if="page.id" :pageId="page.id" :isPartial="true"/>

<div class="flex action-bar">
  <SplitButton
    v-if="page.id"
    label="Предложить правки"
    icon="pi pi-send"
    @click="submitToReview"
    :model="submitBtnItems"
  />

  <Button v-else @click.prevent="submit" label="Опубликовать статью" icon="pi pi-check" />

  <div class="field fields-published">
    <label for="page-published" id="label-is-page-published">
      {{ page.is_published ? 'Доступно для чтения' : 'Скрыто' }}
    </label>
    <InputSwitch v-model="page.is_published" inputId="page-published"/>
  </div>

  <Button v-if="page.id" @click.prevent="destroy" label="Удалить" text severity="danger" style='margin-left: auto' icon="pi pi-trash" />
</div>

<div class="errors">{{ errors }}</div>

<div v-if="seen" class="form">
  <div class="field">
    <label>Тип документа</label>
    <Dropdown
      v-model="page.page_type"
      :options="pageTypes"
      optionLabel="name"
      optionValue="code"
      placeholder="Тип документа"
    />
  </div>

  <div style="font-size: 0.6em; margin: 0 0 30px 0; width: 400px;">
    {{ pageTypesDesc[page.page_type] }}
  </div>

  <div class="field">
    <label>Заголовок</label>
    <InputText v-model="page.title" placeholder="Заголовок" class="page-field-title" />
  </div>

  <div class="field">
    <label>Подзаголовок (не обязательно)</label>
    <InputText v-model="page.title_sub" placeholder="Подзаголовок" class="page-field-subtitle" />
  </div>

  <div class="group-fields">
    <div class="field">
      <label>Язык статьи</label>
      <Dropdown
        v-model="page.lang"
        :options="langs"
        optionLabel="name"
        optionValue="code"
        placeholder="Язык статьи"
      />
    </div>

    <div class="field">
      <label>ID для группировки переводов (не обязательно)</label>
      <AutocompletePage v-model="page.group_lang_id" fetchKey="group_lang_id"/>
    </div>
  </div>

  <div class="field">
    <label>Адрес (путь в URL)</label>
    <InputText v-model="page.path" placeholder="Адрес" />
  </div>

  <div class="group-fields">
    <div class="field">
      <label>ID родителя (не обязательно)</label>
      <AutocompletePage v-model="page.parent_id" fetchKey="id" />
    </div>
  </div>

  <div class="group-fields">
    <div class="field">
      <label>Аудио-файл (не обязательно)</label>

    <InputText v-model="page.audio" placeholder="Аудио-файл" />
    </div>
  </div>

  <div class="field">
    <label>Статья:</label>
    <tiptap :content="page.body" @change="(d) => { page.body = d; }"/>
  </div>

  <div v-if="seenMenu" class="tree-menu">
    <EditMenu :pageId="page.id" :pageMenu="pageMenu"/>
  </div>
</div>
</template>

<style scoped>
h1 {
  margin: 15px 0;
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

.page-field-title {
  width: 100%;
}
.page-field-subtitle {
  width: 100%;
}
.p-chips-input-token input[type='text'] {
  border-width: 0 !important;
}
</style>
