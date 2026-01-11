<template>
  <div class="hiveon-dashboard-wrap">
    <div class="hiveon-dashboard">
      <!-- Серверы -->
      <div class="hiveon-card">
        <div class="hiveon-card-title">Серверы</div>
        <div class="hiveon-row">
          <div class="hiveon-select-wrap">
            <select v-model="selectedServer" class="hiveon-select">
              <option v-for="srv in servers" :key="srv" :value="srv">{{ srv }}</option>
            </select>
          </div>
          <button @click="fetchVMs" class="hiveon-btn">Запросить список ВМ</button>
        </div>
      </div>
      <!-- Запущенные виртуалки -->
      <div class="hiveon-card">
        <div class="hiveon-card-title">Запущенные виртуалки</div>
        <div class="hiveon-row">
          <div class="hiveon-select-wrap">
            <select v-model="selectedRunningVM" class="hiveon-select">
              <option v-for="vm in runningVMs" :key="vm" :value="vm">{{ vm }}</option>
            </select>
          </div>
          <button @click="fetchRunningVMs" class="hiveon-btn">Показать запущенные ВМ</button>
          <button @click="launchApp" class="hiveon-btn success">Запустить приложение</button>
          <button @click="stopRunningVM" class="hiveon-btn accent">Грохнуть виртуалку</button>
          <button @click="forceStopRunningVM" class="hiveon-btn danger">Жёстко отключить</button>
        </div>
      </div>
      <!-- Все ВМ -->
      <div class="hiveon-card">
        <div class="hiveon-card-title">Виртуалки на выбранном сервере</div>
        <div class="hiveon-row">
          <div class="hiveon-select-wrap">
            <select v-model="selectedVM" class="hiveon-select">
              <option v-for="vm in vms" :key="vm.name" :value="vm.name">{{ vm.name }} ({{ vm.state }})</option>
            </select>
          </div>
          <button @click="runVM" class="hiveon-btn">Запустить выбранную ВМ</button>
          <button v-if="vmJustStarted" class="hiveon-btn accent" disabled>ВМ запускается...</button>
        </div>
      </div>
      <!-- Статусы -->
      <div class="hiveon-card" style="padding: 18px 38px;">
        <div class="hiveon-row" style="justify-content: space-between;">
          <div style="min-width: 130px;">
            <div class="hiveon-card-title" style="font-size: 1rem; color: var(--hiveon-text-secondary)">Серверов</div>
            <div class="hiveon-status-value">{{ servers.length }}</div>
          </div>
          <div style="min-width: 130px;">
            <div class="hiveon-card-title" style="font-size: 1rem; color: var(--hiveon-text-secondary)">Виртуалок на
              сервере</div>
            <div class="hiveon-status-value">{{ vms.length }}</div>
          </div>
          <div style="min-width: 130px;">
            <div class="hiveon-card-title" style="font-size: 1rem; color: var(--hiveon-text-secondary)">Запущено ВМ
            </div>
            <div class="hiveon-status-value green">{{ runningVMs.length }}</div>
          </div>
        </div>
      </div>
    </div>
    <!-- Лог действий теперь справа -->
    <aside class="hiveon-dashboard-log">
      <div class="hiveon-card">
        <div class="hiveon-card-title" style="margin-bottom:14px;">Лог действий с виртуалками</div>
        <ul class="hiveon-logs-list">
          <li v-for="(log, idx) in logs" :key="idx" class="hiveon-log-item">
            <span class="log-time">[{{ log.time }}]</span>
            <span class="log-host">[{{ log.host }}/{{ log.vm }}]</span>
            <b class="log-action">{{ log.action }}</b>:
            <span :class="['log-status', log.status]">{{ log.status }}</span>
          </li>
          <li v-if="logs.length === 0" class="log-empty">Нет записей за эту сессию.</li>
        </ul>
      </div>
    </aside>
  </div>
</template>

<script>
import axios from "axios";
export default {
  data() {
    return {
      vmJustStarted: false,
      servers: [],
      selectedServer: "",
      vms: [],
      selectedVM: "",
      logs: [],
      runningVMs: [],
      selectedRunningVM: ""
    }
  },
  created() {
    axios.get('/api/vms/list').then(res => {
      this.servers = res.data.vms || [];
      if (this.servers.length) this.selectedServer = this.servers[0];
    }).catch(() => { });
  },
  methods: {
    async launchApp() {
      try {
        const res = await axios.post('/proxy/start?vm_ip=172.20.1.196&video_port=55554');

        if (res.data.status === 'proxy_started' || res.data.status === 'proxy_worked') {
          const proxyPort = res.data.proxy_port;
          const connectionAddress = res.data.connection_address;

          window.location.href = `crystalcloudeapp://launch?host=${connectionAddress}&port=${proxyPort}`;
          alert(`Прокси запущен на ${connectionAddress}:${proxyPort}`);
        } else {
          alert('Ошибка при инициализации прокси');
        }
      } catch (error) {
        alert('Ошибка при запуске приложения: ' + error.message);
      }
    },
    openLauncher() {
      window.location.href = `gcloud://${this.selectedVM}`;
      this.vmJustStarted = false;
    },
    async forceStopRunningVM() {
      if (!this.selectedServer || !this.selectedRunningVM) {
        alert("Выберите сервер и виртуалку для жёсткого отключения!");
        return;
      }
      if (!confirm(`Вы действительно хотите ЖЁСТКО отключить виртуалку "${this.selectedRunningVM}"?`)) return;
      try {
        let res = await axios.post('/api/vms/force_stop', {
          vm_host: this.selectedServer,
          vm_name: this.selectedRunningVM
        });
        this.logs.unshift({
          time: new Date().toLocaleString(),
          ...res.data
        });
        alert(`ВМ ${res.data.vm} ЖЁСТКО отключена на сервере ${res.data.host} — статус: ${res.data.status}`);
        await this.fetchRunningVMs();
      } catch {
        this.logs.unshift({
          time: new Date().toLocaleString(),
          action: 'force_stop',
          vm: this.selectedRunningVM,
          host: this.selectedServer,
          status: 'error'
        });
        alert('Ошибка жёсткого выключения ВМ');
      }
    },
    async stopRunningVM() {
      if (!this.selectedServer || !this.selectedRunningVM) {
        alert("Выберите сервер и виртуалку для выключения!");
        return;
      }
      if (!confirm(`Вы действительно хотите выключить виртуалку "${this.selectedRunningVM}"?`)) return;
      try {
        let res = await axios.post('/api/vms/stop', {
          vm_host: this.selectedServer,
          vm_name: this.selectedRunningVM
        });
        this.logs.unshift({
          time: new Date().toLocaleString(),
          ...res.data
        });
        alert(`ВМ ${res.data.vm} выключена на сервере ${res.data.host} — статус: ${res.data.status}`);
        // обновим список запущенных ВМ
        await this.fetchRunningVMs();
      } catch {
        this.logs.unshift({
          time: new Date().toLocaleString(),
          action: 'stop',
          vm: this.selectedRunningVM,
          host: this.selectedServer,
          status: 'error'
        });
        alert('Ошибка выключения ВМ');
      }
    },
    async fetchRunningVMs() {
      if (!this.selectedServer) return;
      let res = await axios.get(`/api/vms/running?vm=${this.selectedServer}`);
      this.runningVMs = res.data.running_vms || [];
      if (this.runningVMs && this.runningVMs.length) this.selectedRunningVM = this.runningVMs[0];
    },
    async fetchVMs() {
      if (!this.selectedServer) return;
      await axios.get(`/api/vms/available?vm=${this.selectedServer}`);
      let res = await axios.get(`/api/vms/cached?vm=${this.selectedServer}`);
      this.vms = res.data.vms;
      if (this.vms && this.vms.length) this.selectedVM = this.vms[0].name;
    },
    async runVM() {
      if (!this.selectedServer || !this.selectedVM) return alert("Выберите ВМ!");
      try {
        let res = await axios.post('/api/vms/start', {
          vm_host: this.selectedServer,
          vm_name: this.selectedVM
        });
        this.logs.unshift({
          time: new Date().toLocaleString(),
          ...res.data
        });
        alert(`ВМ ${res.data.vm} запущена на сервере ${res.data.host} — статус: ${res.data.status}`);
      } catch {
        this.logs.unshift({
          time: new Date().toLocaleString(),
          action: 'start',
          vm: this.selectedVM,
          host: this.selectedServer,
          status: 'error'
        });
        alert('Ошибка запуска ВМ');
      }
    }
  }
}
</script>
