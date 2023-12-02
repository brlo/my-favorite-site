import axios from 'axios'
import { getCookie } from './cookies'

// console.log('import.meta.env.VITE_API_URL', import.meta.env.VITE_API_URL)
const axiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_URL, // задаётся в .env.local (local не уходит в git)
  timeout: 1000,
  headers: {'X-API-TOKEN': getCookie('api_token')},
})

// const post = await fetch(`/api/post/1`).then(r => r.json())
export default axiosInstance
