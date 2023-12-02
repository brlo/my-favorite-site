<script setup>
import Header from "@/views/_layout/Header.vue";
import Footer from "@/views/_layout/Footer.vue";
</script>

<template>
<Header />

<div class='flex-wrap'>
  <div class='content'>
    <router-view></router-view>
  </div>
</div>

<Footer />
</template>

<style scoped>
</style>
