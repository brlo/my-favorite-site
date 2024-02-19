import { getCookie } from './cookies'

// задаётся в .env.local (local не уходит в git)
const apiUrl = import.meta.env.VITE_API_URL

// Штука для отмены запросов (по таймату или вручную)
// doc: https://stackoverflow.com/questions/31061838/how-do-i-cancel-an-http-fetch-request/47250621#47250621
const controller = new AbortController()
const signal = controller.signal

// ЗАПРОС
function httpRequest(method, path, queryParams, body, options) {
  // queryParams дописываем в path
  if (queryParams) path = path + '?' + new URLSearchParams(queryParams);

  // теперь можно собрать url
  const url = apiUrl + '/ru/api' + path;

  // Подготовим body для PUT и POST запросов
  const bodyJSON = JSON.stringify(body);

  const headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'X-API-TOKEN': getCookie('api_token'),
  }

  console.log(method + ': ' + url, bodyJSON, options)

  const timeout = setTimeout(() => controller.abort(), 10000);

  const promise = fetch(url, {
    method: method,
    body: bodyJSON,
    headers: headers,
    signal: controller.signal,
    // ...options,
  })
  .then(response => response.json())
  .finally(() => clearTimeout(timeout))

  return promise;
}

const api = {
  get:    (path, queryParams, options) => { return httpRequest('GET', path, queryParams, undefined, options) },
  post:   (path, body, options)        => { return httpRequest('POST', path, undefined, body, options) },
  put:    (path, body, options)        => { return httpRequest('PUT', path, undefined, body, options) },
  delete: (path, body, options)        => { return httpRequest('DELETE', path, undefined, body, options) },
}

// export default api
export { api }
