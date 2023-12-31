<script setup>
import { ref } from "vue"
import {_} from 'vue-underscore'
import { getCookie } from '@/libs/cookies.js'
import MenuItem from "@/components/MenuItem.vue"
import { useToast } from "primevue/usetoast";

const toast = useToast();
const toastError = (t, msg) => { toast.add({ severity: 'error', summary: t, detail: msg, life: 5000 }) }
const toastSuccess = (t, msg) => { toast.add({ severity: 'success', summary: t, detail: msg, life: 5000 }) }
const toastInfo = (t, msg) => { toast.add({ severity: 'info', summary: t, detail: msg, life: 5000 }) }


const props = defineProps({
  pageId: String,
  pageMenu: Array,
})

const apiUrl = import.meta.env.VITE_API_URL

// информация для создания/редактирования одного элемента мею
const currentMenuItem = ref({parent_id: ''})
// обычное меню в виде массива от сервера
let arrMenu = ref(props.pageMenu)
// древовидное меню для отрисовки меню
const treeMenu = ref([])
// меню для select field
const lineMenu = ref([])

// Функция, которая преобразует массив в дерево
function arrayToTree(originArray) {
  const field_id = 'id'
  const field_parent_id = 'parent_id'

  // clone
  // let array = [...originArray]
  let array = [];
  for (let item of originArray) { array.push(item) };

  // Создаем пустой объект для хранения дерева
  let tree = [];
  // Проходим по всем элементам массива
  for (let item of array) {
    // Если элемент имеет parent_id, то он является потомком какого-то узла
    if (item[field_parent_id]) {
      // Находим родительский узел по parent_id
      let parent = array.find((x) => x[field_id] === item[field_parent_id]);
      // Если родительский узел существует
      if (parent) {
        // Если у родительского узла еще нет поля childs, то создаем его как пустой массив
        if (!parent.childs) {
          parent.childs = [];
        }
        // Добавляем текущий элемент в массив childs родительского узла
        parent.childs.push(item);
      }
    } else {
      // Если элемент не имеет parent_id, то он является корневым узлом
      // Добавляем его в объект дерева по его id
      tree.push(item);
    }
  }
  // Возвращаем объект дерева
  return tree;
}

// линейный список элементов для select (с чёрточками для отображения глубины)
function treeMenuToLineMenu(treeMenu, depth = 0) {
  if (treeMenu == null) return []

  let l_menu = []

  _.each(
    treeMenu,
    function (item) {
      l_menu.push({
        name: '-'.repeat(depth) + ' ' + item.title,
        code: item.id,
      })

      if (item.childs) {
        l_menu = _.union(
          l_menu,
          treeMenuToLineMenu(item.childs, depth+1)
        )
      }
    }
  )
  return l_menu
}

// удалить элемент из меню по ID (потом вызови loadNewMenu())
function removeMenuElement(objId) {
  const item = arrMenu.value.find((x) => x.id === objId);
  const index = arrMenu.value.indexOf(item);
  if (index > -1) { // only splice array when item is found
    arrMenu.value.splice(index, 1); // 2nd parameter means remove one item only
  }
}

// добавить новый элемент в меню (потом вызови loadNewMenu())
function addMenuElement(obj) { arrMenu.value.push(obj) }

function loadNewMenu() {
  // Вызываем функцию и выводим результат
  // arrMenu = items
  // затираем у всех детей, иначе они по второму разу добавятся, будет некрасиво.
  // иначе можно было бы при добавлении просто проверять, может быть объект уже добавлен.
  for (let item of arrMenu.value) {
    if (item.childs) item.childs = [];
  };
  treeMenu.value = arrayToTree(arrMenu.value)
  lineMenu.value = treeMenuToLineMenu(treeMenu.value)
}
loadNewMenu()

// СОЗДАТЬ / ОБНОВИТЬ
function submitCurrentMenuItem() {
  const isUpdate = currentMenuItem.value.id ? true : false
  const httpMethod = isUpdate ? 'PUT' : 'POST'
  let path = `/ru/api/pages/${props.pageId}/menus/`
  if (isUpdate) path = path + currentMenuItem.value.id
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
      toastSuccess('Успех', 'Новый пункт добавлен в меню')
      // если обновляли (а не создавали), то надо удалить старый элемент из меню
      if (isUpdate) { removeMenuElement(currentMenuItem.value.id) }
      // добавляем новый элемент в меню
      addMenuElement(data.item)
      // рендерим меню
      loadNewMenu()
      // обнуляем форму
      currentMenuItem.value = {parent_id: ''}
    } else {
      toastError('Ошибка', 'Не удалось добавить пункт в меню')
      console.log('FAIL menu item create!', data)
      if (data.errors) alert(data.errors)
    }
  })
}

// УДАЛИТЬ
function destroy(obj) {
  if(confirm("Удалить элемент меню? \n" + obj.title)){
    const path = `/ru/api/pages/${obj.page_id}/menus/${obj.id}`
    const url = 'http://bibleox.lan' + path
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
        removeMenuElement(obj.id)
        loadNewMenu()
      } else {
        console.log('FAIL!', data)
        if (data.errors) alert(data.errors)
      }
    })
  }
}
</script>

<template>
<div>
  <h3>Добавить элемент меню</h3>

  <div class="group-fields">
    <div class="field">
      <label>Название</label>
      <input v-model="currentMenuItem.title" required type="text" style="width:300px;" />
    </div>
    <div class="field">
      <label>Ссылка</label>
      <input v-model="currentMenuItem.path" type="text" style="width:300px;" />
    </div>
  </div>

  <div class="group-fields">
    <div class="field">
      <label>Приоритет</label>
      <input v-model="currentMenuItem.priority" type="text" style="width:100px;"/>
    </div>
    <div class="field">
      <label>Родитель</label>
      <select v-model="currentMenuItem.parent_id">
        <option value="">Нет родителя</option>
        <option v-for="item in lineMenu" :value="item.code">
          {{ item.name }}
        </option>
      </select>
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
    @destroy="(item) => { destroy(item) }"
    @forUpdate="(item) => { currentMenuItem = item }"
  />
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
