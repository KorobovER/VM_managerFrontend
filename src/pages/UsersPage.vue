<template>
  <q-page class="q-pa-md">
    <div class="page-header">
      <h1 class="page-title">Пользователи</h1>
      <p class="page-description">Управление пользователями системы</p>
    </div>

    <q-card class="users-card">
      <q-card-section>
        <div class="row items-center justify-between q-mb-md">
          <div class="text-h6">Список пользователей</div>
          <q-btn color="primary" icon="refresh" label="Обновить" @click="fetchUsers" :loading="loading" />
        </div>

        <q-table :rows="users" :columns="columns" row-key="id" :loading="loading" :pagination="{ rowsPerPage: 10 }"
          class="users-table">
          <template v-slot:body-cell-role="props">
            <q-td :props="props">
              <q-badge :color="props.row.role === 'admin' ? 'purple' : 'green'"
                :label="props.row.role === 'admin' ? 'Администратор' : 'Пользователь'" />
            </q-td>
          </template>

          <template v-slot:body-cell-is_active="props">
            <q-td :props="props">
              <q-badge :color="props.row.is_active ? 'positive' : 'negative'"
                :label="props.row.is_active ? 'Активен' : 'Неактивен'" />
            </q-td>
          </template>

          <template v-slot:no-data>
            <div class="full-width row flex-center text-grey-6 q-gutter-sm">
              <q-icon size="2em" name="sentiment_dissatisfied" />
              <span>Нет данных для отображения</span>
            </div>
          </template>
        </q-table>
      </q-card-section>
    </q-card>

    <q-dialog v-model="errorDialog" position="top">
      <q-card class="error-card">
        <q-card-section class="row items-center">
          <q-avatar icon="error" color="negative" text-color="white" />
          <span class="q-ml-sm">{{ errorMessage }}</span>
        </q-card-section>
        <q-card-actions align="right">
          <q-btn flat label="OK" color="primary" v-close-popup />
        </q-card-actions>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script>
import { ref, onMounted } from 'vue'
import { api } from 'src/boot/axios'

export default {
  name: 'UsersPage',
  setup() {
    const users = ref([])
    const loading = ref(false)
    const errorDialog = ref(false)
    const errorMessage = ref('')

    const columns = [
      {
        name: 'id',
        required: true,
        label: 'ID',
        align: 'left',
        field: row => row.id,
        sortable: true
      },
      {
        name: 'username',
        required: true,
        label: 'Имя пользователя',
        align: 'left',
        field: row => row.username,
        sortable: true
      },
      {
        name: 'email',
        required: true,
        label: 'Email',
        align: 'left',
        field: row => row.email,
        sortable: true
      },
      {
        name: 'role',
        required: true,
        label: 'Роль',
        align: 'left',
        field: row => row.role,
        sortable: true
      },
      {
        name: 'is_active',
        required: true,
        label: 'Статус',
        align: 'left',
        field: row => row.is_active,
        sortable: true
      }
    ]

    const fetchUsers = async () => {
      loading.value = true
      try {
        const response = await api.get('api/admin/users')
        console.log('Response from /admin/users:', response)
        console.log('Response data:', response.data)
        console.log('Type of response.data:', typeof response.data)
        console.log('Is array?', Array.isArray(response.data))
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

    onMounted(() => {
      fetchUsers()
    })

    return {
      users,
      loading,
      errorDialog,
      errorMessage,
      columns,
      fetchUsers
    }
  }
}
</script>

<style scoped>
.page-header {
  margin-bottom: 24px;
}

.page-title {
  font-size: 2rem;
  font-weight: 700;
  color: var(--hiveon-text);
  margin: 0 0 8px 0;
}

.page-description {
  color: #a0aec0;
  font-size: 1rem;
  margin: 0;
}

.users-card {
  background: var(--hiveon-card);
  border: 1px solid #20262f;
  border-radius: 12px;
}

.users-table {
  background: transparent;
}

.users-table :deep(.q-table__container) {
  background: transparent;
}

.users-table :deep(.q-table th) {
  color: var(--hiveon-cyan);
  font-weight: 600;
  border-bottom: 1px solid #20262f;
}

.users-table :deep(.q-table td) {
  color: var(--hiveon-text);
  border-bottom: 1px solid rgba(32, 38, 47, 0.5);
}

.users-table :deep(.q-table tr:hover td) {
  background: rgba(102, 126, 234, 0.05);
}

.error-card {
  background: var(--hiveon-card);
  border: 1px solid #20262f;
  color: var(--hiveon-text);
}
</style>
