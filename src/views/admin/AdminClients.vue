<template>
  <div>
    <div class="page-header">
      <div>
        <h2 class="page-title">Clients</h2>
        <p class="page-subtitle">Manage client companies and accounts</p>
      </div>
      <button @click="openCreateModal" class="btn-primary">
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
        </svg>
        Add Client
      </button>
    </div>

    <div class="card">
      <LoadingSpinner v-if="loading" text="Loading clients..." />
      <div v-else-if="!clients.length" class="empty-state">
        <div class="empty-state-icon">🏢</div>
        <p class="font-medium text-gray-700">No clients yet</p>
        <p class="text-sm text-gray-400 mt-1 mb-4">Create a client account to get started</p>
        <button @click="openCreateModal" class="btn-primary">Add Client</button>
      </div>
      <div v-else class="table-container">
        <table class="table">
          <thead>
            <tr>
              <th>Client</th>
              <th>Email</th>
              <th>Active Projects</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="client in clients" :key="client.id">
              <td>
                <div class="flex items-center gap-3">
                  <div class="avatar w-9 h-9 text-sm bg-purple-100 text-purple-700">
                    {{ client.full_name?.split(' ').map(n=>n[0]).join('').toUpperCase().slice(0,2) || 'C' }}
                  </div>
                  <span class="font-medium text-gray-900">{{ client.full_name }}</span>
                </div>
              </td>
              <td class="text-gray-500">{{ client.email }}</td>
              <td>
                <span class="badge badge-purple">{{ client.project_count || 0 }} projects</span>
              </td>
              <td>
                <div class="flex items-center gap-2">
                  <button @click="openEditModal(client)" class="btn-secondary btn-sm">Edit</button>
                  <button @click="confirmDelete(client)" class="btn-danger btn-sm">Remove</button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Create/Edit Modal -->
    <AppModal
      :show="showModal"
      :title="editingClient ? 'Edit Client' : 'Add New Client'"
      @close="closeModal"
    >
      <form @submit.prevent="saveClient" class="space-y-4">
        <div class="form-group">
          <label class="form-label">Company / Full Name <span class="text-red-500">*</span></label>
          <input v-model="form.full_name" type="text" class="form-input" placeholder="Acme Corporation" required />
        </div>
        <div class="form-group">
          <label class="form-label">Email Address <span class="text-red-500">*</span></label>
          <input v-model="form.email" type="email" class="form-input" placeholder="contact@acme.com" :disabled="!!editingClient" required />
        </div>
        <div v-if="!editingClient" class="form-group">
          <label class="form-label">Password <span class="text-red-500">*</span></label>
          <input v-model="form.password" type="password" class="form-input" placeholder="Min. 8 characters" required minlength="8" />
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <button type="button" @click="closeModal" class="btn-secondary">Cancel</button>
          <button type="submit" class="btn-primary" :disabled="saving">
            <span v-if="saving" class="spinner w-4 h-4"></span>
            {{ editingClient ? 'Save Changes' : 'Create Client' }}
          </button>
        </div>
      </form>
    </AppModal>

    <!-- Delete Modal -->
    <AppModal :show="showDeleteModal" title="Remove Client" @close="showDeleteModal = false">
      <p class="text-gray-600 text-sm mb-4">
        Remove <strong>{{ deletingClient?.full_name }}</strong>? All their data will be preserved but they will lose portal access.
      </p>
      <div class="flex justify-end gap-3">
        <button @click="showDeleteModal = false" class="btn-secondary">Cancel</button>
        <button @click="deleteClient" class="btn-danger" :disabled="saving">
          <span v-if="saving" class="spinner w-4 h-4"></span>
          Remove Client
        </button>
      </div>
    </AppModal>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useToast } from 'vue-toastification'
import AppModal from '@/components/shared/AppModal.vue'
import LoadingSpinner from '@/components/shared/LoadingSpinner.vue'

const toast = useToast()
const clients = ref([])
const loading = ref(true)
const saving = ref(false)
const showModal = ref(false)
const showDeleteModal = ref(false)
const editingClient = ref(null)
const deletingClient = ref(null)
const form = ref({ full_name: '', email: '', password: '' })

onMounted(fetchClients)

async function fetchClients() {
  loading.value = true
  const { data } = await supabase.from('profiles').select('*').eq('role', 'CLIENT').order('full_name')
  if (data) {
    const ids = data.map(c => c.id)
    const { data: projects } = await supabase.from('projects').select('client_id').in('client_id', ids)
    const countMap = {}
    projects?.forEach(p => { countMap[p.client_id] = (countMap[p.client_id] || 0) + 1 })
    clients.value = data.map(c => ({ ...c, project_count: countMap[c.id] || 0 }))
  }
  loading.value = false
}

function openCreateModal() {
  editingClient.value = null
  form.value = { full_name: '', email: '', password: '' }
  showModal.value = true
}

function openEditModal(client) {
  editingClient.value = client
  form.value = { full_name: client.full_name, email: client.email, password: '' }
  showModal.value = true
}

function closeModal() { showModal.value = false; editingClient.value = null }

async function saveClient() {
  saving.value = true
  try {
    if (editingClient.value) {
      await supabase.from('profiles').update({ full_name: form.value.full_name, updated_at: new Date().toISOString() }).eq('id', editingClient.value.id)
      toast.success('Client updated')
    } else {
      const { data, error } = await supabase.auth.signUp({
        email: form.value.email,
        password: form.value.password,
        options: {
          data: { full_name: form.value.full_name, role: 'CLIENT' }
        }
      })
      if (error) throw error
      if (!data.user) throw new Error('User creation failed')

      const { error: profileError } = await supabase.from('profiles').upsert({
        id: data.user.id,
        email: form.value.email,
        full_name: form.value.full_name,
        role: 'CLIENT',
        updated_at: new Date().toISOString()
      })
      if (profileError) throw profileError

      toast.success('Client account created! They can now log in.')
    }
    closeModal()
    await fetchClients()
  } catch (err) {
    toast.error(err.message)
  } finally {
    saving.value = false
  }
}

function confirmDelete(client) { deletingClient.value = client; showDeleteModal.value = true }

async function deleteClient() {
  saving.value = true
  try {
    const { error } = await supabase
      .from('profiles')
      .delete()
      .eq('id', deletingClient.value.id)
    if (error) throw error
    toast.success('Client removed from portal')
    showDeleteModal.value = false
    await fetchClients()
  } catch (err) {
    toast.error(err.message)
  } finally {
    saving.value = false
  }
}
</script>
