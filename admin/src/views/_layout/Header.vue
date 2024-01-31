<script setup>
const apiUrl = import.meta.env.VITE_API_URL

const props = defineProps({
  user: Object
})

function logout() {
  if (window.confirm("Вы точно хотите выйти из своего профиля?")) {
    document.cookie = 'api_token=; Max-Age=-99999999;';
    location.reload();
  }
}
</script>

<template>
<header>
  <div class="container">
    <div class="logo">
      <a :href="`${apiUrl}/`">
        <img src="@/assets/bibleox-ru.png">
      </a>
    </div>
    <nav>
      <router-link v-if="user.privs.pages_read" to="/">Сводка</router-link>
      <router-link v-if="user.privs.pages_read" to="/pages">Статьи</router-link>
      <router-link v-if="user.privs.mr_read" to="/merge_requests">Правки</router-link>
      <router-link v-if="user.privs.dict_read" to="/dict_words">Словарь</router-link>
      <span id="you" v-if="user">Вы: <a @click.prevent="logout" id="you">{{ user.name }}</a></span>
    </nav>
  </div>
</header>
</template>

<style scoped>
header {
  background-color: #f6f4e4;
}

header .container {
  position: relative;
  max-width: 1200px;
  width: 100%;
  padding: 12px 10px;
  margin: 0 auto;
}

header nav {
  display: flex;
  padding: 10px 0 0 0;
}
header nav > a {
  padding-right: 10px;
}
header nav > a#settings-btn {
  margin-left: auto;
  padding-right: 0;
}

.logo img {
  width: 120px;
  background-color: #d0d7be;
  padding: 8px 10px;
  border-radius: 4px;
  -webkit-transition: background-color 124ms linear;
  -ms-transition: background-color 124ms linear;
  transition: background-color 124ms linear;
}

.night-mode .logo img {
  background-color: #c0cda1;
}

.logo img:hover {
  background-color: #a4d091;
}
.logo img:active {
  background-color: #a2b997;
}

#you {
  margin-left: auto;
}
</style>
