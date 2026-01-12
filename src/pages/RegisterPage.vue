<template>
    <div class="register-page">
        <div class="register-card">
            <div class="register-header">
                <h1>Регистрация пользователя</h1>
                <p>Только для администраторов</p>
            </div>
            <form @submit.prevent="handleRegister" class="register-form">
                <div class="form-group">
                    <label for="username">Логин</label>
                    <input id="username" v-model="formData.username" type="text" class="form-input"
                        placeholder="Введите логин" required />
                </div>
                <div class="form-group">
                    <label for="email">Email</label>
                    <input id="email" v-model="formData.email" type="email" class="form-input"
                        placeholder="user@example.com" required />
                </div>
                <div class="form-group">
                    <label for="password">Пароль</label>
                    <input id="password" v-model="formData.password" type="password" class="form-input"
                        placeholder="Введите пароль" required />
                </div>
                <div class="form-group">
                    <label for="role">Роль</label>
                    <select id="role" v-model="formData.role" class="form-input">
                        <option value="user">Пользователь</option>
                        <option value="admin">Администратор</option>
                    </select>
                </div>
                <div v-if="error" class="error-message">{{ error }}</div>
                <div v-if="success" class="success-message">{{ success }}</div>
                <div class="form-actions">
                    <button type="button" @click="$router.back()" class="btn-secondary">Назад</button>
                    <button type="submit" class="btn-primary" :disabled="loading">
                        {{ loading ? 'Регистрация...' : 'Зарегистрировать' }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</template>

<script>
import { ref } from 'vue'
import { useAuthStore } from 'src/stores/auth'

export default {
    setup() {
        const authStore = useAuthStore()

        const formData = ref({
            username: '',
            email: '',
            password: '',
            role: 'user'
        })
        const error = ref('')
        const success = ref('')
        const loading = ref(false)

        const handleRegister = async () => {
            error.value = ''
            success.value = ''
            loading.value = true

            const result = await authStore.register(formData.value)

            loading.value = false

            if (result.success) {
                success.value = `Пользователь ${formData.value.username} успешно зарегистрирован!`
                formData.value = {
                    username: '',
                    email: '',
                    password: '',
                    role: 'user'
                }
            } else {
                error.value = result.error
            }
        }

        return {
            formData,
            error,
            success,
            loading,
            handleRegister
        }
    }
}
</script>

<style scoped>
.register-page {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    padding: 20px;
}

.register-card {
    background: white;
    border-radius: 16px;
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
    padding: 40px;
    width: 100%;
    max-width: 500px;
}

.register-header {
    text-align: center;
    margin-bottom: 32px;
}

.register-header h1 {
    font-size: 28px;
    font-weight: 700;
    color: #1a202c;
    margin: 0 0 8px 0;
}

.register-header p {
    font-size: 14px;
    color: #718096;
    margin: 0;
}

.register-form {
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

.success-message {
    padding: 12px;
    background: #c6f6d5;
    color: #22543d;
    border-radius: 8px;
    font-size: 14px;
    text-align: center;
}

.form-actions {
    display: flex;
    gap: 12px;
    justify-content: flex-end;
}

.btn-primary,
.btn-secondary {
    padding: 14px 24px;
    border: none;
    border-radius: 8px;
    font-size: 16px;
    font-weight: 600;
    cursor: pointer;
    transition: transform 0.2s, box-shadow 0.2s;
}

.btn-primary {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
}

.btn-primary:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 10px 20px rgba(102, 126, 234, 0.3);
}

.btn-primary:disabled {
    opacity: 0.6;
    cursor: not-allowed;
}

.btn-secondary {
    background: #e2e8f0;
    color: #2d3748;
}

.btn-secondary:hover {
    background: #cbd5e0;
}
</style>
