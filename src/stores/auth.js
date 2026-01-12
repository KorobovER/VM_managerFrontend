import { reactive, computed } from 'vue'
import axios from 'axios'

const state = reactive({
  user: null,
  token: localStorage.getItem('access_token') || null,
  loading: false,
})

export const useAuthStore = () => {
  const isAuthenticated = computed(() => !!state.token)
  const isAdmin = computed(() => state.user?.role === 'admin')
  const currentUser = computed(() => state.user)

  const login = async (username, password) => {
    state.loading = true
    try {
      const formData = new URLSearchParams()
      formData.append('username', username)
      formData.append('password', password)

      const response = await axios.post('/api/auth/token', formData, {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      })

      state.token = response.data.access_token
      localStorage.setItem('access_token', response.data.access_token)

      await fetchUser()
      return { success: true }
    } catch (error) {
      return { success: false, error: error.response?.data?.detail || 'Ошибка авторизации' }
    } finally {
      state.loading = false
    }
  }

  const fetchUser = async () => {
    if (!state.token) return

    try {
      const response = await axios.get('/api/auth/me', {
        headers: {
          Authorization: `Bearer ${state.token}`,
        },
      })
      state.user = response.data
    } catch (error) {
      logout()
      throw error
    }
  }

  const logout = () => {
    state.user = null
    state.token = null
    localStorage.removeItem('access_token')
  }

  const register = async (userData) => {
    try {
      const response = await axios.post('/api/auth/register', userData, {
        headers: {
          Authorization: `Bearer ${state.token}`,
        },
      })
      return { success: true, data: response.data }
    } catch (error) {
      return { success: false, error: error.response?.data?.detail || 'Ошибка регистрации' }
    }
  }

  return {
    state,
    isAuthenticated,
    isAdmin,
    currentUser,
    login,
    logout,
    fetchUser,
    register,
  }
}
