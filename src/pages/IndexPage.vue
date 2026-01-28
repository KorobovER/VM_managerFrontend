<template>
  <div class="vm-manager">
    <!-- Заголовок и выбор сервера -->
    <div class="page-header">
      <div class="header-content">
        <h1 class="page-title">Управление виртуальными машинами</h1>
        <div class="server-selector">
          <label>Сервер:</label>
          <select v-model="selectedServer" class="server-select" @change="onServerChange">
            <option :value="null" disabled>Выберите сервер</option>
            <option v-for="srv in servers" :key="srv.id" :value="srv.id">
              {{ srv.name }} ({{ srv.host }})
              <span v-if="srv.ping === -1">❌ Недоступен</span>
              <span v-else>🟢 {{ Number(srv.ping).toFixed(3) }}ms</span>
            </option>
          </select>
        </div>
      </div>
    </div>

    <!-- Статистика -->
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-icon servers">📡</div>
        <div class="stat-content">
          <div class="stat-value">{{ servers.length }}</div>
          <div class="stat-label">Серверов</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon vms">💻</div>
        <div class="stat-content">
          <div class="stat-value">{{ vms.length }}</div>
          <div class="stat-label">Всего VM</div>
        </div>
      </div>
      <div class="stat-card active">
        <div class="stat-icon running">▶️</div>
        <div class="stat-content">
          <div class="stat-value">{{ runningVMs.length }}</div>
          <div class="stat-label">Запущено</div>
        </div>
      </div>
    </div>

    <div class="content-grid">
      <!-- Левая колонка: Управление VM -->
      <div class="main-content">
        <!-- Все виртуальные машины -->
        <div class="vm-section">
          <div class="section-header">
            <h2>Виртуальные машины на сервере</h2>
            <button @click="fetchVMs" class="btn-refresh" :disabled="!currentServer || loading.fetchVMs"
              :loading="loading.fetchVMs">
              <span v-if="loading.fetchVMs">⏳ Загрузка...</span>
              <span v-else>🔄 Обновить</span>
            </button>
          </div>

          <div v-if="!currentServer" class="empty-state">
            <div class="empty-icon">🖥️</div>
            <p>Выберите сервер для просмотра виртуальных машин</p>
          </div>

          <div v-else-if="vms.length === 0" class="empty-state">
            <div class="empty-icon">📭</div>
            <p>Нет доступных виртуальных машин</p>
            <button @click="fetchVMs" class="btn-secondary" :disabled="loading.fetchVMs">
              <span v-if="loading.fetchVMs">⏳ Загрузка...</span>
              <span v-else>Загрузить список</span>
            </button>
          </div>

          <div v-else class="vm-grid">
            <div v-for="vm in vms" :key="vm.name" class="vm-card" :class="{
              'vm-running': vm.state === 'running',
              'vm-stopped': vm.state === 'shut off',
              'vm-selected': selectedVM === vm.name
            }" @click="selectedVM = vm.name">
              <div class="vm-card-header">
                <div class="vm-name">{{ vm.name }}</div>
                <div class="vm-state" :class="`state-${vm.state.replace(' ', '-')}`">
                  <span class="state-dot"></span>
                  {{ vm.state }}
                </div>
              </div>
              <div class="vm-card-actions">
                <button v-if="vm.state !== 'running'" @click.stop="runVM(vm.name)" class="btn-action btn-start"
                  :disabled="loading.startVM[vm.name]">
                  <span v-if="loading.startVM[vm.name]">⏳ Запуск...</span>
                  <span v-else>▶️ Запустить</span>
                </button>
                <div v-else class="vm-running-actions">
                  <button @click.stop="startAppOnVM(vm)" class="btn-action btn-start-app"
                    :disabled="loading.startApp[vm.name] || isAppButtonDisabled(vm.name)" title="Запустить приложение">
                    <span v-if="loading.startApp[vm.name]">⏳ Запуск...</span>
                    <span v-else-if="loading.checkReady[vm.name]">🔄 Проверка...</span>
                    <span v-else>📱 Приложение</span>
                  </button>
                  <button @click.stop="launchApp(vm.name)" class="btn-action btn-connect"
                    :disabled="loading.launchApp[vm.name]" title="Подключиться к ВМ">
                    <span v-if="loading.launchApp[vm.name]">⏳ Подключение...</span>
                    <span v-else>🚀 Подключиться</span>
                  </button>
                  <button @click.stop="launchRDP(vm.name)" class="btn-action btn-rdp"
                    :disabled="loading.launchRDP[vm.name]" title="Подключиться по РДП">
                    <span v-if="loading.launchRDP[vm.name]">⏳ РДП...</span>
                    <span v-else>🖥️ РДП</span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Запущенные VM -->
        <div class="vm-section running-section">
          <div class="section-header">
            <h2>Активные виртуальные машины</h2>
            <button @click="fetchRunningVMs" class="btn-refresh" :disabled="!currentServer || loading.fetchRunning">
              <span v-if="loading.fetchRunning">⏳ Загрузка...</span>
              <span v-else>🔄 Обновить</span>
            </button>
          </div>

          <div v-if="!currentServer" class="empty-state">
            <div class="empty-icon">⚡</div>
            <p>Выберите сервер для просмотра активных VM</p>
          </div>

          <div v-else-if="runningVMs.length === 0" class="empty-state">
            <div class="empty-icon">😴</div>
            <p>Нет запущенных виртуальных машин</p>
          </div>

          <div v-else class="running-vm-list">
            <div v-for="vm in runningVMs" :key="vm" class="running-vm-item"
              :class="{ selected: selectedRunningVM === vm }" @click="selectedRunningVM = vm">
              <div class="running-vm-info">
                <div class="running-indicator"></div>
                <div class="running-vm-name">{{ vm }}</div>
              </div>
              <div class="running-vm-actions">
                <button @click.stop="startAppOnVM({ name: vm })" class="btn-action-small btn-start-app"
                  title="Запустить приложение" :disabled="loading.startApp[vm] || isAppButtonDisabled(vm)">
                  <span v-if="loading.startApp[vm]">⏳ Запуск...</span>
                  <span v-else-if="loading.checkReady[vm]">🔄 Проверка...</span>
                  <span v-else>📱 Приложение</span>
                </button>
                <button @click.stop="launchApp(vm)" class="btn-action-small btn-connect" title="Подключиться"
                  :disabled="loading.launchApp[vm]">
                  <span v-if="loading.launchApp[vm]">⏳ Подключение...</span>
                  <span v-else>🚀 Подключиться</span>
                </button>
                <button @click.stop="launchRDP(vm)" class="btn-action-small btn-rdp" title="Подключиться по РДП"
                  :disabled="loading.launchRDP[vm]">
                  <span v-if="loading.launchRDP[vm]">⏳ РДП...</span>
                  <span v-else>🖥️ РДП</span>
                </button>
                <button @click.stop="stopRunningVM(vm)" class="btn-action-small btn-stop" title="Остановить"
                  :disabled="loading.stopVM[vm]">
                  <span v-if="loading.stopVM[vm]">⏳ Остановка...</span>
                  <span v-else>⏹️ Остановить</span>
                </button>
                <button @click.stop="forceStopRunningVM(vm)" class="btn-action-small btn-force-stop"
                  title="Принудительно остановить" :disabled="loading.forceStopVM[vm]">
                  <span v-if="loading.forceStopVM[vm]">⏳ Отключение...</span>
                  <span v-else>⚠️ Жёстко</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Правая колонка: Логи -->
      <div class="sidebar">
        <div class="logs-section">
          <div class="section-header">
            <h2>История действий</h2>
            <button @click="logs = []" class="btn-clear" v-if="logs.length > 0">
              🗑️ Очистить
            </button>
          </div>
          <div class="logs-container">
            <div v-if="logs.length === 0" class="empty-state small">
              <div class="empty-icon">📝</div>
              <p>Нет записей</p>
            </div>
            <div v-else class="log-list">
              <div v-for="(log, idx) in logs" :key="idx" class="log-item" :class="`log-${log.status}`">
                <div class="log-header">
                  <span class="log-time">{{ formatTime(log.time) }}</span>
                  <span class="log-status-badge" :class="`status-${log.status}`">
                    {{ log.status }}
                  </span>
                </div>
                <div class="log-body">
                  <div class="log-action">{{ log.action }}</div>
                  <div class="log-details">{{ log.host }} / {{ log.vm }}</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import axios from "axios";
import { useQuasar } from 'quasar';
import { api } from 'src/boot/axios';

export default {
  setup() {
    const $q = useQuasar();
    return { $q };
  },
  data() {
    return {
      vmJustStarted: false,
      servers: [],
      selectedServer: null,
      vms: [],
      selectedVM: "",
      logs: [],
      runningVMs: [],
      selectedRunningVM: "",
      vmReadyStates: {}, // Состояния готовности ВМ
      loading: {
        fetchVMs: false,
        fetchRunning: false,
        startVM: {},
        stopVM: {},
        forceStopVM: {},
        launchApp: {},
        launchRDP: {},
        startApp: {},
        checkReady: {} // Добавляем загрузку для проверки готовности
      }
    }
  },
  computed: {
    currentServer() {
      return this.servers.find(s => s.id === this.selectedServer);
    },
    isAppButtonDisabled() {
      return (vmName) => {
        // Кнопка неактивна если ВМ не готова
        return !this.vmReadyStates[vmName];
      };
    }
  },
  created() {
    this.fetchServers();
  },
  methods: {
    async fetchServers() {
      try {
        const response = await axios.get('/api/servers');
        this.servers = response.data;
        if (this.servers.length) {
          this.selectedServer = this.servers[0].id;
          this.onServerChange();
        }
      } catch (err) {
        console.error('Ошибка загрузки серверов:', err);
      }
    },

    async onServerChange() {
      this.vms = [];
      this.runningVMs = [];
      this.selectedVM = "";
      this.selectedRunningVM = "";
      if (this.currentServer) {
        await this.fetchVMs();
        await this.fetchRunningVMs();
      }
    },
    formatTime(timeString) {
      const date = new Date(timeString);
      return date.toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' });
    },
    async checkVMReady(vmName) {
      const vmIP = this.getVMIP();
      if (!vmIP) return false;

      this.loading.checkReady[vmName] = true;
      try {
        const response = await api.post('/api/vms/ready', null, {
          params: { vm_ip: vmIP }
        });

        const isReady = response.data.ready;
        this.vmReadyStates[vmName] = isReady;

        return isReady;
      } catch (error) {
        console.error('Ошибка проверки готовности ВМ:', error);
        this.vmReadyStates[vmName] = false;
        return false;
      } finally {
        this.loading.checkReady[vmName] = false;
      }
    },
    getVMIP() {
      // Временный маппинг хоста к IP ВМ
      const hostToVmIP = {
        '172.20.0.198': '172.20.1.196',
        '172.20.0.199': '172.20.1.197'
      };

      return hostToVmIP[this.currentServer.host] || '172.20.1.196';
    },
    async startAppOnVM(vm) {
      const vmName = vm.name;
      console.log('VM object:', vm); // Для отладки - смотрим структуру VM

      // Сначала проверяем готовность ВМ
      const isReady = await this.checkVMReady(vmName);

      if (!isReady) {
        this.$q.notify({
          type: 'warning',
          message: `ВМ "${vmName}" еще не готова к запуску приложений`,
          position: 'top-right',
          icon: 'warning',
          timeout: 3000
        });
        return;
      }

      // Временный маппинг хоста к IP ВМ (пока не найдем как получить IP из VM объекта)
      const hostToVmIP = {
        '172.20.0.198': '172.20.1.196',
        '172.20.0.199': '172.20.1.197'
      };

      const vmIP = hostToVmIP[this.currentServer.host] || '172.20.1.196'; // fallback

      console.log('Using VM IP:', vmIP, 'for host:', this.currentServer.host);

      this.loading.startApp[vmName] = true;
      try {
        const response = await api.post('/api/vms/start-app', null, {
          params: {
            vm_ip: vmIP,
            app_path: 'C:\\CloudServer\\CrystalCloudServer.exe'
          }
        });

        // Добавляем задержку для обработки ответа
        await new Promise(resolve => setTimeout(resolve, 2000));

        if (response.data.app_started) {
          this.$q.notify({
            type: 'positive',
            message: `Приложение успешно запущено на ВМ "${vmName}"`,
            position: 'top-right',
            icon: 'check_circle',
            timeout: 2500
          });
          this.addLog('start_app', vmName, 'success');
        } else {
          this.$q.notify({
            type: 'warning',
            message: `Не удалось запустить приложение на ВМ "${vmName}"`,
            position: 'top-right',
            icon: 'warning',
            timeout: 3000
          });
          this.addLog('start_app', vmName, 'error');
        }
      } catch (error) {
        console.error('Ошибка запуска приложения:', error);
        const errorMsg = error.response?.data?.detail || error.response?.data?.message || 'Ошибка при запуске приложения';
        this.$q.notify({
          type: 'negative',
          message: errorMsg,
          position: 'top-right',
          timeout: 3000
        });
        this.addLog('start_app', vmName, 'error');
      } finally {
        this.loading.startApp[vmName] = false;
      }
    },
    async launchApp(vmName = null) {
      const vm = vmName || this.selectedRunningVM;
      this.loading.launchApp[vm] = true;
      try {
        const res = await axios.post('/proxy/start?vm_ip=172.20.1.196&video_port=55554');

        if (res.data.status === 'proxy_started' || res.data.status === 'proxy_worked') {
          const proxyPort = res.data.proxy_port;
          const connectionAddress = res.data.connection_address;

          if (proxyPort && connectionAddress) {
            window.location.href = `crystalcloudeapp://?-i=${connectionAddress}&-p=${proxyPort}`;
            this.addLog('launch_app', vmName || this.selectedRunningVM, 'success');
          } else {
            this.addLog('launch_app', vmName || this.selectedRunningVM, 'error');
            this.$q.notify({
              type: 'negative',
              message: 'Ошибка: хост или порт не получены',
              position: 'top-right',
              timeout: 3000
            });
          }
        } else {
          this.addLog('launch_app', vmName || this.selectedRunningVM, 'error');
          this.$q.notify({
            type: 'negative',
            message: 'Ошибка при инициализации прокси',
            position: 'top-right',
            timeout: 3000
          });
        }
      } catch (error) {
        console.error('Ошибка при запуске приложения:', error);
        this.addLog('launch_app', vmName || this.selectedRunningVM, 'error');
        this.$q.notify({
          type: 'negative',
          message: 'Ошибка при запуске приложения: ' + error.message,
          position: 'top-right',
          timeout: 4000
        });
      } finally {
        this.loading.launchApp[vm] = false;
      }
    },
    async launchRDP(vmName = null) {
      const vm = vmName || this.selectedRunningVM;
      this.loading.launchRDP[vm] = true;
      try {
        const gamePath = 'C:\\Users\\ggg\\Desktop\\G-SYNC Pendulum Demo.lnk';
        const res = await axios.post(`/proxy/rdp/start?vm_ip=172.20.1.196&game_path=${encodeURIComponent(gamePath)}`);

        if (res.data.status === 'tunnel_started') {
          const rdpCommand = res.data.rdp_command;
          const tunnelHost = res.data.tunnel_host;
          const tunnelPort = res.data.tunnel_port;

          if (rdpCommand && tunnelHost && tunnelPort) {
            this.$q.notify({
              type: 'positive',
              message: `РДП туннель запущен: ${tunnelHost}:${tunnelPort}`,
              position: 'top-right',
              icon: 'check_circle',
              timeout: 3000
            });

            this.$q.dialog({
              title: '🖥️ Подключение по РДП',
              message: `Туннель готов к подключению<br><strong>Адрес:</strong> ${tunnelHost}:${tunnelPort}<br><br>Учетные данные:<br><strong>Пользователь:</strong> ggg<br><strong>Пароль:</strong> 123<br><br>Игра будет запущена автоматически при подключении.`,
              html: true,
              ok: {
                label: '� Подключиться',
                color: 'primary'
              },
              cancel: {
                label: 'Закрыть',
                color: 'grey'
              }
            }).onOk(() => {
              this.executeRDPCommand(rdpCommand);
            });

            this.addLog('launch_rdp', vmName || this.selectedRunningVM, 'success');
          } else {
            this.addLog('launch_rdp', vmName || this.selectedRunningVM, 'error');
            this.$q.notify({
              type: 'negative',
              message: 'Ошибка: команда подключения не получена',
              position: 'top-right',
              timeout: 3000
            });
          }
        } else {
          this.addLog('launch_rdp', vmName || this.selectedRunningVM, 'error');
          this.$q.notify({
            type: 'negative',
            message: 'Ошибка при инициализации РДП туннеля',
            position: 'top-right',
            timeout: 3000
          });
        }
      } catch (error) {
        console.error('Ошибка при запуске РДП:', error);
        this.addLog('launch_rdp', vmName || this.selectedRunningVM, 'error');
        this.$q.notify({
          type: 'negative',
          message: 'Ошибка при запуске РДП: ' + error.message,
          position: 'top-right',
          timeout: 4000
        });
      } finally {
        this.loading.launchRDP[vm] = false;
      }
    },
    executeRDPCommand(rdpCommand) {
      console.log('executeRDPCommand вызвана с командой:', rdpCommand);
      const match = rdpCommand.match(/mstsc \/v:([^:]+):(\d+)/);
      if (match) {
        const host = match[1];
        const port = match[2];
        window.location.href = `rdp://${host}:${port}`;
        console.log(`Запуск RDP: rdp://${host}:${port}`);
        this.$q.notify({
          type: 'positive',
          message: 'RDP подключение инициировано',
          position: 'top-right',
          timeout: 2000
        });
      } else {
        console.error('Не удалось распарсить RDP команду:', rdpCommand);
        this.$q.notify({
          type: 'negative',
          message: 'Ошибка при парсинге RDP команды',
          position: 'top-right',
          timeout: 3000
        });
      }
    },
    async forceStopRunningVM(vmName = null) {
      const vm = vmName || this.selectedRunningVM;
      if (!this.currentServer || !vm) {
        this.$q.notify({
          type: 'warning',
          message: 'Выберите сервер и виртуалку для жёсткого отключения',
          position: 'top-right',
          timeout: 2500
        });
        return;
      }

      this.loading.forceStopVM[vm] = true;

      this.$q.dialog({
        title: 'Подтверждение',
        message: `Вы действительно хотите ЖЁСТКО отключить виртуалку "${vm}"?`,
        cancel: {
          label: 'Отмена',
          color: 'grey',
          flat: true
        },
        ok: {
          label: 'Отключить',
          color: 'negative',
          flat: true
        },
        persistent: true
      }).onOk(async () => {
        try {
          let res = await axios.post('/api/vms/force_stop', {
            vm_host: this.currentServer.host,
            vm_name: vm,
            host: this.currentServer.host,
            port: this.currentServer.port
          });
          this.addLog('force_stop', vm, res.data.status || 'success');
          this.$q.notify({
            type: 'positive',
            message: `ВМ ${vm} жёстко отключена`,
            position: 'top-right',
            icon: 'check_circle',
            timeout: 2500
          });
          await this.fetchRunningVMs();
          await this.fetchVMs();
        } catch (error) {
          console.error('Ошибка force_stop:', error.response?.data);
          this.addLog('force_stop', vm, 'error');
          const errorMsg = error.response?.data?.detail || 'Ошибка жёсткого выключения ВМ';
          this.$q.notify({
            type: 'negative',
            message: errorMsg,
            position: 'top-right',
            timeout: 3000
          });
        } finally {
          this.loading.forceStopVM[vm] = false;
        }
      }).onCancel(() => {
        this.loading.forceStopVM[vm] = false;
      });
    },
    async stopRunningVM(vmName = null) {
      const vm = vmName || this.selectedRunningVM;
      if (!this.currentServer || !vm) {
        this.$q.notify({
          type: 'warning',
          message: 'Выберите сервер и виртуалку для выключения',
          position: 'top-right',
          timeout: 2500
        });
        return;
      }

      this.loading.stopVM[vm] = true;

      this.$q.dialog({
        title: 'Подтверждение',
        message: `Вы действительно хотите выключить виртуалку "${vm}"?`,
        cancel: {
          label: 'Отмена',
          color: 'grey',
          flat: true
        },
        ok: {
          label: 'Выключить',
          color: 'orange',
          flat: true
        },
        persistent: true
      }).onOk(async () => {
        try {
          let res = await axios.post('/api/vms/stop', {
            vm_host: this.currentServer.host,
            vm_name: vm,
            host: this.currentServer.host,
            port: this.currentServer.port
          });
          this.addLog('stop', vm, res.data.status || 'success');
          this.$q.notify({
            type: 'positive',
            message: `ВМ ${vm} выключена`,
            position: 'top-right',
            icon: 'check_circle',
            timeout: 2500
          });

          // Очищаем состояние готовности при остановке ВМ
          delete this.vmReadyStates[vm];

          await this.fetchRunningVMs();
          await this.fetchVMs();
        } catch (error) {
          console.error('Ошибка stop:', error.response?.data);
          this.addLog('stop', vm, 'error');
          const errorMsg = error.response?.data?.detail || 'Ошибка выключения ВМ';
          this.$q.notify({
            type: 'negative',
            message: errorMsg,
            position: 'top-right',
            timeout: 3000
          });
        } finally {
          this.loading.stopVM[vm] = false;
        }
      }).onCancel(() => {
        this.loading.stopVM[vm] = false;
      });
    },
    async fetchRunningVMs() {
      if (!this.currentServer) return;
      this.loading.fetchRunning = true;
      try {
        let res = await axios.get(`/api/vms/running?host=${this.currentServer.host}&port=${this.currentServer.port}`);
        this.runningVMs = res.data.running_vms || [];
        if (this.runningVMs && this.runningVMs.length) this.selectedRunningVM = this.runningVMs[0];

        // Проверяем готовность для всех запущенных ВМ
        for (const vmName of this.runningVMs) {
          await this.checkVMReady(vmName);
        }
      } catch (error) {
        console.error('Ошибка загрузки запущенных VM:', error);
        this.runningVMs = [];
        this.selectedRunningVM = "";
      } finally {
        this.loading.fetchRunning = false;
      }
    },
    async fetchVMs() {
      if (!this.currentServer) return;
      this.loading.fetchVMs = true;
      try {
        let res = await axios.get(`/api/vms/available?host=${this.currentServer.host}&port=${this.currentServer.port}`);
        this.vms = res.data.vms || [];
        if (this.vms && this.vms.length) this.selectedVM = this.vms[0].name;

        // Проверяем готовность для запущенных ВМ в основной сетке
        for (const vm of this.vms) {
          if (vm.state === 'running') {
            await this.checkVMReady(vm.name);
          }
        }
      } catch (error) {
        console.error('Ошибка загрузки VM:', error);
        this.vms = [];
        this.selectedVM = "";
        this.$q.notify({
          type: 'negative',
          message: 'Ошибка при загрузке списка виртуальных машин',
          position: 'top-right',
          timeout: 3000
        });
      } finally {
        this.loading.fetchVMs = false;
      }
    },
    async runVM(vmName = null) {
      const vm = vmName || this.selectedVM;
      if (!this.currentServer || !vm) {
        this.$q.notify({
          type: 'warning',
          message: 'Выберите виртуальную машину',
          position: 'top-right',
          timeout: 2500
        });
        return;
      }
      this.loading.startVM[vm] = true;
      try {
        let res = await axios.post('/api/vms/start', {
          vm_host: this.currentServer.host,
          vm_name: vm,
          host: this.currentServer.host,
          port: this.currentServer.port
        });
        this.addLog('start', vm, res.data.status || 'success');
        this.$q.notify({
          type: 'positive',
          message: `ВМ ${vm} запущена`,
          position: 'top-right',
          icon: 'check_circle',
          timeout: 2500
        });

        // Сбрасываем состояние готовности ВМ при запуске
        this.vmReadyStates[vm] = false;

        await this.fetchVMs();
        await this.fetchRunningVMs();
      } catch (error) {
        console.error('Ошибка start:', error.response?.data);
        this.addLog('start', vm, 'error');
        const errorMsg = error.response?.data?.detail || 'Ошибка запуска ВМ';
        this.$q.notify({
          type: 'negative',
          message: errorMsg,
          position: 'top-right',
          timeout: 3000
        });
      } finally {
        this.loading.startVM[vm] = false;
      }
    },
    addLog(action, vm, status) {
      this.logs.unshift({
        time: new Date().toISOString(),
        action,
        vm,
        host: this.currentServer?.name || 'unknown',
        status
      });
      if (this.logs.length > 50) this.logs.pop();
    }
  }
}
</script>

<style scoped>
.vm-manager {
  padding: 24px;
  max-width: 1600px;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 32px;
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 20px;
}

.page-title {
  font-size: 32px;
  font-weight: 700;
  color: #1a202c;
  margin: 0;
}

.server-selector {
  display: flex;
  align-items: center;
  gap: 12px;
}

.server-selector label {
  font-size: 15px;
  font-weight: 600;
  color: #4a5568;
}

.server-select {
  padding: 10px 16px;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  font-size: 15px;
  min-width: 300px;
  background: white;
  cursor: pointer;
  transition: all 0.2s;
}

.server-select:hover {
  border-color: #cbd5e0;
}

.server-select:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

/* Статистика */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
  margin-bottom: 32px;
}

.stat-card {
  background: white;
  border-radius: 12px;
  padding: 24px;
  display: flex;
  align-items: center;
  gap: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  transition: transform 0.2s, box-shadow 0.2s;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.12);
}

.stat-card.active {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.stat-card.active .stat-value,
.stat-card.active .stat-label {
  color: white;
}

.stat-icon {
  font-size: 36px;
  width: 60px;
  height: 60px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 12px;
  background: #f7fafc;
}

.stat-card.active .stat-icon {
  background: rgba(255, 255, 255, 0.2);
}

.stat-content {
  flex: 1;
}

.stat-value {
  font-size: 32px;
  font-weight: 700;
  color: #1a202c;
  line-height: 1;
  margin-bottom: 4px;
}

.stat-label {
  font-size: 14px;
  color: #718096;
  font-weight: 500;
}

/* Сетка контента */
.content-grid {
  display: grid;
  grid-template-columns: 1fr 350px;
  gap: 24px;
}

@media (max-width: 1200px) {
  .content-grid {
    grid-template-columns: 1fr;
  }
}

.main-content {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

/* Секции */
.vm-section {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.running-section {
  background: linear-gradient(135deg, #f7fafc 0%, #edf2f7 100%);
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.section-header h2 {
  font-size: 20px;
  font-weight: 600;
  color: #2d3748;
  margin: 0;
}

/* Кнопки */
.btn-refresh,
.btn-clear {
  padding: 8px 16px;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  background: #edf2f7;
  color: #4a5568;
}

.btn-refresh:hover:not(:disabled),
.btn-clear:hover {
  background: #e2e8f0;
  transform: translateY(-1px);
}

.btn-refresh:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}

.btn-secondary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}

.btn-secondary {
  padding: 10px 20px;
  background: #667eea;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-secondary:hover {
  background: #5568d3;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
}

/* Пустое состояние */
.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: #718096;
}

.empty-state.small {
  padding: 40px 20px;
}

.empty-icon {
  font-size: 48px;
  margin-bottom: 16px;
}

.empty-state p {
  font-size: 16px;
  margin: 0 0 20px 0;
}

/* Сетка VM */
.vm-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 16px;
}

.vm-card {
  background: white;
  border: 2px solid #e2e8f0;
  border-radius: 12px;
  padding: 16px;
  cursor: pointer;
  transition: all 0.2s;
}

.vm-card:hover {
  border-color: #cbd5e0;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.vm-card.vm-selected {
  border-color: #667eea;
  background: #f7fafc;
}

.vm-card.vm-running {
  border-left: 4px solid #48bb78;
}

.vm-card.vm-stopped {
  border-left: 4px solid #cbd5e0;
}

.vm-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.vm-name {
  font-size: 16px;
  font-weight: 600;
  color: #2d3748;
}

.vm-state {
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

.state-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #cbd5e0;
}

.vm-state.state-running .state-dot {
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

.vm-card-actions {
  display: flex;
  gap: 8px;
}

.vm-running-actions {
  display: flex;
  gap: 8px;
  width: 100%;
}

.vm-running-actions .btn-action {
  flex: 1;
}

.btn-action {
  flex: 1;
  padding: 10px 16px;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-start {
  background: #48bb78;
  color: white;
}

.btn-start-app {
  background: #38a169;
  color: white;
}

.btn-start:hover:not(:disabled) {
  background: #38a169;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(72, 187, 120, 0.3);
}

.btn-start:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-connect {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.btn-connect:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
}

.btn-connect:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-rdp {
  background: #4299e1;
  color: white;
}

.btn-rdp:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(66, 153, 225, 0.3);
}

.btn-rdp:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* Запущенные VM */
.running-vm-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.running-vm-item {
  background: white;
  border: 2px solid #e2e8f0;
  border-radius: 10px;
  padding: 16px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  cursor: pointer;
  transition: all 0.2s;
}

.running-vm-item:hover {
  border-color: #cbd5e0;
  transform: translateX(4px);
}

.running-vm-item.selected {
  border-color: #667eea;
  background: #f7fafc;
}

.running-vm-info {
  display: flex;
  align-items: center;
  gap: 12px;
}

.running-indicator {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background: #48bb78;
  animation: pulse 2s infinite;
}

.running-vm-name {
  font-size: 15px;
  font-weight: 600;
  color: #2d3748;
}

.running-vm-actions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.btn-action-small {
  padding: 8px 14px;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  white-space: nowrap;
  color: white;
}

.btn-action-small.btn-start-app {
  background: #48bb78;
}

.btn-action-small.btn-connect {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.btn-action-small.btn-rdp {
  background: #4299e1;
}

.btn-action-small.btn-stop {
  background: #f6ad55;
}

.btn-action-small.btn-force-stop {
  background: #fc8181;
}

.btn-action-small:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
}

.btn-action-small:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* Логи */
.sidebar {
  display: flex;
  flex-direction: column;
}

.logs-section {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  height: fit-content;
  max-height: calc(100vh - 200px);
  display: flex;
  flex-direction: column;
}

.logs-container {
  flex: 1;
  overflow-y: auto;
  margin-top: 16px;
}

.log-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.log-item {
  background: #f7fafc;
  border-left: 4px solid #cbd5e0;
  border-radius: 8px;
  padding: 12px;
  transition: all 0.2s;
}

.log-item:hover {
  background: #edf2f7;
}

.log-item.log-success {
  border-left-color: #48bb78;
}

.log-item.log-error {
  border-left-color: #fc8181;
}

.log-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.log-time {
  font-size: 12px;
  color: #718096;
  font-weight: 500;
}

.log-status-badge {
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  padding: 2px 8px;
  border-radius: 4px;
}

.log-status-badge.status-success {
  background: #c6f6d5;
  color: #22543d;
}

.log-status-badge.status-error {
  background: #fed7d7;
  color: #c53030;
}

.log-body {
  font-size: 13px;
}

.log-action {
  font-weight: 600;
  color: #2d3748;
  margin-bottom: 4px;
}

.log-details {
  color: #718096;
  font-size: 12px;
}
</style>
