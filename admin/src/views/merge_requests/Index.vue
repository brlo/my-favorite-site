<script setup>
import { ref, watchEffect } from 'vue';
import { api } from '@/libs/api.js';
import AutocompletePage from "@/components/AutocompletePage.vue";
import Dropdown from 'primevue/dropdown';

const props = defineProps({
  currentUser: Object,
  pageId: String,
  limit: Number,
  isPartial: Boolean,
  isListOnly: Boolean,
})

const mergeRequests = ref({})
const filterStatus = ref('')
const filterPageId = ref('')
const errors = ref('')

// если выбор состояния MR скрыт, то показываем только не принятые MR
if (!props.isListOnly) filterStatus.value = '2';

const mergeStatus = {
  0: 'Отклонено',
  1: 'Принято',
  2: 'Ожидает',
}
const mergeStatusClass = {
  0: 'grey',
  1: 'green',
  2: 'blue',
}
const mergeDropdownList = [
  { name: 'Показать все', code: '' },
  { name: 'Ожидает', code: '2' },
  { name: 'Принято', code: '1' },
  { name: 'Отклонено', code: '0' },
]

function getList() {
  let params = {};

  // Сейчас отдаём просто непринятые правки для текущей страницы
  if (props.pageId) {
    params.page_id = props.pageId;
    params.is_merged = 2;
  }

  // Сейчас рисуем общий список с возможностями фильрации
  if (filterStatus.value != '') {
    params.is_merged = filterStatus.value;
  }
  if (filterPageId.value != '' && filterPageId.value != undefined) {
    params.page_id = filterPageId.value;
  }

  if (props.limit) params.limit = props.limit;

  api.get('/merge_requests/list', params).then(data => {
    console.log(data)
    if (data.success == 'ok') {
      mergeRequests.value = data.items;
    } else {
      errors.value = data.errors;
    }
  })
}

watchEffect(
  // следим за изменением фильтра по статусу MR
  function() {
    // if (filterStatus.value != undefined || filterPageId.value != undefined) {
      getList();
    // }
  }
)
</script>

<template>
<div v-if="isPartial">

  <div v-if="mergeRequests.length" class="merge-requests">
    <h2 class="hint">Для этой статьи предложены правки</h2>

    <div class="merge-requests-list">
      <div class="merge-request" v-for="mr in mergeRequests">
        <div class="main-info">
          <router-link :to="{ name: 'ShowMergeRequest', params: { id: mr.id }}">
            <span class="diff-author">{{ mr.author?.name  }}</span>
          </router-link> <span :class="`merge-status-${mr.is_merged}`">
            <i :class="`badge ${mergeStatusClass[mr.is_merged]}`">{{ mergeStatus[mr.is_merged]}}</i>
          </span>
        </div>

        <div class="descr">
          <span class="updated-at">{{ mr.updated_at_word  }}</span>,
          <span class="diff-scores">
            <span class="plus" v-if="mr.plus_i">+{{ mr.plus_i }}</span> <span class="minus" v-if="mr.minus_i">-{{ mr.minus_i }}</span>
          </span>
        </div>
      </div>
    </div>

    <div v-if="errors.length">{{ errors }}</div>
  </div>
</div>

<div v-else>
  <div class="merge-requests">
    <h2>Правки к статьям</h2>

    <div v-if="!isListOnly" class="filters-bar">
      <Dropdown
        v-model="filterStatus"
        :options="mergeDropdownList"
        optionLabel="name"
        optionValue="code"
        placeholder="Статус правки"
      />

      <AutocompletePage v-model="filterPageId" fetchKey="id" />
    </div>

    <div v-if="mergeRequests.length" class="merge-requests-list">
      <div class="merge-request" v-for="mr in mergeRequests">
        <div class="main-info">
          <router-link :to="{ name: 'ShowMergeRequest', params: { id: mr.id }}">
            <span class="diff-title">{{ mr.page.title }}</span>
          </router-link> <span :class="`merge-status-${mr.is_merged}`">
            <i :class="`badge ${mergeStatusClass[mr.is_merged]}`">{{ mergeStatus[mr.is_merged]}}</i>
            <i class="badge black" v-if="mr.page.is_deleted">стр. удалена</i>
            <i class="badge grey" v-else-if="!mr.page.is_published">стр. скрыта</i>
          </span>
        </div>

        <div class="descr">
          <span class="updated-at">{{ mr.updated_at_word  }}</span>,
          <span class="diff-author">{{ mr.author?.name  }}</span>,
          <span class="diff-scores">
            <span class="plus" v-if="mr.plus_i">+{{ mr.plus_i }}</span> <span class="minus" v-if="mr.minus_i">-{{ mr.minus_i }}</span>
          </span>
        </div>
      </div>

      <div v-if="errors.length">{{ errors }}</div>
    </div>
    <div v-else class="empty-results">Нет результатов</div>
  </div>
</div>
</template>

<style scoped>
.merge-request {
  margin: 10px 0;
}

.descr {
  margin: 5px 0 0 0;
  font-size: 0.8em;
  color: #999;
}

.merge-request {
  padding: 5px 0;
}

.plus { color: #198e67; }
.minus { color: #ce2e2e; }

.empty-results {
  margin: 15px 0;
}

.filters-bar > .p-component {
  margin: 0 10px 0 0;
}
</style>
