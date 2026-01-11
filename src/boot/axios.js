import axios from 'axios'

// Переписываем все запросы, убирая /api
axios.interceptors.request.use((config) => {
  if (config.url && config.url.startsWith('/api/')) {
    config.url = config.url.replace('/api/', '/')
  }
  return config
})
