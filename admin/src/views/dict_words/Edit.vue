<script setup>
import { ref, computed } from "vue";
// import Tiptap from "@/components/Tiptap.vue";
// import router from "@/router/index";
// import EditMenu from "@/components/EditMenu.vue";
// import AutocompletePage from "@/components/AutocompletePage.vue";
// import IndexMergeRequests from "@/views/merge_requests/Index.vue";
// import InputSwitch from 'primevue/inputswitch';
// import Dropdown from 'primevue/dropdown';
// import InputText from 'primevue/inputtext';
// import Button from 'primevue/button';

import { useToast } from "primevue/usetoast";
import { api } from '@/libs/api.js';

// задаётся в .env.local (local не уходит в git)
const apiUrl = import.meta.env.VITE_API_URL

const toast = useToast();
const toastError = (t, msg) => { toast.add({ severity: 'error', summary: t, detail: msg, life: 5000 }) }
const toastSuccess = (t, msg) => { toast.add({ severity: 'success', summary: t, detail: msg, life: 5000 }) }
const toastInfo = (t, msg) => { toast.add({ severity: 'info', summary: t, detail: msg, life: 5000 }) }

const props = defineProps({
  id: String
})
</script>

<template>
</template>

<style scoped>
</style>
