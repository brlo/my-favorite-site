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
    <router-view v-if="user.privs.pages_read" :user="user"></router-view>
    <div v-else-if="user == false">
      <h2>Ура! Вы зарегистрировались!</h2>

      <p>Но это ещё не всё, так как Ваша учётная запись ещё не подтверждена.</p>
      <p>Мы допускаем к редактированию статей только неанонимных авторов.</p>

      <p>Пожалуйста, свяжитесь с нами для подтверждения записи: <a href='https://t.me/bibleox'>https://t.me/bibleox</a></p>
    </div>
  </div>
</div>

<Footer />
</template>

<style scoped>
</style>
