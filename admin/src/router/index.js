// To access the router or the route inside the setup function,
// call the useRouter or useRoute functions.
// We will learn more about this in the Composition API
// Throughout the docs, we will often use the router instance.
// Keep in mind that this.$router is exactly the same as directly
// using the router instance created through createRouter.
import { createRouter, createWebHistory } from "vue-router"
import { getCookie } from "@/libs/cookies"

// 2. Define some routes
// Each route should map to a component.
// We'll talk about nested routes later.
const routes = [
  { path: "/", name: "Hello", component: ()=>import("@/views/Hello.vue")},
  { path: "/bibs", name: "Bibs", component: ()=>import("@/views/bibs/Index.vue")},
  { path: "/bibs/new", name: "NewBib", component: ()=>import("@/views/bibs/New.vue")},
  { path: "/bibs/:id([a-f0-9]+)", name: "EditBib", component: ()=>import("@/views/bibs/Edit.vue"), props: true},
  { path: "/fathers", name: "Fathers", component: ()=>import("@/views/fathers/Index.vue")},
  { path: "/fathers/new", name: "NewFather", component: ()=>import("@/views/fathers/New.vue")},
]

// docs: https://router.vuejs.org/guide/essentials/named-routes.html
const router = createRouter({
  // 4. Provide the history implementation to use. We are using the hash history for simplicity here.
  history: createWebHistory(),
  routes, // short for `routes: routes`
})

// router.beforeEach((to, from, next) => {
//   // Потом тут стоит ещё и запрос добавить для проверки, авторизован ли
//   // Достаточно проверить 1 раз при загрузке приложения.
//   if (to.name !== 'Login' && getCookie('api_token') === '') next({ name: 'Login' })
//   else next()
// })

export default router
