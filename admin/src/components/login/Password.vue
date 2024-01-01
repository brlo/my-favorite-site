<script setup>
import { ref, computed } from "vue"
import { getCookie, setCookie } from "@/libs/cookies.js"
import { api } from '@/libs/api.js'
import router from "@/router/index"

// уходим на главную, если уже авторизованы
if (getCookie('api_token') !== '') {
  router.push('/')
}

const usernameInput = ref('')
const pswInput = ref('')
const errors = ref('')

function doLogin() {
  const params = {
    username: usernameInput.value,
    password: pswInput.value,
  }

  api.post('/login/psw/', params).then(data => {
    if (data.success == 'ok') {
      setCookie('api_token', data.api_token, '999');
      window.location.reload()
    } else {
      errors.value = 'Неправильный пароль: ' + params.password
    };
  }).catch(function (error) {
    console.log('error', error);
  });
  // if (params.username == 'admin' && params.password == '111') {
  //   setCookie('api_token', 'admin', 999)
  //   window.location.reload()
  // } else {
  //   errors.value = 'Неправильный пароль: ' + params.password
  // }
}

const isValidUsername = computed(() => usernameInput.value.length > 0);
const isValidPsw = computed(() => pswInput.value.length > 0);
const isFormValid = computed(() => isValidUsername.value && isValidPsw.value);
</script>

<template>
<form @submit.prevent="doLogin">
  <div class="form-center">

    <div class="form-control">
      <label>Логин</label>
      <input v-model="usernameInput" type="text" autocomplete="current-username" />
    </div>

    <div class="form-control">
      <label>Пароль</label>
      <input v-model="pswInput" type="password" autocomplete="current-password" />
    </div>

    <input type="submit" value="Войти" class="btn" :disabled="!isFormValid"/>

    <div class="errors" v-if="errors.length">{{ errors }}</div>
  </div>
</form>
</template>

<style scoped>
form {
  display:flex;
  align-items: center;
  justify-content: center;
  margin: 10px;
}
</style>
