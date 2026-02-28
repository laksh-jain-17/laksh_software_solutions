<template>
  <div>
    <div class="page-header">
      <div>
        <h2 class="page-title">Employees</h2>
        <p class="page-subtitle">Manage your team members</p>
      </div>
      <button @click="openCreateModal" class="btn-primary">
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
        </svg>
        Add Employee
      </button>
    </div>

    <!-- Employees table -->
    <div class="card">
      <LoadingSpinner v-if="loading" text="Loading employees..." />
      <div v-else-if="!employees.length" class="empty-state">
        <div class="empty-state-icon">👥</div>
        <p class="font-medium text-gray-700">No employees yet</p>
        <p class="text-sm text-gray-400 mt-1 mb-4">Add your first team member to get started</p>
        <button @click="openCreateModal" class="btn-primary">Add Employee</button>
      </div>
      <div v-else class="table-container">
        <table class="table">
          <thead>
            <tr>
              <th>Employee</th>
              <th>Email</th>
              <th>Assigned Projects</th>
              <th>Joined</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="emp in employees" :key="emp.id">
              <td>
                <div class="flex items-center gap-3">
                  <div class="avatar w-9 h-9 text-sm">
                    {{ emp.full_name?.split(' ').map(n=>n[0]).join('').toUpperCase().slice(0,2) || 'U' }}
                  </div>
                  <span class="font-medium text-gray-900">{{ emp.full_name }}</span>
                </div>
              </td>
              <td class="text-gray-500">{{ emp.email }}</td>
              <td>
                <span class="badge badge-blue">{{ emp.project_count || 0 }} projects</span>
              </td>
              <td class="text-gray-500">{{ formatDate(emp.updated_at) }}</td>
              <td>
                <div class="flex items-center gap-2">
                  <button @click="openEditModal(emp)" class="btn-secondary btn-sm">Edit</button>
                  <button @click="confirmDelete(emp)" class="btn-danger btn-sm">Remove</button>
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
      :title="editingEmployee ? 'Edit Employee' : 'Add New Employee'"
      :subtitle="editingEmployee ? 'Update employee information' : 'Create a new employee account'"
      @close="closeModal"
    >
      <form @submit.prevent="saveEmployee" class="space-y-4">
        <div class="form-group">
          <label class="form-label">Full Name <span class="text-red-500">*</span></label>
          <input v-model="form.full_name" type="text" class="form-input" placeholder="John Doe" required />
        </div>
        <div class="form-group">
          <label class="form-label">Email Address <span class="text-red-500">*</span></label>
          <input v-model="form.email" type="email" class="form-input" placeholder="john@company.com" :disabled="!!editingEmployee" required />
          <p v-if="editingEmployee" class="form-error">Email cannot be changed after creation</p>
        </div>
        <div v-if="!editingEmployee" class="form-group">
          <label class="form-label">Password <span class="text-red-500">*</span></label>
          <input v-model="form.password" type="password" class="form-input" placeholder="Min. 8 characters" required minlength="8" />
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <button type="button" @click="closeModal" class="btn-secondary">Cancel</button>
          <button type="submit" class="btn-primary" :disabled="saving">
            <span v-if="saving" class="spinner w-4 h-4"></span>
            {{ editingEmployee ? 'Save Changes' : 'Create Employee' }}
          </button>
        </div>
      </form>
    </AppModal>

    <!-- Delete Confirmation -->
    <AppModal :show="showDeleteModal" title="Remove Employee" subtitle="This action cannot be undone" @close="showDeleteModal = false">
      <p class="text-gray-600 text-sm mb-4">
        Are you sure you want to remove <strong>{{ deletingEmployee?.full_name }}</strong>? They will lose access to the portal.
      </p>
      <div class="flex justify-end gap-3">
        <button @click="showDeleteModal = false" class="btn-secondary">Cancel</button>
        <button @click="deleteEmployee" class="btn-danger" :disabled="saving">
          <span v-if="saving" class="spinner w-4 h-4"></span>
          Remove Employee
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
const employees = ref([])
const loading = ref(true)
const saving = ref(false)
const showModal = ref(false)
const showDeleteModal = ref(false)
const editingEmployee = ref(null)
const deletingEmployee = ref(null)

const form = ref({ full_name: '', email: '', password: '' })

onMounted(fetchEmployees)

async function fetchEmployees() {
  loading.value = true
  const { data } = await supabase
    .from('profiles')
    .select('*')
    .eq('role', 'EMPLOYEE')
    .order('full_name')

  if (data) {
    // Get project counts
    const ids = data.map(e => e.id)
    const { data: assignments } = await supabase
      .from('project_assignments')
      .select('employee_id')
      .in('employee_id', ids)

    const countMap = {}
    assignments?.forEach(a => {
      countMap[a.employee_id] = (countMap[a.employee_id] || 0) + 1
    })
    employees.value = data.map(e => ({ ...e, project_count: countMap[e.id] || 0 }))
  }
  loading.value = false
}

function openCreateModal() {
  editingEmployee.value = null
  form.value = { full_name: '', email: '', password: '' }
  showModal.value = true
}

function openEditModal(emp) {
  editingEmployee.value = emp
  form.value = { full_name: emp.full_name, email: emp.email, password: '' }
  showModal.value = true
}

function closeModal() {
  showModal.value = false
  editingEmployee.value = null
}

async function saveEmployee() {
  saving.value = true
  try {
    if (editingEmployee.value) {
      const { error } = await supabase
        .from('profiles')
        .update({ full_name: form.value.full_name, updated_at: new Date().toISOString() })
        .eq('id', editingEmployee.value.id)
      if (error) throw error
      toast.success('Employee updated successfully')
    } else {
      // Save current admin session first
      const { data: { session: adminSession } } = await supabase.auth.getSession()

      // Create the new employee account
      const { data, error } = await supabase.auth.signUp({
        email: form.value.email,
        password: form.value.password,
        options: {
          data: { full_name: form.value.full_name, role: 'EMPLOYEE' }
        }
      })
      if (error) throw error
      if (!data.user) throw new Error('User creation failed')

      // Insert profile directly with correct role
      const { error: profileError } = await supabase.from('profiles').upsert({
        id: data.user.id,
        email: form.value.email,
        full_name: form.value.full_name,
        role: 'EMPLOYEE',
        updated_at: new Date().toISOString()
      })
      if (profileError) throw profileError

      // Restore admin session immediately
      if (adminSession) {
        await supabase.auth.setSession({
          access_token: adminSession.access_token,
          refresh_token: adminSession.refresh_token
        })
      }

      toast.success('Employee account created! They can now log in.')
    }
    closeModal()
    await fetchEmployees()
  } catch (err) {
    toast.error(err.message)
  } finally {
    saving.value = false
  }
}

function confirmDelete(emp) {
  deletingEmployee.value = emp
  showDeleteModal.value = true
}

async function deleteEmployee() {
  saving.value = true
  try {
    // Delete profile (auth user will cascade if set up, otherwise just remove profile)
    const { error } = await supabase
      .from('profiles')
      .delete()
      .eq('id', deletingEmployee.value.id)
    if (error) throw error
    toast.success('Employee removed from portal')
    showDeleteModal.value = false
    await fetchEmployees()
  } catch (err) {
    toast.error(err.message)
  } finally {
    saving.value = false
  }
}

function formatDate(ts) {
  return ts ? new Date(ts).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }) : '—'
}
</script>
