<template>
  <div>
    <div class="page-header">
      <div>
        <h2 class="page-title">User Management</h2>
        <p class="page-subtitle">View and manage all system users</p>
      </div>
    </div>

    <!-- Search + filter -->
    <div class="flex flex-wrap gap-3 mb-5">
      <input v-model="search" type="text" class="form-input w-64" placeholder="Search users..." />
      <select v-model="filterRole" class="form-select w-40">
        <option value="">All Roles</option>
        <option value="ADMIN">Admin</option>
        <option value="EMPLOYEE">Employee</option>
        <option value="CLIENT">Client</option>
      </select>
    </div>

    <div class="card">
      <LoadingSpinner v-if="loading" text="Loading users..." />
      <div v-else class="table-container">
        <table class="table">
          <thead>
            <tr>
              <th>User</th>
              <th>Email</th>
              <th>Role</th>
              <th>Last Updated</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="user in filteredUsers" :key="user.id">
              <td>
                <div class="flex items-center gap-3">
                  <div
                    class="avatar w-9 h-9 text-sm"
                    :class="{
                      'bg-blue-100 text-blue-700': user.role === 'ADMIN',
                      'bg-emerald-100 text-emerald-700': user.role === 'EMPLOYEE',
                      'bg-purple-100 text-purple-700': user.role === 'CLIENT',
                    }"
                  >
                    {{ user.full_name?.split(' ').map(n=>n[0]).join('').toUpperCase().slice(0,2) || 'U' }}
                  </div>
                  <span class="font-medium text-gray-900">{{ user.full_name }}</span>
                </div>
              </td>
              <td class="text-gray-500">{{ user.email }}</td>
              <td>
                <span
                  class="badge"
                  :class="{
                    'badge-blue': user.role === 'ADMIN',
                    'badge-green': user.role === 'EMPLOYEE',
                    'badge-purple': user.role === 'CLIENT',
                  }"
                >{{ user.role }}</span>
              </td>
              <td class="text-gray-500">{{ formatDate(user.updated_at) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import LoadingSpinner from '@/components/shared/LoadingSpinner.vue'

const users = ref([])
const loading = ref(true)
const search = ref('')
const filterRole = ref('')

const filteredUsers = computed(() => users.value.filter(u => {
  const matchSearch = !search.value || u.full_name?.toLowerCase().includes(search.value.toLowerCase()) || u.email?.toLowerCase().includes(search.value.toLowerCase())
  const matchRole = !filterRole.value || u.role === filterRole.value
  return matchSearch && matchRole
}))

onMounted(async () => {
  const { data } = await supabase.from('profiles').select('*').order('role').order('full_name')
  users.value = data || []
  loading.value = false
})

function formatDate(ts) {
  return ts ? new Date(ts).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }) : '—'
}
</script>
