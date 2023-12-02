<script setup>
</script>

<template>
<header>
  <div class="container">
    <div class="logo">
      <a href="/ru/gen/1/">
        <img src="@/assets/bibleox-ru.png">
      </a>
    </div>
    <nav>
      <router-link to="/bibs">Из Библии</router-link>
      <router-link to="/fathers">Из отцов</router-link>

      <a href="javascript:" id="settings-btn" class="local">Настройки</a>
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
  max-width: 700px;
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
  /* background-color: #406c59; */
  padding: 8px 10px;
  border-radius: 4px;
  -webkit-transition: background-color 124ms linear;
  -ms-transition: background-color 124ms linear;
  transition: background-color 124ms linear;
}

.night-mode .logo img {
  background-color: #c0cda1;
  /* background-color: #406c59; */
}

.logo img:hover {
  background-color: #a4d091;
  /* background-color: #a4d091; */
}
.logo img:active {
  background-color: #a2b997;
  /* background-color: #a2b997; */
}
</style>
