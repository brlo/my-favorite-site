<script setup>
import { ref, computed, onMounted } from "vue";
import router from "@/router/index";
import { useConfirm } from "primevue/useconfirm";
import { useToast } from "primevue/usetoast";
import { api } from '@/libs/api.js';

// Компоненты PrimeVue
import InputText from 'primevue/inputtext';
import Textarea from 'primevue/textarea';
import Button from 'primevue/button';
import SplitButton from 'primevue/splitbutton';
import Dropdown from 'primevue/dropdown';
import Checkbox from 'primevue/checkbox';
import Chips from 'primevue/chips';
import ConfirmDialog from 'primevue/confirmdialog';
import Toast from 'primevue/toast';
import AutocompletePage from "@/components/AutocompletePage.vue";

const pconfirm = useConfirm();
const toast = useToast();

const toastError = (t, msg) => { toast.add({ severity: 'error', summary: t, detail: msg, life: 5000 }) }
const toastSuccess = (t, msg) => { toast.add({ severity: 'success', summary: t, detail: msg, life: 5000 }) }

const props = defineProps({
  id: String,
  currentUser: Object,
})

const errors = ref('');
const project = ref({
  title: '',
  description: '',
  source_langs: [],
  is_active: true,
});
const selectedPage = ref(null);
const attachedPages = ref([]);
const isLoading = ref(false);

const user = ref({ privs: {} });

// Доступные языки для выбора
const availableLangs = [
  { name: '🇷🇺 Русский', code: 'ru' },
  { name: '🇺🇸 Английский', code: 'en' },
  { name: '🇪🇸 Испанский', code: 'es' },
  { name: '🇫🇷 Французский', code: 'fr' },
  { name: '🇩🇪 Немецкий', code: 'de' },
  { name: '🇨🇳 Китайский', code: 'zh' },
  { name: '🇯🇵 Японский', code: 'ja' },
  { name: '🇦🇪 Арабский', code: 'ar' },
];

// Загрузка проекта
function getProject() {
  isLoading.value = true;
  api.get(`/translation-projects/${props.id}/`).then(data => {
    project.value = data.item;
  }).catch(error => {
    toastError('Ошибка', 'Не удалось загрузить проект');
    console.error('FAIL!', error);
  }).finally(() => {
    isLoading.value = false;
  });
}

if (props.id) {
  getProject();
}

// Инициализация пользователя
if (props.currentUser) {
  user.value = props.currentUser;
} else {
  user.value = { privs: {} };
}

const canEdit = computed(() => {
  return user.value?.privs?.super || false;
});

function submit() {
  let httpMethod = '', path = '';

  if (project.value.id) {
    httpMethod = 'put'
    path = `/translation_projects/${project.value.id}/`
  } else {
    httpMethod = 'post'
    path = '/translation_projects/'
  }

  isLoading.value = true;
  api[httpMethod](path, { project: project.value }).then(data => {
    if (data.success == 'ok') {
      project.value = data.item;
      toastSuccess('Успех', 'Проект сохранен');
      errors.value = '';
      // Если это создание нового проекта, перенаправляем на его редактирование
      if (!props.id) {
        router.push({ name: 'EditTranslationProject', params: { id: data.item.id } });
      }
    } else {
      toastError('Ошибка', 'Не удалось сохранить проект');
      console.log('FAIL!', data);
      errors.value = data.errors ? data.errors : data;
    }
  }).catch(error => {
    toastError('Ошибка', 'Ошибка при сохранении проекта');
    console.error('FAIL!', error);
  }).finally(() => {
    isLoading.value = false;
  });
}

// Присоединение страницы к проекту
function attachPageToProject() {
  if (!selectedPage.value) {
    toastError('Ошибка', 'Выберите страницу для присоединения');
    return;
  }

  if (!project.value.id) {
    toastError('Ошибка', 'Сначала сохраните проект');
    return;
  }

  isLoading.value = true;
  api.post(`/translation-projects/${project.value.id}/add_page/`, {
    page_id: selectedPage.value
  }).then(data => {
    if (data.success == 'ok') {
      toastSuccess('Успех', 'Страница успешно присоединена к проекту');
      selectedPage.value = null;
    } else {
      toastError('Ошибка', data.message || 'Не удалось присоединить страницу');
      errors.value = data.errors ? data.errors : data;
    }
  }).catch(error => {
    toastError('Ошибка', 'Ошибка при присоединении страницы');
    console.error('FAIL!', error);
  }).finally(() => {
    isLoading.value = false;
  });
}

function destroy() {
  pconfirm.require({
    message: `Точно хотите удалить проект перевода: "${project.value.title}"?`,
    header: 'Удаление проекта перевода',
    acceptLabel: 'Да',
    rejectLabel: 'Нет',
    rejectClass: 'p-button-text',
    acceptClass: 'p-button-danger p-button-text',
    icon: 'pi pi-exclamation-triangle',
    accept: () => {
      api.delete(`/translation-projects/${project.value.id}/`).then(data => {
        if (data.success == 'ok') {
          toastSuccess('Успех', 'Проект удален');
          errors.value = '';
          router.push({ name: "TranslationProjects" });
        } else {
          toastError('Ошибка', 'Не удалось удалить проект');
          errors.value = data.errors ? data.errors : data;
        }
      }).catch(error => {
        toastError('Ошибка', 'Ошибка при удалении проекта');
        console.error('FAIL!', error);
      });
    }
  });
}

// const submitBtnItems = [
//   {
//     label: 'Сохранить',
//     icon: 'pi pi-check',
//     command: () => {
//       submit()
//     }
//   },
// ];
</script>

<template>
<ConfirmDialog/>
<Toast />

<router-link :to="{ name: 'TranslationProjects'}">← Назад к проектам</router-link>

<h1 v-if="project.id">Редактирование проекта перевода</h1>
<h1 v-else>Новый проект перевода</h1>

<div v-if="currentUser">
  <div v-if="canEdit" class="can-info can-edit">
    <i class="pi pi-check-circle"></i> Вы можете управлять проектами перевода
  </div>
  <div v-else class="cannot-edit">
    <i class="pi pi-times-circle"></i> У вас нет прав для управления проектами перевода
  </div>
</div>

<div class="flex action-bar">
  <Button
    v-if="canEdit"
    @click.prevent="submit"
    label="Сохранить проект"
    icon="pi pi-check"
    :disabled="!canEdit || isLoading"
    :loading="isLoading"
  />

  <Button
    v-if="project.id && canEdit"
    @click.prevent="destroy"
    label="Удалить"
    text
    severity="danger"
    style='margin-left: auto'
    icon="pi pi-trash"
    :disabled="isLoading"
  />
</div>

<div class="errors">{{ errors }}</div>

<div class="form">
  <div class="field">
    <label>Название проекта</label>
    <InputText
      v-model="project.title"
      placeholder="Название проекта"
      :disabled="!canEdit || isLoading"
    />
  </div>

  <div class="field">
    <label>Описание проекта</label>
    <Textarea
      v-model="project.description"
      placeholder="Описание проекта"
      :disabled="!canEdit || isLoading"
      autoResize
      rows="5"
      cols="30"
    />
  </div>

  <div class="field">
    <label>Исходные языки</label>
    <Dropdown
      v-model="project.source_langs"
      :options="availableLangs"
      optionLabel="name"
      optionValue="code"
      placeholder="Выберите языки"
      :disabled="!canEdit || isLoading"
      :multiple="true"
      :filter="true"
    />
  </div>

  <div v-if="project.source_langs && project.source_langs.length > 0" class="field">
    <label>Выбранные языки:</label>
    <div class="selected-langs">
      <span
        v-for="langCode in project.source_langs"
        :key="langCode"
        class="lang-tag"
      >
        {{ availableLangs.find(l => l.code === langCode)?.name || langCode }}
      </span>
    </div>
  </div>

  <!-- Блок для присоединения страниц -->
  <div v-if="project.id" class="field attach-page-section">
    <h2>Присоединенные авторские тексты</h2>

    <div class="attach-page-controls">
      <div class="autocomplete-wrapper">
        <label>Поиск страницы для присоединения:</label>
        <AutocompletePage
          v-model="selectedPage"
          fetchKey="id"
          placeholder="Введите название страницы..."
          :disabled="!canEdit || isLoading"
        />
      </div>

      <Button
        @click="attachPageToProject"
        label="Присоединить авторский текст к проекту"
        icon="pi pi-link"
        :disabled="!selectedPage || !canEdit || isLoading"
        :loading="isLoading"
        class="attach-button"
      />
    </div>
  </div>
</div>
</template>

<style scoped>
.selected-langs {
  margin-top: 10px;
}

.lang-tag {
  display: inline-block;
  background-color: #e9ecef;
  padding: 4px 8px;
  margin: 2px;
  border-radius: 4px;
  font-size: 0.9em;
}

.attach-page-section {
  margin-top: 30px;
  padding-top: 20px;
  border-top: 2px solid #e9ecef;
}

.attach-page-controls {
  display: flex;
  gap: 15px;
  align-items: flex-end;
  margin-bottom: 20px;
}

.autocomplete-wrapper {
  flex: 1;
}

.attach-button {
  white-space: nowrap;
}

.attached-pages-list {
  margin-top: 20px;
}

.attached-page-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px;
  margin: 5px 0;
  background-color: #f8f9fa;
  border-radius: 4px;
  border-left: 4px solid #3b82f6;
}

.page-info {
  display: flex;
  flex-direction: column;
}

.page-path {
  font-size: 0.8em;
  color: #6c757d;
  margin-top: 2px;
}

.detach-button {
  margin-left: 10px;
}

.no-pages-message {
  padding: 20px;
  text-align: center;
  color: #6c757d;
  background-color: #f8f9fa;
  border-radius: 4px;
}

h1 {
  margin: 15px 0;
}

h2 {
  margin: 20px 0 15px 0;
  color: #2c3e50;
  border-bottom: 1px solid #e9ecef;
  padding-bottom: 5px;
}

h3 {
  margin: 15px 0 10px 0;
  color: #495057;
}

.field {
  margin-bottom: 20px;
}

.field label {
  display: block;
  margin-bottom: 5px;
  font-weight: 500;
}

.one-line {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.one-line label {
  margin-bottom: 0;
}

.can-info {
  display: inline-block;
  margin: 0 0 20px 0;
  padding: 10px;
  font-size: 0.9em;
  border-radius: 4px;
  border: 1px solid;
}

.can-edit {
  color: #22C55E;
  background-color: #f0fdf467;
  border-color: #22c55e4e;
}

.cannot-edit {
  color: #EF4444;
  background-color: #fef2f252;
  border-color: #ef44444a;
}

.can-info .pi {
  margin-right: 4px;
  font-size: 1em;
}

.action-bar {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 20px;
}

.errors {
  color: #ef4444;
  margin-bottom: 20px;
}

@media (max-width: 768px) {
  .attach-page-controls {
    flex-direction: column;
    align-items: stretch;
  }

  .attach-button {
    align-self: flex-start;
  }
}
</style>
