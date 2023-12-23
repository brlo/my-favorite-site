<script setup>
import { ref, computed } from 'vue'
import {_} from 'vue-underscore'
import Tiptap from "@/components/Tiptap.vue"
import router from "@/router/index"
import MenuItem from "@/components/MenuItem.vue"
import { getCookie } from '@/libs/cookies.js'

const props = defineProps({
  id: String
})

const apiUrl = import.meta.env.VITE_API_URL

const page = ref({page_type: 1, lang: 'ru', published: true})
const currentMenuItem = ref({path_parent: ''})
const treeMenu = ref([])
const lineMenu = ref([])

// СТАТЬЯ
function getPage() {
  const path = `/ru/api/pages/${props.id}`
  const params = { session_key: 'test' }
  const url = apiUrl + path + '?' + new URLSearchParams(params)
  const headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'X-API-TOKEN': getCookie('api_token'),
  }
  console.log('GET: ' + url)
  fetch(url, {headers: headers})
  .then(response => response.json())
  .then(data => {
    console.log(data)
    page.value = data.item
    treeMenu.value = data.tree_menu.items
    lineMenu.value = treeMenuToLineMenu(data.tree_menu.items)
  })
}

if (props.id) {
  getPage();
}

// // ТЕМЫ
// const qSubjects = ref([])
// function getSubjects() {
//   const path = '/ru/api/quotes_subjects/list'
//   const url = apiUrl + path
//   console.log('GET: ' + url)
//   fetch(url).then(response => response.json())
//   .then(data => {
//     qSubjects.value = _.map(
//       data.items,
//       function (subj) { return { name: subj.title_ru, code: subj.id } }
//     )
//   })
// }
// getSubjects();

// ЯЗЫКИ
const langs = [
  { name: '🇷🇺 RU', code: 'ru' },
  { name: '🇺🇸 EN', code: 'en' },
  { name: '🇬🇷 GR', code: 'gr' },
  { name: '🇯🇵 JP', code: 'jp' },
]

const pageTypes = [
  { name: 'Статья', code: '1' },
  { name: 'Книга', code: '2' },
  { name: 'Библ. стих', code: '3' },
  { name: 'Список', code: '4' },
]

const pageTypesDesc = {
  '1': 'Просто какая-то статья. Обычно, статья — это разбор какого-то термина.',
  '2': 'Книга — это режим публикации книг по одной главе. Если есть следующие или предыдущие части, то ссылки на них надо указать в соответствующих полях.',
  '3': 'Библейский стих — это режим публикации апологетичиских разборов того или иного стиха Библии. В названии статьи надо указать только адрес библейского стиха: Быт. 1:5. Тогда он привяжется к стиху на сайте и каждый увидит, что к данному стиху есть комментарий.',
  '4': 'Список — это режим публикации статьи, к которой можно добавить меню из ссылок на другие статьи. Эта возможность появиться только после создания статьи-списка.',
}

let seen = computed(() => {
  return (props.id == null || page.value?.id) ? true : false
})

let seenMenu = computed(() => {
  return (props.id != null || page.page_type == 4) ? true : false
})

function submitCurrentMenuItem() {
  const httpMethod = currentMenuItem.value.id ? 'PUT' : 'POST'
  let path = `/ru/api/pages/${props.id}/menus/`
  if (currentMenuItem.value.id) path = path + currentMenuItem.value.id
  const params = { session_key: 'test' }
  const url = apiUrl + path + '?' + new URLSearchParams(params)
  const headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'X-API-TOKEN': getCookie('api_token')
  }
  const bodyJSON = JSON.stringify({menu_item: currentMenuItem.value})
  console.log(httpMethod + ': ' + url, bodyJSON)
  fetch(url, {method: httpMethod, headers: headers, body: bodyJSON})
  .then(response => response.json())
  .then(data => {
    console.log(data)
    if (data.success == 'ok') {
      loadNewMenu(data.items)
    } else {
      console.log('FAIL menu item create!', data)
      if (data.errors) alert(data.errors)
    }
  })
}

function treeMenuToLineMenu(treeMenu, depth = 0) {
  if (treeMenu == null) return []

  let l_menu = []

  _.each(
    treeMenu,
    function (item) {
      l_menu.push({
        name: '-'.repeat(depth) + ' ' + item.obj.title,
        code: item.obj.path,
      })

      if (item.childs.length) {
        l_menu = _.union(
          l_menu,
          treeMenuToLineMenu(item.childs, depth+1)
        )
      }
    }
  )
  return l_menu
}

function loadNewMenu(items) {
  treeMenu.value = items
  lineMenu.value = treeMenuToLineMenu(items)
}


function submit() {
  const httpMethod = props.id ? 'PUT' : 'POST'
  let path = '/ru/api/pages/'
  if (props.id) path = path + props.id
  const params = { session_key: 'test' }
  const url = apiUrl + path + '?' + new URLSearchParams(params)
  const headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'X-API-TOKEN': getCookie('api_token')
  }
  const bodyJSON = JSON.stringify({page: page.value})
  console.log(httpMethod + ': ' + url)
  fetch(url, {method: httpMethod, headers: headers, body: bodyJSON})
  .then(response => response.json())
  .then(data => {
    console.log(data)
    page.value = data.item
    if (data.success == 'ok') {
      router.push({ name: "Pages" })
    } else {
      console.log('FAIL!', data)
      if (data.errors) alert(data.errors)
    }
  })
}

function destroy() {
  if(confirm("Удалить статью? \n" + page.value.title)){
    const path = `/ru/api/pages/${props.id}`
    const url = apiUrl + path
    const headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-API-TOKEN': getCookie('api_token')
    }
    console.log('DELETE: ' + url)
    fetch(url, {method: 'DELETE', headers: headers})
    .then(response => response.json())
    .then(data => {
      if (data.success == 'ok') {
        router.push({ name: "Pages" })
      } else {
        console.log('FAIL!', data)
        if (data.errors) alert(data.errors)
      }
    })
  }
}
</script>

<template>
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
    <select v-model="page.page_type">
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
    <input v-model="page.published" type="checkbox" id="page-published" style="width: 20px; height: 20px;"/>
    <label for="page-published" style="display: inline-block; padding: 0 0 5px 5px; font-size: 1.3em; position: relative; bottom: 3px;">
      {{ page.published ? 'Доступно для чтения' : 'Скрыто' }}
    </label>
  </div>

  <div class="field">
    <label>Заголовок</label>
    <input v-model="page.title" type="text" style="width: 100%;" />
  </div>

  <div class="field">
    <label>Подзаголовок</label>
    <input v-model="page.title_sub" type="text" />
  </div>

  <div class="field">
    <label>Адрес</label>
    <input v-model="page.path" type="text" />
  </div>

  <div class="group-fields">
    <div class="field">
      <label>Адрес родителя</label>
      <input v-model="page.path_parent" type="text" />
    </div>

    <div class="field">
      <label>Название родителя</label>
      <input v-model="page.path_parent_title" type="text" />
    </div>
  </div>

  <div class="group-fields">
    <div class="field">
      <label>Адрес предыдущей страницы</label>
      <input v-model="page.path_prev" type="text" />
    </div>

    <div class="field">
      <label>Название предыдущей страницы</label>
      <input v-model="page.path_prev_title" type="text" />
    </div>
  </div>

  <div class="group-fields">
    <div class="field">
      <label>Адрес следующей страницы</label>
      <input v-model="page.path_next" type="text" />
    </div>

    <div class="field">
      <label>Название следующей страницы</label>
      <input v-model="page.path_next_title" type="text" />
    </div>
  </div>

  <div class="group-fields">
    <div class="field">
      <label>Язык статьи</label>
      <select v-model="page.lang">
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
    <div>
      <h3>Добавить элемент меню</h3>

      <div class="group-fields">
        <div class="field">
          <label>Приоритет</label>
          <input v-model="currentMenuItem.priority" type="text" style="width:100px;"/>
        </div>
        <div class="field">
          <label>Родитель</label>
          <select v-model="currentMenuItem.path_parent">
            <option value="">Нет родителя</option>
            <option v-for="item in lineMenu" :value="item.code">
              {{ item.name }}
            </option>
          </select>
        </div>
      </div>
      <div class="group-fields">
        <div class="field">
          <label>Название</label>
          <input v-model="currentMenuItem.title" type="text" style="width:300px;" />
        </div>
        <div class="field">
          <label>Ссылка</label>
          <input v-model="currentMenuItem.path" type="text" style="width:300px;" />
        </div>
      </div>

      <button @click.prevent="submitCurrentMenuItem" class="menu-create-btn pretty btn">
        {{ currentMenuItem.id ? 'Обновить' : 'Добавить' }} элемент
      </button>
    </div>

    <h3>Меню</h3>

    <div v-if="treeMenu" class="menu-items">
      <MenuItem
        v-for="item in treeMenu"
        :item="item"
        @destroy="(items) => { loadNewMenu(items) }"
        @forUpdate="(item) => { currentMenuItem = item }"
      />
    </div>
  </div>
</div>
</template>

<style scoped>
.tree-menu {
  border-top: 1px solid #777;
  padding: 40px 0 0 0;
  margin: 40px 0 0 0;
}

.menu-items {
  margin: 20px 0;
}

.menu-create-btn {
  margin: 10px 0 30px 0;
}

h3 {
  margin: 10px 0 20px 0;
}
</style>
