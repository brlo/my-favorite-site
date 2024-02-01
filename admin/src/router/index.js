// To access the router or the route inside the setup function,
// call the useRouter or useRoute functions.
// We will learn more about this in the Composition API
// Throughout the docs, we will often use the router instance.
// Keep in mind that this.$router is exactly the same as directly
// using the router instance created through createRouter.
import { createRouter, createWebHistory } from "vue-router"

// 2. Define some routes
// Each route should map to a component.
// We'll talk about nested routes later.
const routes = [
  { path: "/", name: "Main", component: ()=>import("@/views/Main.vue")},
  { path: "/pages", name: "Pages", component: ()=>import("@/views/pages/Index.vue")},
  { path: "/pages/new", name: "NewPage", component: ()=>import("@/views/pages/Edit.vue")},
  { path: "/pages/:id([a-f0-9]+)", name: "EditPage", component: ()=>import("@/views/pages/Edit.vue"), props: true},
  { path: "/dict_words", name: "DictWords", component: ()=>import("@/views/dict_words/Index.vue")},
  { path: "/dict_words/new", name: "NewDictWord", component: ()=>import("@/views/dict_words/Edit.vue")},
  { path: "/dict_words/:id([a-f0-9]+)", name: "EditDictWord", component: ()=>import("@/views/dict_words/Edit.vue"), props: true},
  { path: "/merge_requests", name: "MergeRequests", component: ()=>import("@/views/merge_requests/Index.vue")},
  { path: "/merge_requests/:id([a-f0-9]+)", name: "ShowMergeRequest", component: ()=>import("@/views/merge_requests/Show.vue"), props: true},
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
