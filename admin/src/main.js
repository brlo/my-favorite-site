import { createApp } from "vue"

import "@/style.css"
import App from '@/App.vue'
import Login from '@/Login.vue'
import { getCookie } from "@/libs/cookies"
import axiosInstance from "@/libs/axios"
import router from "@/router/index"

const mainComponent = getCookie('api_token') === '' ? Login : App
const app = createApp(mainComponent)
// this.$api can be accessed in any component (but not in script-setup)
app.config.globalProperties.$api = axiosInstance
// to access in script-setup, call: import { inject } from 'vue'; const api = inject('api')
app.provide('api', axiosInstance)
app.use(router)
app.mount('#app')
