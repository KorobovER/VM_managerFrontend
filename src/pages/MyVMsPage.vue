<template>
  <div class="my-vms-page">
    <div class="page-header">
      <h1>Мои виртуальные машины</h1>
      <button @click="fetchVMs" class="hiveon-btn primary" :disabled="loading">
        🔄 Обновить
      </button>
    </div>

    <div v-if="loading" class="loading-container">
      <div class="loading-spinner"></div>
      <p>Загрузка виртуальных машин...</p>
    </div>

    <div v-else-if="vms.length === 0" class="empty-state">
      <div class="empty-icon">💻</div>
      <h3>Нет виртуальных машин</h3>
      <p>У вас нет назначенных виртуальных машин</p>
    </div>

    <div v-else class="vms-grid">
      <div v-for="vm in vms" :key="vm.name" class="vm-card" :class="{
        'vm-running': vm.state === 'running',
        'vm-stopped': vm.state === 'shut off'
      }">
        <div class="vm-header">
          <h3>{{ vm.name }}</h3>
          <span class="vm-status">{{ vm.state === 'running' ? '🟢' : '⏹️' }}</span>
        </div>

        <div class="vm-details">
          <div class="detail-row">
            <span class="label">Сервер:</span>
            <span class="value">{{ vm.server_host }}:{{ vm.server_port }}</span>
          </div>
          <div class="detail-row">
            <span class="label">Статус:</span>
            <span class="status-badge" :class="vm.state">
              <span class="status-dot"></span>
              {{ vm.state === 'running' ? 'Запущена' : 'Остановлена' }}
            </span>
          </div>
          <div v-if="vm.assigned_at" class="detail-row">
            <span class="label">Назначена:</span>
            <span class="value">{{ formatDate(vm.assigned_at) }}</span>
          </div>
        </div>

        <div class="vm-actions">
          <button v-if="vm.state !== 'running'" @click="startVM(vm)" class="hiveon-btn success"
            :disabled="actionLoading[vm.name]" title="Запустить ВМ">
            {{ actionLoading[vm.name] ? '🔄 Запуск...' : '▶️ Запустить' }}
          </button>
          <button v-else @click="connectVM(vm)" class="hiveon-btn info" :disabled="actionLoading[vm.name]"
            title="Подключиться к ВМ">
            {{ actionLoading[vm.name] ? '🔄 Подключение...' : '🚀 Подключиться' }}
          </button>
        </div>
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
  name: 'MyVMsPage',
  setup() {
    const $q = useQuasar()
    const vms = ref([])
    const loading = ref(false)
    const actionLoading = ref({})
    const errorDialog = ref(false)
    const errorMessage = ref('')

    const fetchVMs = async () => {
      loading.value = true
      try {
        // Сначала получаем информацию о текущем пользователе
        const userResponse = await api.get('/api/auth/me')
        console.log('User response:', userResponse.data)

        if (!userResponse.data?.id) {
          throw new Error('Не удалось получить ID пользователя')
        }

        // Затем получаем ВМ пользователя с правильным ID
        const response = await api.get(`/api/users/${userResponse.data.id}/vms`)
        console.log('My VMs response:', response)
        console.log('My VMs data:', response.data)

        // Ответ содержит { user: "...", vms: [...] }
        vms.value = response.data?.vms || []
      } catch (error) {
        console.error('Ошибка при загрузке ВМ:', error)
        console.error('Error response:', error.response?.data)
        console.error('Error detail array:', error.response?.data?.detail)
        console.error('Error status:', error.response?.status)
        console.error('Error headers:', error.response?.headers)

        // Если detail это массив, выводим его элементы
        if (Array.isArray(error.response?.data?.detail)) {
          console.error('Detail items:')
          error.response.data.detail.forEach((item, index) => {
            console.error(`  [${index}]:`, item)
          })
        }

        vms.value = []
        const detailMessage = Array.isArray(error.response?.data?.detail)
          ? error.response.data.detail.join(', ')
          : error.response?.data?.detail || error.response?.data?.message

        errorMessage.value = `Ошибка ${error.response?.status}: ${detailMessage || 'Ошибка при загрузке виртуальных машин'}`
        errorDialog.value = true
      } finally {
        loading.value = false
      }
    }

    const closeErrorDialog = () => {
      errorDialog.value = false
      errorMessage.value = ''
    }

    const startVM = async (vm) => {
      actionLoading.value[vm.name] = true
      try {
        await api.post('/api/vms/start', {
          vm_host: vm.server_host,
          vm_name: vm.name,
          host: vm.server_host,
          port: vm.server_port
        })

        $q.notify({
          type: 'positive',
          message: `ВМ "${vm.name}" запущена`,
          position: 'top-right',
          icon: 'check_circle',
          timeout: 2500
        })

        // Обновляем статус ВМ
        await fetchVMs()
      } catch (error) {
        console.error('Ошибка запуска ВМ:', error)
        const errorMsg = error.response?.data?.detail || 'Ошибка при запуске ВМ'
        $q.notify({
          type: 'negative',
          message: errorMsg,
          position: 'top-right',
          timeout: 3000
        })
      } finally {
        actionLoading.value[vm.name] = false
      }
    }

    const connectVM = async (vm) => {
      actionLoading.value[vm.name] = true
      try {
        const response = await api.post('/proxy/start?vm_ip=172.20.1.196&video_port=55554')

        if (response.data.status === 'proxy_started' || response.data.status === 'proxy_worked') {
          const proxyPort = response.data.proxy_port
          const connectionAddress = response.data.connection_address

          if (proxyPort && connectionAddress) {
            window.location.href = `crystalcloudeapp://?-i=${connectionAddress}&-p=${proxyPort}`
          } else {
            throw new Error('Хост или порт не получены')
          }
        } else {
          throw new Error('Ошибка при инициализации прокси')
        }
      } catch (error) {
        console.error('Ошибка подключения к ВМ:', error)
        const errorMsg = error.message || 'Ошибка при подключении к ВМ'
        $q.notify({
          type: 'negative',
          message: errorMsg,
          position: 'top-right',
          timeout: 4000
        })
      } finally {
        actionLoading.value[vm.name] = false
      }
    }

    const formatDate = (dateString) => {
      return new Date(dateString).toLocaleString('ru-RU')
    }

    onMounted(() => {
      fetchVMs()
    })

    return {
      $q,
      vms,
      loading,
      actionLoading,
      errorDialog,
      errorMessage,
      fetchVMs,
      closeErrorDialog,
      startVM,
      connectVM,
      formatDate
    }
  }
}
</script>

<style scoped>
.my-vms-page {
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

.vms-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
  gap: 24px;
}

.vm-card {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  transition: transform 0.2s, box-shadow 0.2s;
  border-left: 4px solid #e2e8f0;
}

.vm-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.15);
}

.vm-card.vm-running {
  border-left-color: #48bb78;
}

.vm-card.vm-stopped {
  border-left-color: #cbd5e0;
}

.vm-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  padding-bottom: 16px;
  border-bottom: 2px solid #e2e8f0;
}

.vm-header h3 {
  font-size: 20px;
  font-weight: 600;
  color: #2d3748;
  margin: 0;
}

.vm-status {
  font-size: 20px;
}

.vm-details {
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

.status-badge {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  font-weight: 600;
  padding: 4px 10px;
  border-radius: 12px;
  background: #edf2f7;
  color: #718096;
}

.status-badge.running {
  background: rgba(72, 187, 120, 0.2);
  color: #48bb78;
}

.status-badge.shut-off {
  background: rgba(203, 213, 224, 0.5);
  color: #718096;
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #cbd5e0;
}

.status-badge.running .status-dot {
  background: #48bb78;
  animation: pulse 2s infinite;
}

@keyframes pulse {

  0%,
  100% {
    opacity: 1;
  }

  50% {
    opacity: 0.5;
  }
}

.vm-actions {
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

.hiveon-btn:hover:not(:disabled) {
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

.modal-header h3 {
  font-size: 20px;
  font-weight: 700;
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

@media (max-width: 768px) {
  .my-vms-page {
    padding: 16px;
  }

  .page-header {
    flex-direction: column;
    gap: 16px;
    align-items: stretch;
  }

  .vms-grid {
    grid-template-columns: 1fr;
  }

  .vm-header {
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
