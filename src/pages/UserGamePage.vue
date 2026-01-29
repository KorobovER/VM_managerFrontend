<template>
  <div class="user-game-page">
    <div class="game-container">
      <div class="game-card">
        <div class="game-header">
          <h1 class="game-title">G-SYNC Pendulum Demo</h1>
          <div class="game-icon">🎮</div>
        </div>

        <div class="game-description">
          <p>Нажмите кнопку ниже, чтобы запустить игру</p>
        </div>

        <button @click="launchGame" class="launch-button" :disabled="loading">
          <span v-if="loading" class="button-text">
            ⏳ Запуск игры...
          </span>
          <span v-else class="button-text">
            🚀 Включить Игру
          </span>
        </button>

        <div v-if="statusMessage" class="status-message" :class="statusClass">
          {{ statusMessage }}
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref } from 'vue'
import { useQuasar } from 'quasar'
import { api } from 'src/boot/axios'

export default {
  name: 'UserGamePage',
  setup() {
    const $q = useQuasar()
    const loading = ref(false)
    const statusMessage = ref('')
    const statusClass = ref('')

    const launchGame = async () => {
      loading.value = true
      statusMessage.value = ''

      try {
        // Запускаем RDP туннель
        const gamePath = 'C:\\Users\\ggg\\Desktop\\G-SYNC Pendulum Demo.lnk'
        const res = await api.post(`/proxy/rdp/start?vm_ip=172.20.1.196&game_path=${encodeURIComponent(gamePath)}`)

        if (res.data.status === 'tunnel_started') {
          const rdpCommand = res.data.rdp_command
          const tunnelHost = res.data.tunnel_host
          const tunnelPort = res.data.tunnel_port

          if (rdpCommand && tunnelHost && tunnelPort) {
            statusMessage.value = `Туннель готов: ${tunnelHost}:${tunnelPort}`
            statusClass.value = 'success'

            // Показываем диалог с информацией о подключении
            $q.dialog({
              title: '🎮 Запуск игры',
              message: `Туннель готов к подключению<br><br><strong>Команда для выполнения в PowerShell:</strong><br><code>${rdpCommand}</code><br><br><strong>Адрес:</strong> ${tunnelHost}:${tunnelPort}<br><strong>Пользователь:</strong> ggg<br><strong>Пароль:</strong> 123<br><br>Игра будет запущена автоматически при подключении.`,
              html: true,
              ok: {
                label: '🚀 Открыть PowerShell',
                color: 'primary'
              },
              cancel: {
                label: 'Закрыть',
                color: 'grey'
              }
            }).onOk(() => {
              // Открываем PowerShell
              window.location.href = 'powershell://'
            })
          } else {
            throw new Error('Не получены параметры подключения')
          }
        } else {
          throw new Error('Ошибка при инициализации туннеля')
        }
      } catch (error) {
        console.error('Ошибка при запуске игры:', error)
        statusMessage.value = `Ошибка: ${error.message || 'Не удалось запустить игру'}`
        statusClass.value = 'error'

        $q.notify({
          type: 'negative',
          message: statusMessage.value,
          position: 'top-right',
          timeout: 4000
        })
      } finally {
        loading.value = false
      }
    }

    return {
      loading,
      statusMessage,
      statusClass,
      launchGame
    }
  }
}
</script>

<style scoped>
.user-game-page {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 20px;
}

.game-container {
  width: 100%;
  max-width: 600px;
}

.game-card {
  background: white;
  border-radius: 20px;
  padding: 60px 40px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  text-align: center;
}

.game-header {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 20px;
  margin-bottom: 40px;
}

.game-icon {
  font-size: 80px;
  animation: bounce 2s infinite;
}

@keyframes bounce {
  0%, 100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-20px);
  }
}

.game-title {
  font-size: 36px;
  font-weight: 700;
  color: #1a202c;
  margin: 0;
  line-height: 1.2;
}

.game-description {
  margin-bottom: 40px;
}

.game-description p {
  font-size: 18px;
  color: #718096;
  margin: 0;
  line-height: 1.6;
}

.launch-button {
  width: 100%;
  padding: 20px 40px;
  font-size: 18px;
  font-weight: 700;
  color: white;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border: none;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.3s;
  box-shadow: 0 10px 30px rgba(102, 126, 234, 0.3);
  margin-bottom: 20px;
}

.launch-button:hover:not(:disabled) {
  transform: translateY(-4px);
  box-shadow: 0 15px 40px rgba(102, 126, 234, 0.4);
}

.launch-button:active:not(:disabled) {
  transform: translateY(-2px);
}

.launch-button:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}

.button-text {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
}

.status-message {
  padding: 16px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  margin-top: 20px;
}

.status-message.success {
  background: #d1fae5;
  color: #065f46;
  border-left: 4px solid #10b981;
}

.status-message.error {
  background: #fee2e2;
  color: #991b1b;
  border-left: 4px solid #ef4444;
}

@media (max-width: 768px) {
  .game-card {
    padding: 40px 24px;
  }

  .game-icon {
    font-size: 60px;
  }

  .game-title {
    font-size: 28px;
  }

  .game-description p {
    font-size: 16px;
  }

  .launch-button {
    padding: 16px 24px;
    font-size: 16px;
  }
}
</style>
