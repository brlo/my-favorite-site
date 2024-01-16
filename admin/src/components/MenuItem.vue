<script setup>
// https://vue-hero-icons.netlify.app/
// import { TrashIcon } from "@vue-hero-icons/outline"

const props = defineProps({
  item: Object
})

const emit = defineEmits(['forUpdate','destroy'])

function clickDestroy() {
  emit('destroy', props.item)
}
function clickForUpdate() {
  emit('forUpdate', props.item)
}
</script>

<template>
<div class="menu-element">
  <div class="menu-element-title">
    <span v-if="item.path">
      <a @click.prevent="clickForUpdate">{{ item.title }}</a> / {{ item.priority }}
    </span>
    <span v-else @click.prevent="clickForUpdate">
      <b>{{ item.title }}</b> / {{ item.priority }}
    </span>

    <a @click.prevent="clickDestroy" class="menu-destroy-icon">
      <svg style="width:15px;" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
        <path stroke-linecap="round" stroke-linejoin="round" d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0" />
      </svg>
    </a>
  </div>

  <div class="menu-element-childs">
    <MenuItem
      v-for="child in item.childs"
      :item="child"
      @destroy="(item) => { emit('destroy', item) }"
      @forUpdate="(item) => { emit('forUpdate', item) }"
    />
  </div>
</div>
</template>

<style scoped>
.menu-element-title {
  margin: 5px 0;
}

.menu-element-childs {
  margin: 0 0 0 15px;
}

.menu-destroy-icon {
  margin: 0 0 0 10px;
}
</style>
