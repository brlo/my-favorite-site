<script setup>
import { telegramLoginTemp } from 'vue3-telegram-login'
import { ref } from "vue"
import { getCookie, setCookie } from "@/libs/cookies.js"
import { api } from '@/libs/api.js'
import router from "@/router/index"

// уходим на главную, если уже авторизованы
if (getCookie('api_token') !== '') {
  router.push('/')
}

const isLoaded = ref(false)

function telegramLoadedCallbackFunc () {
  console.log('script is loaded')
  isLoaded.value = true
}

function yourCallbackFunction (data) {
  // gets user as an input
  // id, first_name, last_name, username,
  // photo_url, auth_date and hash
  // console.log(user)

  //alert('Logged in as ' + user.first_name + ' ' + user.last_name + ' (' + user.id + (user.username ? ', @' + user.username : '') + ')');
  const params = { tg_data: data };

  api.post('/login/telegram/', params).then(data => {
    if (data.success == 'ok') {
      setCookie('api_token', data.api_token, '999');
      window.location.reload()
    } else {
      errors.value = 'Неправильный пароль: ' + params.password
    };
  }).catch(function (error) {
    console.log('error', error);
  });
}
</script>

<template>
<div class="form">
  <span v-if="!isLoaded">Loading...</span>
  <telegram-login-temp
    mode="callback"
    telegram-login="bibleox_bot"
    @loaded='telegramLoadedCallbackFunc'
    @callback="yourCallbackFunction"
  />
</div>
</template>

<style scoped>
.form {
  display:flex;
  align-items: center;
  justify-content: center;
  min-height: 200px;
}
</style>
