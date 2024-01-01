<script setup>
import { ref } from "vue"
import { api } from '@/libs/api.js'
import { arrayToTree, treeMenuToLineMenu } from '@/libs/menu_parser'
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

// информация для создания/редактирования одного элемента мею
const currentMenuItem = ref({parent_id: ''})
// обычное меню в виде массива от сервера
let arrMenu = ref(props.pageMenu)
// древовидное меню для отрисовки меню
const treeMenu = ref([])
// меню для select field
const lineMenu = ref([])

// ======================================================================
// ---------------------------- ЛОГИКА  ---------------------------------
// ======================================================================

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
  if (!arrMenu.value) return;

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

// ======================================================================
// ---------------------------- ЗАПРОСЫ ---------------------------------
// ======================================================================

// СОЗДАТЬ / ОБНОВИТЬ
function submitCurrentMenuItem() {
  let isUpdate = false, httpMethod = '', path = '';
  if (currentMenuItem.value.id) {
    isUpdate = true
    httpMethod = 'put'
    path = `/pages/${props.pageId}/menus/${currentMenuItem.value.id}`
  } else {
    isUpdate = false
    httpMethod = 'post'
    path = `/pages/${props.pageId}/menus/`
  }

  const body = { menu_item: currentMenuItem.value }

  const promise = api[httpMethod](path, body)
  console.log(promise)
  promise.then(data => {
    console.log(data)
    if (data.success == 'ok') {
      toastSuccess('Создано', 'Новый пункт добавлен в меню')
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
    const path = `/pages/${obj.page_id}/menus/${obj.id}`
    api.delete(path).then(data => {
      if (data.success == 'ok') {
        removeMenuElement(obj.id)
        loadNewMenu()
        toastInfo('Удалено', 'Пункт меню удалён')
      } else {
        toastError('Ошибка', 'Не удалось удалить пункт меню')
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
