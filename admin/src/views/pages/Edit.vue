<script setup>
import { ref, computed } from "vue";
import Tiptap from "@/components/Tiptap.vue";
import router from "@/router/index";
import EditMenu from "@/components/EditMenu.vue";
import { useToast } from "primevue/usetoast";
import { api } from '@/libs/api.js';

const toast = useToast();
const toastError = (t, msg) => { toast.add({ severity: 'error', summary: t, detail: msg, life: 5000 }) }
const toastSuccess = (t, msg) => { toast.add({ severity: 'success', summary: t, detail: msg, life: 5000 }) }
const toastInfo = (t, msg) => { toast.add({ severity: 'info', summary: t, detail: msg, life: 5000 }) }

const props = defineProps({
  id: String
})

const page = ref({page_type: 1, lang: 'ru', is_published: true})

let pageMenu = null

// СТАТЬЯ
function getPage() {
  api.get(`/pages/${props.id}`).then(data => {
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
  { name: '🇯🇵 JP', code: 'jp' },
]

const pageTypes = [
  { name: 'Статья', code: '1' },
  { name: 'Список', code: '4' },
  { name: 'Книга', code: '2' },
  { name: 'Комментарий на библ. стих', code: '3' },
  { name: 'Книга с разбивкой на стихи', code: '5' },
]

const pageTypesDesc = {
  '1': 'Просто какая-то статья. Обычно, статья — это разбор какого-то термина.',
  '2': 'Книга — это режим публикации книг по одной главе. Если есть следующие или предыдущие части, то ссылки на них надо указать в соответствующих полях.',
  '3': 'Библейский стих — это режим публикации апологетичиских разборов того или иного стиха Библии. В названии статьи надо указать только адрес библейского стиха: Быт. 1:5. Тогда он привяжется к стиху на сайте и каждый увидит, что к данному стиху есть комментарий.',
  '4': 'Список — это режим публикации статьи, к которой можно добавить меню из ссылок на другие статьи. Эта возможность появиться только после создания статьи-списка.',
  '5': 'Книга стих — режим публикации небольших книг древних писателей. Книга разобъётся на стихи. Будет предложено добавить её переводы и аудио-текст',
}

let seen = computed(() => {
  return (props.id == null || page.value?.id) ? true : false
})

let seenMenu = computed(() => {
  return (props.id !== null && page.value.page_type === 4) ? true : false
})


function submit() {
  let httpMethod = '', path = '';
  if (props.id) {
    httpMethod = 'put'
    path = `/pages/${props.id}/`
  } else {
    httpMethod = 'post'
    path = '/pages/'
  }

  api[httpMethod](path, { page: page.value }).then(data => {
    console.log(data)
    if (data.success == 'ok') {
      page.value = data.item
      toastSuccess('Успех', 'Статья создана')
      router.push({ name: 'Pages' })
    } else {
      toastError('Ошибка', 'Не удалось создать статью')
      console.log('FAIL!', data)
      if (data.errors) alert(data.errors)
    }
  })
}

function destroy() {
  if(confirm("Удалить статью? \n" + page.value.title)){
    api.delete(`/pages/${props.id}`).then(data => {
      if (data.success == 'ok') {
        toastSuccess('Успех', 'Статья удалена')
        router.push({ name: "Pages" })
      } else {
        console.log('FAIL!', data)
        toastError('Ошибка', 'Не удалось удалить статью')
        if (data.errors) alert(data.errors)
      }
    })
  }
}
</script>

<template>
<Toast />
<router-link :to="{ name: 'Pages'}">← Назад</router-link>

<h1 v-if="props.id">Редактирование статьи</h1>
<h1 v-else>Новая статья</h1>

<a style='float: right; margin: 20px 0 40px' v-if="props.id" href='' @click.prevent="destroy">
  Удалить статью
</a>

<button @click.prevent="submit" class="form-send-btn pretty btn">
  Опубликовать {{ props.id ? 'правки' : 'статью' }}
</button>

<div v-if="seen" class="form">
  <div class="field">
    <label>Тип документа</label>
    <select v-model="page.page_type" required>
      <option value="" disabled>Тип документа</option>
      <option v-for="pType in pageTypes" :value="pType.code">
        {{ pType.name }}
      </option>
    </select>
  </div>

  <div style="font-size: 0.6em; margin: 0 0 30px 0; width: 400px;">
    {{ pageTypesDesc[page.page_type] }}
  </div>

  <div class="field">
    <input v-model="page.is_published" type="checkbox" id="page-published" style="width: 20px; height: 20px;"/>
    <label for="page-published" style="display: inline-block; padding: 0 0 5px 5px; font-size: 1.3em; position: relative; bottom: 3px;">
      {{ page.is_published ? 'Доступно для чтения' : 'Скрыто' }}
    </label>
  </div>

  <div class="field">
    <label>Заголовок</label>
    <input v-model="page.title" required type="text" style="width: 100%;" />
  </div>

  <div class="field">
    <label>Подзаголовок</label>
    <input v-model="page.title_sub" type="text" />
  </div>

  <div class="group-fields">
    <div class="field">
      <label>Язык статьи</label>
      <select v-model="page.lang" required>
        <option value="" disabled>Язык статьи</option>
        <option v-for="lang in langs" :value="lang.code">
          {{ lang.name }}
        </option>
      </select>
    </div>

    <div class="field">
      <label>ID для группировки переводов</label>
      <input v-model="page.group_lang_id" type="text" />
    </div>
  </div>

  <div class="field">
    <label>Адрес</label>
    <input v-model="page.path" type="text" />
  </div>

  <div class="group-fields">
    <div class="field">
      <label>ID родителя</label>
      <input v-model="page.parent_id" type="text" />
    </div>
  </div>

  <div class="group-fields">
    <div class="field">
      <label>Аудио-файл</label>
      <input v-model="page.audio" type="text" />
    </div>
  </div>

  <div class="field">
    <label>Тэги (через запятую)</label>
    <input v-model="page.tags_str" type="text" />
  </div>

  <div class="field">
    <label>Приоритет</label>
    <input v-model="page.priority" type="number" />
  </div>

  <div class="field">
    <label>Статья:</label>
    <tiptap :content="page.body" @change="(d) => { page.body = d; }"/>
  </div>

  <div class="field">
    <label>Сноски:</label>
    <tiptap :content="page.references" @change="(d) => { page.references = d; }"/>
  </div>

  <div v-if="seenMenu" class="tree-menu">
    <EditMenu :pageId="page.id" :pageMenu="pageMenu"/>
  </div>
</div>
</template>

<style scoped>
</style>
