<script setup>
import { ref, computed } from 'vue';
import router from "@/router/index";
import { api } from '@/libs/api.js';
import { useToast } from "primevue/usetoast";
import Button from 'primevue/button';

const props = defineProps({
  id: String
})

const mergeRequest = ref({});
const errors = ref('');

const toast = useToast();
const toastError = (t, msg) => { toast.add({ severity: 'error', summary: t, detail: msg, life: 5000 }) }
const toastSuccess = (t, msg) => { toast.add({ severity: 'success', summary: t, detail: msg, life: 5000 }) }
const toastInfo = (t, msg) => { toast.add({ severity: 'info', summary: t, detail: msg, life: 5000 }) }

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

const pageFields = {
  title: 'Заголовок',
  title_sub: 'Подзаголовок',
  body: 'Статья',
  references: 'Примечания',
  is_published: 'Доступно для чтения',
  page_type: 'Тип статьи',
  meta_desc: 'META-описание',
  path: 'Адрес',
  parent_id: 'ID родительской страницы',
  lang: 'Язык',
  group_lang_id: 'ID для группировки переводов',
  tags_str: 'Тэги',
  priority: 'Приоритет',
  audio: 'Аудиофайл',
}

// добавляем соседние строчки
function diffWithContext(textDiffs, fullTextAsArr) {
  // Один раз собираем все группы, а потом один раз добавляем в ref, чтобы лишний раз его не беспокоить
  let groups = []

  if (fullTextAsArr && fullTextAsArr.length) {
    textDiffs.forEach(group => {
      const firstGroupLine = group[0][1]
      // const lastGroupLine = group[group.length-1][1]

      let lastMinus = group.findLast((action) => action[0] == '-')
      lastMinus = lastMinus && lastMinus[1]
      let firstPlus = group.find((action) => action[0] == '+')
      firstPlus = firstPlus && firstPlus[1]
      // const lastGroupLine = (lastMinus && lastMinus[1]) || (firstPlus && firstPlus[1])

      const prettyGroup = []

      // ПРЕДЫДУЩИЕ СТРОКИ (==)
      if (Number.isInteger(firstGroupLine) && firstGroupLine > 0) {
        const prevNum = firstGroupLine - 1;
        const prevString = fullTextAsArr[prevNum];
        if (prevString) {
          prettyGroup.push(['', prevNum, prevString]);
        }
      }

      // СУЩЕСТВУЮЩИЕ СТРОКИ (- и +)
      prettyGroup.push(...group)

      // СЛЕДУЮЩИЕ СТРОКИ (==)
      // НУЖНО НАЙТИ В ГРУППЕ ПОСЛЕДНИЙ МИНУС, ИЛИ ПЕРВЫЙ ПЛЮС, это и будет lastGroupLine
      if (Number.isInteger(lastMinus)) {
        const nextNum = lastMinus + 1;
        const nextString = fullTextAsArr[nextNum];
        if (nextString) {
          prettyGroup.push(['', nextNum, nextString]);
        }
      } else if (Number.isInteger(firstPlus)) {
        const num = firstPlus;
        const str = fullTextAsArr[num];
        if (str) {
          prettyGroup.push(['', num, str]);
        }
      }

      groups.push(prettyGroup);
    });
  } else {
    groups = textDiffs;
  }

  return groups;
}

function getItem() {
  api.get(`/merge_requests/${props.id}`).then(data => {
    console.log(data)
    if (data.success == 'ok') {
      mergeRequest.value = data.item;
      errors.value = '';
    } else {
      errors.value = data.errors ? data.errors : data;
    }
  })
}

getItem()


function merge() {
  if(confirm("Правки будут применены к статье. Продолжить?")) {
    api.post(`/merge_requests/${props.id}/merge`).then(data => {
      console.log(data)
      if (data.success == 'ok') {
        toastSuccess('Принято', 'Правки успешно применены к статье');
        mergeRequest.value = data.item;
        errors.value = '';
        router.push({ name: 'EditPage', params: { id: data.item.page_id } });
      } else {
        toastError('Ошибка', 'Не удалось принять правки');
        console.log('FAIL!', data);
        errors.value = data.errors ? data.errors : data;
      }
    })
  }
}

function rebase() {
  if(confirm("Правки будут обновлены. Продолжить?")) {
    api.post(`/merge_requests/${props.id}/rebase`).then(data => {
      console.log(data)
      if (data.success == 'ok') {
        toastInfo('Обновлено', 'Правки успешно обновлены');
        errors.value = '';
        mergeRequest.value = data.item;
      } else {
        toastError('Ошибка', 'Не удалось обновить правки')
        console.log('FAIL!', data)
        errors.value = data.errors ? data.errors : data;
      }
    })
  }
}

function reject() {
  if(confirm("Правки будут отклонены. Продолжить?")) {
    api.post(`/merge_requests/${props.id}/reject`).then(data => {
      console.log(data)
      if (data.success == 'ok') {
        toastInfo('Отклонено', 'Правки отклонены');
        errors.value = '';
        mergeRequest.value = data.item;
      } else {
        toastError('Ошибка', 'Не удалось отклонить правки');
        console.log('FAIL!', data);
        errors.value = data.errors ? data.errors : data;
      }
    })
  }
}

let isRebaseBtnSeen = computed(() => {
  // MR ещё не принят
  const isWaiting = mergeRequest.value.is_merged == 2;
  // и MR основан на самой свежей версии статьи
  const isOldDiff = mergeRequest.value.src_ver != mergeRequest.value.page.merge_ver;
  return isWaiting && isOldDiff;
})
let isRejectBtnSeen = computed(() => {
  // MR ещё не принят
  return mergeRequest.value.is_merged == 2;
})
</script>

<template>
<Toast />
<div v-if="mergeRequest.id">
  <label>Правки к статье:</label>
  <h1>
    <router-link :to="{ name: 'EditPage', params: { id: mergeRequest.page_id }}">{{ mergeRequest.page.title }}</router-link> <span class="plus mono-font" v-if="mergeRequest.plus_i">+{{ mergeRequest.plus_i }}</span><span class="minus mono-font" v-if="mergeRequest.minus_i">-{{ mergeRequest.minus_i }}</span>
    <i :class="`badge ${mergeStatusClass[mergeRequest.is_merged]}`">{{ mergeStatus[mergeRequest.is_merged]}}</i>
  </h1>
  <label>Предложил: {{ mergeRequest.user?.name }} ({{ mergeRequest.user?.username }})</label>
  <label>{{ mergeRequest.updated_at_word }}</label>
  <label>Оригинал текста от: {{ mergeRequest.src_ver }}</label>

  <div class="flex action-bar">
    <Button v-if="mergeRequest.is_merged == 1" disabled :label="`Правки уже приняты: ${ mergeRequest.action_at }`" icon="pi pi-check-circle" />
    <Button v-else-if="mergeRequest.is_merged == 0" disabled severity="secondary" :label="`Правки отклонены: ${ mergeRequest.action_at }`" icon="pi pi-times" />
    <Button v-else-if="mergeRequest.src_ver != mergeRequest.page.merge_ver" disabled severity="secondary" label="Ожидает обновления" />
    <Button v-else @click.prevent="merge" label="Применить правки" icon="pi pi-check" />

    <Button v-if="isRebaseBtnSeen" @click.prevent="rebase" label="Обновить" style='margin: 0 10px;' icon="pi pi-wrench" />

    <Button v-if="isRejectBtnSeen" @click.prevent="reject" label="Отклонить" text severity="danger" style='margin-left: auto' icon="pi pi-trash" />
  </div>

  <div class="errors">{{ errors }}</div>

  <div class="merge-request looks-like-page">

    <div class="diff" v-for="(val,key) in mergeRequest.attrs_diff">
      <div class="diff-title">{{ pageFields[key] }}</div>
      <table class="diff-groups">
        <tr class="line remove">
          <td class="line-num mono-font">0</td>
          <td class="line-action mono-font">-</td>
          <td class="line-content">{{ val['old'] ? val['old'] : mergeRequest.page[key] }}</td>
        </tr>
        <tr class="line add">
          <td class="line-num mono-font">0</td>
          <td class="line-action mono-font">+</td>
          <td class="line-content">{{ val['new'] }}</td>
        </tr>
      </table>
    </div>

    <div v-for="(diffsInfo, fieldName) in mergeRequest.diffs">
      <div class="diff-title diff-summary">
        {{ pageFields[fieldName] }}: <span class="plus mono-font" v-if="diffsInfo.p_i">+{{ diffsInfo.p_i }}</span> <span class="minus mono-font" v-if="diffsInfo.m_i">-{{ diffsInfo.m_i }}</span>
      </div>
      <div class="diff" v-for="group in diffWithContext(diffsInfo.diffs, mergeRequest.page.text_arrs[fieldName])">
        <table class="diff-groups">
          <tr
            v-for="action in group"
            :class="`line
              ${(action[0] == '+' && action[1] != '?') ? 'add' : ''}
              ${(action[0] == '-' && action[1] != '?') ? 'remove' : ''}
              ${(action[0] == '' || action[1] == '?') ? 'eq' : ''}`"
          >
            <td class="line-num mono-font">{{ action[1] }}</td>
            <td class="line-action mono-font">{{ action[0] }}</td>
            <td class="line-content" v-html="action[2]"/>
          </tr>
        </table>
      </div>
    </div>

    <div class="help-info">
      <div class="title">Подсказки:</div>
      <div class="help-row">"-" — строка будет удалена (красная).</div>
      <div class="help-row">"+" — строка будет добавлена (зелёная).</div>
      <div class="help-row">" " — строка является лишь подсказкой (серая).</div>
      <div class="help-row">"?" — строка не будет обработана, так как на её месте уже находятся чужие изменения, а поэтому нам непонятно как с ней поступить, поэтому просто игнорируем её.</div>
    </div>
  </div>
</div>
</template>

<style scoped>
i.badge {
  top: -13px;
  margin: 0 0 0 5px;
  font-size: 0.3em;
}

label {
  font-size: 0.8em;
  color: #666;
}

button.green {
  background-color: #00b377;
  color: #fff;
  border-radius: 5px;
  border: 0px;
}

button.green:hover {
  background-color: #10c286;
  border: 0px;
}
button.green:active {
  background-color: #08a16e;
  border: 0px;
}

.diff-title {
  margin: 20px 0 -10px 0;
  font-weight: 500;
}

.diff-summary {
  margin: 15px 0;
}

.plus, .minus {
  font-weight: bold;
}
.plus {
  color: #00b377;
}
.minus {
  color: #ef4343;
}

.mono-font {
  font-family: "DejaVu Sans Mono", "Liberation Mono", "Consolas", "Ubuntu Mono", "Courier New", "andale mono", "lucida console", monospace
}

table.diff-groups {
  border-collapse: collapse;
  border-spacing: 0px;
  margin: 20px 0;
}

td.line-num {
  user-select: none;
  color: #ffffff;
  vertical-align: top;
  padding: 6px;
  text-align: right;
  font-size: 0.8em;
  font-weight: bold;
}

td.line-action {
  user-select: none;
  color: #888;
  width: 30px;
  text-align: center;
  vertical-align: top;
  padding: 6px 5px 0 5px;
  font-size: 0.8em;
  font-weight: bold;
}

td.line-content {
  width: 100%;
}

tr.line.eq td.line-content {
  color: #bbb;
}

tr.line.eq td.line-num {
  background-color: #ddd;
}
tr.line.add td.line-num {
  background-color: #00b37788;
}
tr.line.remove td.line-num {
  background-color: #f1afb8;
}

tr.line.eq:hover td.line-num {
  background-color: #ccc;
}
tr.line.add:hover td.line-num {
  background-color: #01b478c4;
}
tr.line.remove:hover td.line-num {
  background-color: #eb9aa5;
}

tr.eq {
  background-color: #eee;
}
tr.add {
  background-color: #00b37739;
}
tr.remove {
  background-color: #f9d7dc;
}

.help-info { margin: 25px 0;}
.help-info .title { font-weight: bold; font-size: 0.8em; }
.help-info .help-row { font-size: 0.7em; }
</style>
