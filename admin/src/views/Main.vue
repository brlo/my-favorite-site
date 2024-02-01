<script setup>
import IndexStats from "@/views/stats/Index.vue";
import IndexMergeRequests from "@/views/merge_requests/Index.vue";
import IndexPages from "@/views/pages/Index.vue";

const props = defineProps({
  currentUser: Object,
})
</script>

<template>
<IndexStats />
<div class="divider"></div>
<div class="row">
  <div class="col-50">
    <IndexPages :isListOnly="true" :limit="5" />
  </div>
  <div class="col-50">
    <IndexMergeRequests :isListOnly="true" :limit="5" />
  </div>
</div>
</template>

<style scoped>
.row {
  display: flex;
}

.col-50 {
  flex: 50%;
  padding-right: 10px;
}

@media (max-width: 600px) {
  .row {
    display: flex;
    flex-direction: column;
  }
  .col-50 {
    flex: 100%;
  }
}

.divider {
  margin: 15px 0 25px 0;
  border-top: 1px solid #777;
}
</style>
