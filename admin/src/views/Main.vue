<script setup>
import IndexMergeRequests from "@/views/merge_requests/Index.vue";
import IndexPages from "@/views/pages/Index.vue";

</script>

<template>
<IndexMergeRequests :isListOnly="true" />
<div class="divider"></div>
<IndexPages :isListOnly="true" />
</template>

<style scoped>
.divider {
  margin: 15px 0 25px 0;
  border-top: 1px solid #777;
}
</style>
