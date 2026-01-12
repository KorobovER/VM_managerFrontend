<template>
  <q-layout view="lHh Lpr lFf" class="hiveon-bg">
    <q-header elevated class="hiveon-header">
      <q-toolbar>
        <q-toolbar-title>
          <span class="hiveon-logo">VM Manager</span>
        </q-toolbar-title>
        <div class="nav-links">
          <router-link to="/" class="nav-link">Виртуальные машины</router-link>
          <router-link v-if="isAdmin" to="/servers" class="nav-link">Серверы</router-link>
          <router-link v-if="isAdmin" to="/register" class="nav-link">Регистрация</router-link>
        </div>
        <div class="user-info">
          <span class="username">{{ currentUser?.username }}</span>
          <span class="user-role" :class="currentUser?.role">{{ roleLabel }}</span>
          <button @click="handleLogout" class="logout-btn">Выход</button>
        </div>
      </q-toolbar>
    </q-header>
    <q-page-container>
      <router-view />
    </q-page-container>
  </q-layout>
</template>

<script>
import { computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from 'src/stores/auth'

export default {
  name: "MainLayout",
  setup() {
    const router = useRouter()
    const authStore = useAuthStore()

    const isAdmin = computed(() => authStore.isAdmin.value)
    const currentUser = computed(() => authStore.currentUser.value)
    const roleLabel = computed(() => {
      return currentUser.value?.role === 'admin' ? 'Администратор' : 'Пользователь'
    })

    const handleLogout = () => {
      authStore.logout()
      router.push('/login')
    }

    onMounted(async () => {
      if (!authStore.state.user && authStore.state.token) {
        try {
          await authStore.fetchUser()
        } catch {
          router.push('/login')
        }
      }
    })

    return {
      isAdmin,
      currentUser,
      roleLabel,
      handleLogout
    }
  }
}
</script>

<style scoped>
.hiveon-bg {
  background: var(--hiveon-bg) !important;
  min-height: 100vh;
}

.hiveon-header {
  background: var(--hiveon-card) !important;
  color: var(--hiveon-cyan) !important;
  border-bottom: 1px solid #20262f;
}

.hiveon-logo {
  font-weight: 800;
  font-size: 1.25rem;
  color: var(--hiveon-cyan);
  letter-spacing: 0.03em;
}

.nav-links {
  display: flex;
  gap: 24px;
  margin-left: 48px;
}

.nav-link {
  color: #a0aec0;
  text-decoration: none;
  font-weight: 500;
  font-size: 15px;
  transition: color 0.2s;
  padding: 8px 12px;
  border-radius: 6px;
}

.nav-link:hover {
  color: var(--hiveon-cyan);
  background: rgba(102, 126, 234, 0.1);
}

.nav-link.router-link-active {
  color: var(--hiveon-cyan);
  font-weight: 600;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-left: auto;
}

.username {
  color: var(--hiveon-text);
  font-weight: 600;
  font-size: 14px;
}

.user-role {
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
}

.user-role.admin {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.user-role.user {
  background: #48bb78;
  color: white;
}

.logout-btn {
  padding: 8px 16px;
  background: transparent;
  border: 2px solid #e2e8f0;
  color: var(--hiveon-text);
  border-radius: 6px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.logout-btn:hover {
  background: #e2e8f0;
  border-color: #cbd5e0;
}
</style>
