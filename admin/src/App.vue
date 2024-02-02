<script setup>
import { ref } from 'vue';
import { api } from '@/libs/api.js';
import Header from "@/views/_layout/Header.vue";
import Footer from "@/views/_layout/Footer.vue";

const user = ref();

const userClean = () => user.value = { privs: {} };

function getUser() {
  api.get('/users/me').then(data => {
    console.log('GET User', data)
    if (data.success == 'ok') {
      user.value = data;
    } else {
      user.value = false;
    }
  })
}
userClean();
getUser();
</script>

<template>
<Header :user="user" />

<div class='flex-wrap'>
  <div class='content'>
    <div v-if="user == false || user.privs.pages_read !== true">
      <h2>Ура! Вы зарегистрировались!</h2>

      <p>Но это ещё не всё, так как Ваша учётная запись ещё не подтверждена.</p>
      <p>Мы допускаем к редактированию статей только проверенных и не анонимных авторов.</p>

      <p>Пожалуйста, свяжитесь с нами для подтверждения записи: <a href='https://t.me/bibleox_live'>https://t.me/bibleox_live</a></p>
    </div>
    <router-view v-else-if="user.privs.pages_read" :currentUser="user"></router-view>
  </div>
</div>

<Footer />
</template>

<style scoped>
</style>
