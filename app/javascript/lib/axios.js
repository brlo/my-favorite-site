import axios from "axios"
// Автоматически отправлять CSRF-токен в заголовках
const csrfToken = document.querySelector("meta[name='csrf-token']")
if (csrfToken) {
  axios.defaults.headers.common["X-CSRF-Token"] = csrfToken.content
}

export default axios
