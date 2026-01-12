import { boot } from 'quasar/wrappers'
import axios from 'axios'

const api = axios.create()

export default boot(({ app, router }) => {
  const requestInterceptor = (config) => {
    const token = localStorage.getItem('access_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  }

  const responseInterceptor = (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('access_token')
      router.push('/login')
    }
    return Promise.reject(error)
  }

  // Добавляем interceptor'ы к глобальному axios
  axios.interceptors.request.use(requestInterceptor, (error) => Promise.reject(error))
  axios.interceptors.response.use((response) => response, responseInterceptor)

  // Добавляем interceptor'ы к api instance
  api.interceptors.request.use(requestInterceptor, (error) => Promise.reject(error))
  api.interceptors.response.use((response) => response, responseInterceptor)

  app.config.globalProperties.$axios = axios
  app.config.globalProperties.$api = api
})

export { api }
