<template>
    <div class="servers-page">
        <div class="page-header">
            <h1>Управление серверами</h1>
            <button @click="showAddDialog = true" class="hiveon-btn success">
                + Добавить сервер
            </button>
        </div>

        <div class="servers-grid">
            <div v-for="server in servers" :key="server.id" class="server-card">
                <div class="server-header">
                    <h3>{{ server.name }}</h3>
                    <span class="server-id">ID: {{ server.id }}</span>
                </div>
                <div class="server-info">
                    <div class="info-row">
                        <span class="label">Хост:</span>
                        <span class="value">{{ server.host }}</span>
                    </div>
                    <div class="info-row">
                        <span class="label">Порт:</span>
                        <span class="value">{{ server.port }}</span>
                    </div>
                    <div class="info-row">
                        <span class="label">Пользователь:</span>
                        <span class="value">{{ server.user }}</span>
                    </div>
                    <div class="info-row">
                        <span class="label">Создан:</span>
                        <span class="value">{{ formatDate(server.created_at) }}</span>
                    </div>
                </div>
            </div>
        </div>

        <div v-if="showAddDialog" class="modal-overlay" @click="closeDialog">
            <div class="modal-content" @click.stop>
                <div class="modal-header">
                    <h2>Добавить новый сервер</h2>
                    <button @click="closeDialog" class="close-btn">&times;</button>
                </div>
                <form @submit.prevent="addServer" class="server-form">
                    <div class="form-group">
                        <label>Название сервера</label>
                        <input v-model="newServer.name" type="text" required class="form-input" />
                    </div>
                    <div class="form-group">
                        <label>Хост (IP адрес)</label>
                        <input v-model="newServer.host" type="text" required class="form-input" />
                    </div>
                    <div class="form-group">
                        <label>Порт</label>
                        <input v-model.number="newServer.port" type="number" required class="form-input" />
                    </div>
                    <div class="form-group">
                        <label>Пользователь</label>
                        <input v-model="newServer.user" type="text" required class="form-input" />
                    </div>
                    <div v-if="error" class="error-message">{{ error }}</div>
                    <div class="form-actions">
                        <button type="button" @click="closeDialog" class="hiveon-btn">Отмена</button>
                        <button type="submit" class="hiveon-btn success">Добавить</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</template>

<script>
import { ref, onMounted } from 'vue'
import axios from 'axios'

export default {
    setup() {
        const servers = ref([])
        const showAddDialog = ref(false)
        const error = ref('')
        const newServer = ref({
            name: '',
            host: '',
            port: 16509,
            user: 'vmuser'
        })

        const fetchServers = async () => {
            try {
                const response = await axios.get('/api/servers')
                servers.value = response.data
            } catch (err) {
                console.error('Ошибка загрузки серверов:', err)
            }
        }

        const addServer = async () => {
            error.value = ''
            try {
                const response = await axios.post('/api/servers', newServer.value)
                servers.value.push(response.data)
                closeDialog()
            } catch (err) {
                error.value = err.response?.data?.detail || 'Ошибка при добавлении сервера'
            }
        }

        const closeDialog = () => {
            showAddDialog.value = false
            error.value = ''
            newServer.value = {
                name: '',
                host: '',
                port: 16509,
                user: 'vmuser'
            }
        }

        const formatDate = (dateString) => {
            return new Date(dateString).toLocaleString('ru-RU')
        }

        onMounted(() => {
            fetchServers()
        })

        return {
            servers,
            showAddDialog,
            error,
            newServer,
            addServer,
            closeDialog,
            formatDate
        }
    }
}
</script>

<style scoped>
.servers-page {
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

.servers-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
    gap: 24px;
}

.server-card {
    background: white;
    border-radius: 12px;
    padding: 24px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    transition: transform 0.2s, box-shadow 0.2s;
}

.server-card:hover {
    transform: translateY(-4px);
    box-shadow: 0 8px 16px rgba(0, 0, 0, 0.15);
}

.server-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 16px;
    padding-bottom: 16px;
    border-bottom: 2px solid #e2e8f0;
}

.server-header h3 {
    font-size: 20px;
    font-weight: 600;
    color: #2d3748;
    margin: 0;
}

.server-id {
    font-size: 12px;
    color: #718096;
    background: #edf2f7;
    padding: 4px 8px;
    border-radius: 4px;
}

.server-info {
    display: flex;
    flex-direction: column;
    gap: 12px;
}

.info-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.info-row .label {
    font-size: 14px;
    color: #718096;
    font-weight: 500;
}

.info-row .value {
    font-size: 14px;
    color: #2d3748;
    font-weight: 600;
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

.modal-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 24px;
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
    font-size: 32px;
    color: #718096;
    cursor: pointer;
    line-height: 1;
    padding: 0;
    width: 32px;
    height: 32px;
}

.close-btn:hover {
    color: #2d3748;
}

.server-form {
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
}

.form-input:focus {
    border-color: #667eea;
    box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
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

.hiveon-btn.success {
    background: linear-gradient(135deg, #48bb78 0%, #38a169 100%);
    color: white;
}

.hiveon-btn.success:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(72, 187, 120, 0.3);
}
</style>
