<script setup>
import IndexStats from "@/views/stats/Index.vue";
import IndexPages from "@/views/pages/Index.vue";

const props = defineProps({
  currentUser: Object,
})
</script>

<template>
<IndexStats />
<div class="divider"></div>
<IndexPages :isListOnly="true" :limit="5" />
</template>

<style scoped>
.divider {
  margin: 15px 0 25px 0;
  border-top: 1px solid #777;
}
</style>
