<template>
  <div class="users-page">
    <div class="page-header">
      <h1>Управление пользователями</h1>
      <button @click="fetchUsers" class="hiveon-btn primary" :disabled="loading">
        🔄 Обновить
      </button>
    </div>

    <div v-if="loading" class="loading-container">
      <div class="loading-spinner"></div>
      <p>Загрузка пользователей...</p>
    </div>

    <div v-else-if="users.length === 0" class="empty-state">
      <div class="empty-icon">👥</div>
      <h3>Нет пользователей</h3>
      <p>Список пользователей пуст или не удалось загрузить данные</p>
    </div>

    <div v-else class="users-grid">
      <div v-for="user in users" :key="user.id" class="user-card">
        <div class="user-header">
          <div class="user-info">
            <h3>{{ user.username }}</h3>
            <span class="user-id">ID: {{ user.id }}</span>
          </div>
          <div class="user-status">
            <span class="status-badge" :class="{ active: user.is_active, inactive: !user.is_active }">
              {{ user.is_active ? 'Активен' : 'Неактивен' }}
            </span>
          </div>
        </div>

        <div class="user-details">
          <div class="detail-row">
            <span class="label">Email:</span>
            <span class="value">{{ user.email }}</span>
          </div>
          <div class="detail-row">
            <span class="label">Роль:</span>
            <span class="role-badge" :class="user.role">
              {{ user.role === 'admin' ? '👑 Администратор' : '👤 Пользователь' }}
            </span>
          </div>
        </div>

        <div class="user-actions">
          <button class="hiveon-btn info" @click="openAssignDialog(user)" title="Назначить ВМ">
            🖥️ Назначить ВМ
          </button>
        </div>
      </div>
    </div>

    <!-- Диалог назначения ВМ -->
    <div v-if="showAssignDialog" class="modal-overlay" @click="closeAssignDialog">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h2>Назначить ВМ пользователю</h2>
          <button @click="closeAssignDialog" class="close-btn">&times;</button>
        </div>
        <form @submit.prevent="assignVM" class="vm-form">
          <div class="form-group">
            <label>Пользователь</label>
            <input type="text" :value="selectedUser?.username" readonly class="form-input" />
          </div>
          <div class="form-group">
            <label>Сервер *</label>
            <select v-model="vmAssignment.server_id" @change="onServerChange" required class="form-input">
              <option :value="null" disabled>Выберите сервер</option>
              <option v-for="server in servers" :key="server.id" :value="server.id">
                {{ server.name }} ({{ server.host }}:{{ server.port }})
              </option>
            </select>
          </div>
          <div class="form-group">
            <label>Виртуальная машина *</label>
            <select v-model="vmAssignment.vm_name" required :disabled="!vmAssignment.server_id || loadingVMs"
              class="form-input">
              <option :value="null" disabled>
                {{ loadingVMs ? 'Загрузка...' : (vmAssignment.server_id ? 'Выберите ВМ' : 'Сначала выберите сервер') }}
              </option>
              <option v-for="vm in availableVMs" :key="vm.name" :value="vm.name">
                {{ vm.name }} ({{ vm.state }})
              </option>
            </select>
          </div>
          <div v-if="assignError" class="error-message">{{ assignError }}</div>
          <div class="form-actions">
            <button type="button" @click="closeAssignDialog" class="hiveon-btn">Отмена</button>
            <button type="submit" class="hiveon-btn success" :disabled="assignLoading || !vmAssignment.vm_name">
              {{ assignLoading ? 'Назначение...' : 'Назначить' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Диалог ошибки -->
    <div v-if="errorDialog" class="modal-overlay" @click="closeErrorDialog">
      <div class="modal-content error-modal" @click.stop>
        <div class="modal-header">
          <h3>⚠️ Ошибка</h3>
          <button @click="closeErrorDialog" class="close-btn">&times;</button>
        </div>
        <div class="modal-body">
          <p>{{ errorMessage }}</p>
        </div>
        <div class="modal-actions">
          <button @click="closeErrorDialog" class="hiveon-btn primary">OK</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'
import { useQuasar } from 'quasar'
import { api } from 'src/boot/axios'

export default {
  name: 'UsersPage',
  setup() {
    const $q = useQuasar()
    const users = ref([])
    const loading = ref(false)
    const errorDialog = ref(false)
    const errorMessage = ref('')
    const showAssignDialog = ref(false)
    const selectedUser = ref(null)
    const assignLoading = ref(false)
    const assignError = ref('')
    const servers = ref([])
    const availableVMs = ref([])
    const loadingVMs = ref(false)
    const vmAssignment = ref({
      user_id: null,
      server_id: null,
      vm_name: '',
      server_host: '',
      server_port: 16509
    })

    const fetchUsers = async () => {
      loading.value = true
      try {
        const response = await api.get('api/admin/users')
        console.log('Response from /admin/users:', response)
        console.log('Response data:', response.data)

        users.value = Array.isArray(response.data) ? response.data : []
      } catch (error) {
        console.error('Ошибка при загрузке пользователей:', error)
        users.value = []
        errorMessage.value = error.response?.data?.detail || 'Ошибка при загрузке пользователей'
        errorDialog.value = true
      } finally {
        loading.value = false
      }
    }

    const closeErrorDialog = () => {
      errorDialog.value = false
      errorMessage.value = ''
    }

    const fetchServers = async () => {
      try {
        const response = await api.get('/api/servers')
        servers.value = response.data || []
      } catch (error) {
        console.error('Ошибка загрузки серверов:', error)
      }
    }

    const fetchVMs = async (serverId) => {
      if (!serverId) return

      const server = servers.value.find(s => s.id === serverId)
      if (!server) return

      loadingVMs.value = true
      try {
        const response = await api.get(`/api/vms/available?host=${server.host}&port=${server.port}`)
        availableVMs.value = response.data.vms || []
      } catch (error) {
        console.error('Ошибка загрузки ВМ:', error)
        availableVMs.value = []
      } finally {
        loadingVMs.value = false
      }
    }

    const onServerChange = () => {
      vmAssignment.value.vm_name = ''
      availableVMs.value = []
      if (vmAssignment.value.server_id) {
        fetchVMs(vmAssignment.value.server_id)
      }
    }

    const openAssignDialog = (user) => {
      selectedUser.value = user
      vmAssignment.value = {
        user_id: user.id,
        server_id: null,
        vm_name: '',
        server_host: '',
        server_port: 16509
      }
      availableVMs.value = []
      assignError.value = ''
      showAssignDialog.value = true
    }

    const closeAssignDialog = () => {
      showAssignDialog.value = false
      selectedUser.value = null
      vmAssignment.value = {
        user_id: null,
        server_id: null,
        vm_name: '',
        server_host: '',
        server_port: 16509
      }
      availableVMs.value = []
      assignError.value = ''
    }

    const assignVM = async () => {
      assignLoading.value = true
      assignError.value = ''

      try {
        // Получаем данные сервера
        const server = servers.value.find(s => s.id === vmAssignment.value.server_id)
        if (!server) {
          throw new Error('Сервер не найден')
        }

        // Формируем данные для запроса
        const requestData = {
          user_id: vmAssignment.value.user_id,
          vm_name: vmAssignment.value.vm_name,
          server_host: server.host,
          server_port: server.port
        }

        const response = await api.post('api/admin/assign-vm', requestData)
        console.log('VM assigned successfully:', response.data)

        // Показываем уведомление об успехе
        $q.notify({
          type: 'positive',
          message: `ВМ "${vmAssignment.value.vm_name}" успешно назначена пользователю "${selectedUser.value.username}"`,
          position: 'top-right',
          icon: 'check_circle',
          timeout: 2500
        })

        closeAssignDialog()
      } catch (error) {
        console.error('Ошибка при назначении ВМ:', error)
        assignError.value = error.response?.data?.detail || 'Ошибка при назначении ВМ'
      } finally {
        assignLoading.value = false
      }
    }

    onMounted(() => {
      fetchUsers()
      fetchServers()
    })

    return {
      $q,
      users,
      loading,
      errorDialog,
      errorMessage,
      showAssignDialog,
      selectedUser,
      assignLoading,
      assignError,
      servers,
      availableVMs,
      loadingVMs,
      vmAssignment,
      fetchUsers,
      closeErrorDialog,
      fetchServers,
      fetchVMs,
      onServerChange,
      openAssignDialog,
      closeAssignDialog,
      assignVM
    }
  }
}
</script>

<style scoped>
.users-page {
  padding: 24px;
  max-width: 1400px;
  margin: 0 auto;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 32px;
}

.page-header h1 {
  font-size: 32px;
  font-weight: 700;
  color: #1a202c;
  margin: 0;
}

.loading-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  color: #1a202c;
}

.loading-spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #e2e8f0;
  border-top: 4px solid var(--hiveon-cyan);
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 16px;
}

@keyframes spin {
  0% {
    transform: rotate(0deg);
  }

  100% {
    transform: rotate(360deg);
  }
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 80px 20px;
  text-align: center;
}

.empty-icon {
  font-size: 64px;
  margin-bottom: 16px;
  opacity: 0.5;
}

.empty-state h3 {
  font-size: 24px;
  font-weight: 600;
  color: #1a202c;
  margin: 0 0 8px 0;
}

.empty-state p {
  color: #a0aec0;
  font-size: 16px;
  margin: 0;
}

.users-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(380px, 1fr));
  gap: 24px;
}

.user-card {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  transition: transform 0.2s, box-shadow 0.2s;
}

.user-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.15);
}

.user-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  padding-bottom: 16px;
  border-bottom: 2px solid #e2e8f0;
}

.user-info {
  flex: 1;
}

.user-info h3 {
  font-size: 20px;
  font-weight: 600;
  color: #2d3748;
  margin: 0;
}

.user-id {
  font-size: 12px;
  color: #718096;
  background: #edf2f7;
  padding: 4px 8px;
  border-radius: 4px;
}

.user-status {
  flex-shrink: 0;
}

.status-badge {
  font-size: 12px;
  font-weight: 600;
  padding: 4px 12px;
  border-radius: 12px;
  text-transform: uppercase;
}

.status-badge.active {
  background: rgba(72, 187, 120, 0.2);
  color: #48bb78;
}

.status-badge.inactive {
  background: rgba(245, 101, 101, 0.2);
  color: #f56565;
}

.user-details {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-bottom: 20px;
}

.detail-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.detail-row .label {
  font-size: 14px;
  color: #718096;
  font-weight: 500;
}

.detail-row .value {
  font-size: 14px;
  color: #2d3748;
  font-weight: 600;
  text-align: right;
  max-width: 60%;
  word-break: break-word;
}

.role-badge {
  font-size: 12px;
  font-weight: 600;
  padding: 4px 12px;
  border-radius: 12px;
}

.role-badge.admin {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.role-badge.user {
  background: rgba(72, 187, 120, 0.2);
  color: #48bb78;
}

.user-actions {
  margin-top: 16px;
  padding-top: 16px;
  border-top: 1px solid #e2e8f0;
  display: flex;
  gap: 8px;
  justify-content: space-between;
}

.hiveon-btn {
  padding: 12px 24px;
  border: none;
  border-radius: 8px;
  font-size: 15px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  background: #e2e8f0;
  color: #2d3748;
}

.hiveon-btn:hover {
  background: #cbd5e0;
}

.hiveon-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}

.hiveon-btn.primary {
  background: linear-gradient(135deg, var(--hiveon-cyan) 0%, #667eea 100%);
  color: white;
}

.hiveon-btn.primary:hover:not(:disabled) {
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
}

.hiveon-btn.info {
  background: linear-gradient(135deg, #4299e1 0%, #3182ce 100%);
  color: white;
}

.hiveon-btn.info:hover:not(:disabled) {
  box-shadow: 0 4px 12px rgba(66, 153, 225, 0.3);
}

.hiveon-btn.success {
  background: linear-gradient(135deg, #48bb78 0%, #38a169 100%);
  color: white;
}

.hiveon-btn.success:hover:not(:disabled) {
  box-shadow: 0 4px 12px rgba(72, 187, 120, 0.3);
}

.hiveon-btn.warning {
  background: linear-gradient(135deg, #f6ad55 0%, #ed8936 100%);
  color: white;
}

.hiveon-btn.warning:hover:not(:disabled) {
  box-shadow: 0 4px 12px rgba(246, 173, 85, 0.3);
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 16px;
  padding: 32px;
  width: 90%;
  max-width: 500px;
  max-height: 90vh;
  overflow-y: auto;
}

.error-modal .modal-header {
  color: #f56565;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.modal-header h2 {
  font-size: 24px;
  font-weight: 700;
  color: #1a202c;
  margin: 0;
}

.close-btn {
  background: none;
  border: none;
  font-size: 24px;
  color: #a0aec0;
  cursor: pointer;
  line-height: 1;
  padding: 0;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.close-btn:hover {
  color: #2d3748;
}

.modal-body {
  margin-bottom: 20px;
}

.modal-body p {
  color: #2d3748;
  margin: 0;
  line-height: 1.5;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
}

.vm-form {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.form-group label {
  font-size: 14px;
  font-weight: 600;
  color: #2d3748;
}

.form-input {
  padding: 12px 16px;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  font-size: 15px;
  transition: all 0.2s;
  outline: none;
  background: white;
  color: #2d3748;
}

.form-input:focus {
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.form-input[readonly] {
  background: #f7fafc;
  color: #718096;
}

.form-input:disabled {
  background: #f7fafc;
  color: #a0aec0;
  cursor: not-allowed;
}

select.form-input {
  cursor: pointer;
}

select.form-input:disabled {
  cursor: not-allowed;
}

.error-message {
  padding: 12px;
  background: #fed7d7;
  color: #c53030;
  border-radius: 8px;
  font-size: 14px;
}

.form-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
}

@media (max-width: 768px) {
  .users-page {
    padding: 16px;
  }

  .page-header {
    flex-direction: column;
    gap: 16px;
    align-items: stretch;
  }

  .users-grid {
    grid-template-columns: 1fr;
  }

  .user-header {
    flex-direction: column;
    text-align: center;
  }

  .detail-row {
    flex-direction: column;
    gap: 4px;
    align-items: flex-start;
  }

  .detail-row .value {
    text-align: left;
    max-width: 100%;
  }
}
</style>
