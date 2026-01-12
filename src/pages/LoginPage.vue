<template>
    <div class="login-page">
        <div class="login-card">
            <div class="login-header">
                <h1>Вход в систему</h1>
                <p>CloudeGaming VM Manager</p>
            </div>
            <form @submit.prevent="handleLogin" class="login-form">
                <div class="form-group">
                    <label for="username">Логин</label>
                    <input id="username" v-model="username" type="text" class="form-input" placeholder="Введите логин"
                        required />
                </div>
                <div class="form-group">
                    <label for="password">Пароль</label>
                    <input id="password" v-model="password" type="password" class="form-input"
                        placeholder="Введите пароль" required />
                </div>
                <div v-if="error" class="error-message">{{ error }}</div>
                <button type="submit" class="login-btn" :disabled="loading">
                    {{ loading ? 'Вход...' : 'Войти' }}
                </button>
            </form>
        </div>
    </div>
</template>

<script>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from 'src/stores/auth'

export default {
    setup() {
        const router = useRouter()
        const authStore = useAuthStore()

        const username = ref('')
        const password = ref('')
        const error = ref('')
        const loading = ref(false)

        const handleLogin = async () => {
            error.value = ''
            loading.value = true

            const result = await authStore.login(username.value, password.value)

            loading.value = false

            if (result.success) {
                router.push('/')
            } else {
                error.value = result.error
            }
        }

        return {
            username,
            password,
            error,
            loading,
            handleLogin
        }
    }
}
</script>

<style scoped>
.login-page {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    padding: 20px;
}

.login-card {
    background: white;
    border-radius: 16px;
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
    padding: 40px;
    width: 100%;
    max-width: 420px;
}

.login-header {
    text-align: center;
    margin-bottom: 32px;
}

.login-header h1 {
    font-size: 28px;
    font-weight: 700;
    color: #1a202c;
    margin: 0 0 8px 0;
}

.login-header p {
    font-size: 14px;
    color: #718096;
    margin: 0;
}

.login-form {
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
    text-align: center;
}

.login-btn {
    padding: 14px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    border: none;
    border-radius: 8px;
    font-size: 16px;
    font-weight: 600;
    cursor: pointer;
    transition: transform 0.2s, box-shadow 0.2s;
}

.login-btn:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 10px 20px rgba(102, 126, 234, 0.3);
}

.login-btn:disabled {
    opacity: 0.6;
    cursor: not-allowed;
}
</style>
