<script setup>
import { telegramLoginTemp } from 'vue3-telegram-login'
import { ref } from "vue"
import { getCookie, setCookie } from "@/libs/cookies.js"
import { inject } from "vue"
import router from "@/router/index"

// уходим на главную, если уже авторизованы
if (getCookie('api_token') !== '') {
  router.push('/')
}

const api = inject('api')

const isLoaded = ref(false)

function telegramLoadedCallbackFunc () {
  console.log('script is loaded')
  isLoaded.value = true
}

function yourCallbackFunction (user) {
  // gets user as an input
  // id, first_name, last_name, username,
  // photo_url, auth_date and hash
  // console.log(user)

  //alert('Logged in as ' + user.first_name + ' ' + user.last_name + ' (' + user.id + (user.username ? ', @' + user.username : '') + ')');
  const params = {
    id: user.id,
    first_name: user.first_name,
    last_name: user.last_name,
    username: user.username,
    photo_url: user.photo_url,
    auth_date: user.auth_date,
    hash: user.hash,
  };
  api.post('/login/telegram/', params)
  .then(function (response) {
    const data = response.data;
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


// function () {
// this.$http.post('http://somehost/user/login', {
//   password: this.password,
//   email: this.email
// }).then(function (response) {
//   if (response.status === 200 && 'token' in response.body) {
//     this.$session.start()
//     this.$session.set('jwt', response.body.token)
//     Vue.http.headers.common['Authorization'] = 'Bearer ' + response.body.token
//     this.$router.push('/panel/search')
//   }
// }, function (err) {
//   console.log('err', err)
// })
// }
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
