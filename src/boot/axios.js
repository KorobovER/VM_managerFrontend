import axios from 'axios'

axios.defaults.baseURL = 'http://sinthy.fvds.ru:9922'

// Переписываем все запросы, убирая /api
axios.interceptors.request.use((config) => {
  if (config.url && config.url.startsWith('/api/')) {
    config.url = config.url.replace('/api/', '/')
  }
  return config
})
