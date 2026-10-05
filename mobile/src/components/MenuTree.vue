<script setup>
// Дерево меню страницы-списка (как pages/_menu на сайте)
defineOptions({ name: 'MenuTree' })
const props = defineProps({
  items: Array,
  depth: { type: Number, default: 0 },
  lang: String,
  icons: Object, // path_low -> url иконки
  downloaded: Object, // Set path_low скачанных страниц
})
</script>

<template>
  <div class="items">
    <template v-for="item in props.items" :key="item.id">
      <div v-if="item.childs.length" :class="['menu-subject', `depth-${props.depth}`, { gold: item.is_gold }]">
        <router-link v-if="item.path" :to="{ name: 'page', params: { lang: props.lang, path: item.path } }">{{ item.title }}</router-link>
        <template v-else>{{ item.title }}</template>
      </div>
      <div
        v-else
        :class="['menu-unit', `depth-${props.depth}`, { gold: item.is_gold, 'not-exist': !item.path || item.is_empty }]"
      >
        <router-link v-if="item.path" :to="{ name: 'page', params: { lang: props.lang, path: item.path } }">
          <img v-if="props.icons?.[item.path.toLowerCase()]" class="menu-icon" :src="props.icons[item.path.toLowerCase()]" loading="lazy" alt="" />
          <span>{{ item.title }}</span>
          <i v-if="props.downloaded?.has(item.path.toLowerCase())" class="saved-dot" title="offline"></i>
        </router-link>
        <span v-else>{{ item.title }}</span>
      </div>
      <div v-if="item.childs.length" class="level">
        <MenuTree :items="item.childs" :depth="props.depth + 1" :lang="props.lang" :icons="props.icons" :downloaded="props.downloaded" />
      </div>
    </template>
  </div>
</template>
