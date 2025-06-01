<script setup>
import { ref } from "vue"
import { api } from '@/libs/api.js'
import { arrayToTree, treeMenuToLineMenu } from '@/libs/menu_parser'
import AutocompletePage from "@/components/AutocompletePage.vue";
import MenuItem from "@/components/MenuItem.vue"
import InputText from 'primevue/inputtext';
import InputNumber from 'primevue/inputnumber';
import Dropdown from 'primevue/dropdown';
import Button from 'primevue/button';
import IconField from 'primevue/iconfield';
import InputIcon from 'primevue/inputicon';
import Checkbox from 'primevue/checkbox';

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
  // Удаляем элемент из списка меню
  const item = arrMenu.value.find((x) => x.id === objId);
  const index = arrMenu.value.indexOf(item);
  if (index > -1) { // only splice array when item is found
    arrMenu.value.splice(index, 1); // 2nd parameter means remove one item only
  }

  // обнуляем форму, если туда был загружен элемент, который только что удалили
  if (currentMenuItem.value.id == objId) {
    clearCurrentMenuItem()
  }
}

// сбрасываем форму с редактированием элемента меню
function clearCurrentMenuItem() { currentMenuItem.value = {parent_id: ''}};

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
      clearCurrentMenuItem()
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

// Функция для сортировки элементов по приоритету
const sortedChilds = (childs) => {
  if (!childs) return []
  return [...childs].sort((a, b) => a.priority - b.priority)
}
</script>

<template>
<div class="menu-preview">

  <h3>Меню</h3>

  <div class="menu-form">
    <h4>Добавить элемент меню</h4>

    <div class="group-fields">
      <div class="field">
        <label>Название</label>
        <IconField iconPosition="left">
          <InputIcon class="pi pi-search" />
          <InputText v-model="currentMenuItem.title" placeholder="Название" />
        </IconField>
      </div>
      <div class="field">
        <label>Ссылка</label>
        <IconField iconPosition="left">
          <InputIcon class="pi pi-search" />
          <AutocompletePage v-model="currentMenuItem.path" fetchKey="path" />
        </IconField>
      </div>
    </div>

    <div class="group-fields">
      <div class="field">
        <label>Приоритет</label>
        <InputNumber v-model="currentMenuItem.priority" placeholder="Приоритет" />
      </div>

      <div class="field">
        <label>Родитель</label>
        <Dropdown
          v-model="currentMenuItem.parent_id"
          filter
          showClear
          :options="lineMenu"
          optionLabel="name"
          optionValue="code"
          placeholder="Родитель"
        />
      </div>

      <field>
        <label for="isgold">Особенный</label>
        <Checkbox v-model="currentMenuItem.is_gold" inputId="isgold" :binary="true" />
      </field>
    </div>

    <div class="btn-bar">
      <Button
        :label="`${currentMenuItem.id ? 'Обновить' : 'Добавить'} элемент`"
        @click.prevent="submitCurrentMenuItem"
        :icon="`${currentMenuItem.id ? 'pi pi-check' : 'pi pi-plus' }`"
      />
      <Button
        v-if="currentMenuItem.id"
        label="Отмена"
        @click.prevent="clearCurrentMenuItem"
        plain
        text
      />
    </div>
  </div>

  <div class="divider"></div>

  <div v-if="treeMenu" class="menu-items">
    <MenuItem
      v-for="item in sortedChilds(treeMenu)"
      :item="item"
      @destroy="(item) => { destroy(item) }"
      @forUpdate="(item) => { currentMenuItem = item }"
    />
  </div>
</div>
</template>

<style scoped>
.divider {
  border-top: 1px solid #777;
  margin: 25px -15px;
}

.menu-items {
  margin: -25px -15px -15px -15px;
  padding: 15px;
  background-color: #fff;
  max-height: 500px;
  overflow-y: scroll;
}

.menu-preview {
  margin: 20px 0;
  padding: 30px 15px 15px 15px;
  border: 1px solid #777;
  border-radius: 6px;
  overflow: hidden;
}

.menu-preview h3 {
  border-bottom: 1px solid #777;
  margin: -30px -15px 15px -15px;
  padding: 15px;
  background-color: #f0f0ea;
}

.btn-bar {
  margin: 15px 0 10px 0;
}
.btn-bar button {
  margin: 0 5px 0 0;
}
</style>
