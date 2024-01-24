import { createApp } from "vue"

import PrimeVue from 'primevue/config'
import 'primevue/resources/themes/lara-light-green/theme.css'
import 'primeicons/primeicons.css'
import "@/style.css"

import App from '@/App.vue'
import Login from '@/Login.vue'
import { getCookie } from "@/libs/cookies"
import router from "@/router/index"

import ConfirmationService from 'primevue/confirmationservice';
import ToastService from 'primevue/toastservice';
import Toast from 'primevue/toast';

// TODO: также сделать тестовый запрос для проверки авторизации и если что отправить в логин
const mainComponent = getCookie('api_token') === '' ? Login : App;

const app = createApp(mainComponent);

// // this.$api can be accessed in any component (but not in script-setup)
// app.config.globalProperties.$api = axiosInstance
// // to access in script-setup, call: import { inject } from 'vue'; const api = inject('api')
// app.provide('api', axiosInstance)

app.use(router);
app.use(PrimeVue);
app.use(ToastService);
app.use(ConfirmationService);
app.component('Toast', Toast);
app.mount('#app');
