<template>
  <div>
    <div class="page-header">
      <div>
        <h2 class="page-title">Projects</h2>
        <p class="page-subtitle">Manage all projects and team assignments</p>
      </div>
      <button @click="openCreateModal" class="btn-primary">
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
        </svg>
        New Project
      </button>
    </div>

    <!-- Filters -->
    <div class="flex flex-wrap gap-3 mb-5">
      <select v-model="filterStatus" class="form-select w-40">
        <option value="">All Statuses</option>
        <option v-for="s in statuses" :key="s" :value="s">{{ s }}</option>
      </select>
      <input v-model="search" type="text" class="form-input w-56" placeholder="Search projects..." />
    </div>

    <div class="card">
      <LoadingSpinner v-if="loading" text="Loading projects..." />
      <div v-else-if="!filteredProjects.length" class="empty-state">
        <div class="empty-state-icon">📁</div>
        <p class="font-medium text-gray-700">No projects found</p>
      </div>
      <div v-else class="table-container">
        <table class="table">
          <thead>
            <tr>
              <th>Project</th>
              <th>Client</th>
              <th>Assigned To</th>
              <th>Status</th>
              <th>Created</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="project in filteredProjects" :key="project.id">
              <td>
                <p class="font-medium text-gray-900">{{ project.name }}</p>
                <p class="text-xs text-gray-400 mt-0.5 line-clamp-1 max-w-xs">{{ project.description }}</p>
              </td>
              <td>{{ project.client?.full_name || '—' }}</td>
              <td>
                <div class="flex flex-wrap gap-1">
                  <span v-if="!project.assignments?.length" class="text-gray-400 text-xs italic">Unassigned</span>
                  <span
                    v-for="a in project.assignments"
                    :key="a.employee_id"
                    class="badge badge-blue text-xs"
                  >
                    {{ a.employee?.full_name?.split(' ')[0] || '—' }}
                  </span>
                </div>
              </td>
              <td><StatusBadge :status="project.status" /></td>
              <td class="text-gray-500">{{ formatDate(project.created_at) }}</td>
              <td>
                <div class="flex items-center gap-2">
                  <button @click="openEditModal(project)" class="btn-secondary btn-sm">Edit</button>
                  <button @click="openAssignModal(project)" class="btn-success btn-sm">Assign</button>
                  <button @click="confirmDelete(project)" class="btn-danger btn-sm">Delete</button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Create/Edit Project Modal -->
    <AppModal :show="showModal" :title="editing ? 'Edit Project' : 'New Project'" @close="closeModal" size="lg">
      <form @submit.prevent="saveProject" class="space-y-4">
        <div class="grid grid-cols-2 gap-4">
          <div class="form-group col-span-2">
            <label class="form-label">Project Name <span class="text-red-500">*</span></label>
            <input v-model="form.name" type="text" class="form-input" placeholder="E.g. Website Redesign" required />
          </div>
          <div class="form-group col-span-2">
            <label class="form-label">Description</label>
            <textarea v-model="form.description" class="form-textarea" rows="3" placeholder="Project overview..."></textarea>
          </div>
          <div class="form-group">
            <label class="form-label">Client <span class="text-red-500">*</span></label>
            <select v-model="form.client_id" class="form-select" required>
              <option value="">Select client</option>
              <option v-for="c in clientOptions" :key="c.id" :value="c.id">{{ c.full_name }}</option>
            </select>
          </div>
          <div class="form-group">
            <label class="form-label">Status</label>
            <select v-model="form.status" class="form-select">
              <option v-for="s in statuses" :key="s" :value="s">{{ s }}</option>
            </select>
          </div>
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <button type="button" @click="closeModal" class="btn-secondary">Cancel</button>
          <button type="submit" class="btn-primary" :disabled="saving">
            <span v-if="saving" class="spinner w-4 h-4"></span>
            {{ editing ? 'Save Changes' : 'Create Project' }}
          </button>
        </div>
      </form>
    </AppModal>

    <!-- Assign Employees Modal -->
    <AppModal :show="showAssignModal" title="Assign Employees" :subtitle="`Project: ${assigningProject?.name}`" @close="showAssignModal = false">
      <LoadingSpinner v-if="loadingEmployees" size="sm" />
      <div v-else class="space-y-2 max-h-72 overflow-y-auto">
        <label
          v-for="emp in employeeOptions"
          :key="emp.id"
          class="flex items-center gap-3 p-3 rounded-lg border border-gray-100 hover:bg-gray-50 cursor-pointer transition-colors"
        >
          <input
            type="checkbox"
            :value="emp.id"
            v-model="selectedEmployees"
            class="w-4 h-4 rounded border-gray-300 text-primary-600 focus:ring-primary-500"
          />
          <div class="avatar w-8 h-8 text-sm">
            {{ emp.full_name?.split(' ').map(n=>n[0]).join('').toUpperCase().slice(0,2) || 'U' }}
          </div>
          <span class="text-sm font-medium text-gray-700">{{ emp.full_name }}</span>
        </label>
        <p v-if="!employeeOptions.length" class="text-gray-400 text-sm text-center py-4">No employees available</p>
      </div>
      <div class="flex justify-end gap-3 mt-4">
        <button @click="showAssignModal = false" class="btn-secondary">Cancel</button>
        <button @click="saveAssignments" class="btn-primary" :disabled="saving">
          <span v-if="saving" class="spinner w-4 h-4"></span>
          Save Assignments
        </button>
      </div>
    </AppModal>

    <!-- Delete Modal -->
    <AppModal :show="showDeleteModal" title="Delete Project" @close="showDeleteModal = false">
      <p class="text-gray-600 text-sm mb-4">Delete <strong>{{ deletingProject?.name }}</strong>? This cannot be undone.</p>
      <div class="flex justify-end gap-3">
        <button @click="showDeleteModal = false" class="btn-secondary">Cancel</button>
        <button @click="deleteProject" class="btn-danger" :disabled="saving">
          <span v-if="saving" class="spinner w-4 h-4"></span>
          Delete Project
        </button>
      </div>
    </AppModal>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useToast } from 'vue-toastification'
import AppModal from '@/components/shared/AppModal.vue'
import LoadingSpinner from '@/components/shared/LoadingSpinner.vue'
import StatusBadge from '@/components/shared/StatusBadge.vue'

const toast = useToast()
const projects = ref([])
const clientOptions = ref([])
const employeeOptions = ref([])
const loading = ref(true)
const loadingEmployees = ref(false)
const saving = ref(false)
const showModal = ref(false)
const showAssignModal = ref(false)
const showDeleteModal = ref(false)
const editing = ref(null)
const assigningProject = ref(null)
const deletingProject = ref(null)
const selectedEmployees = ref([])
const search = ref('')
const filterStatus = ref('')

const statuses = ['Pending', 'In Progress', 'Completed', 'On Hold', 'Cancelled']

const form = ref({ name: '', description: '', client_id: '', status: 'Pending' })

const filteredProjects = computed(() => {
  return projects.value.filter(p => {
    const matchSearch = !search.value || p.name.toLowerCase().includes(search.value.toLowerCase())
    const matchStatus = !filterStatus.value || p.status === filterStatus.value
    return matchSearch && matchStatus
  })
})

onMounted(async () => {
  await Promise.all([fetchProjects(), fetchClientOptions()])
})

async function fetchProjects() {
  loading.value = true
  const { data } = await supabase
    .from('projects')
    .select(`
      *,
      client:profiles!projects_client_id_fkey(id, full_name),
      assignments:project_assignments(employee_id, employee:profiles!project_assignments_employee_id_fkey(id, full_name))
    `)
    .order('created_at', { ascending: false })
  projects.value = data || []
  loading.value = false
}

async function fetchClientOptions() {
  const { data } = await supabase.from('profiles').select('id, full_name').eq('role', 'CLIENT').order('full_name')
  clientOptions.value = data || []
}

function openCreateModal() {
  editing.value = null
  form.value = { name: '', description: '', client_id: '', status: 'Pending' }
  showModal.value = true
}

function openEditModal(project) {
  editing.value = project
  form.value = { name: project.name, description: project.description || '', client_id: project.client_id, status: project.status }
  showModal.value = true
}

function closeModal() { showModal.value = false; editing.value = null }

async function saveProject() {
  saving.value = true
  try {
    if (editing.value) {
      const { error } = await supabase.from('projects').update(form.value).eq('id', editing.value.id)
      if (error) throw error
      toast.success('Project updated')
    } else {
      const { error } = await supabase.from('projects').insert(form.value)
      if (error) throw error
      toast.success('Project created')
    }
    closeModal()
    await fetchProjects()
  } catch (err) {
    toast.error(err.message)
  } finally {
    saving.value = false
  }
}

async function openAssignModal(project) {
  assigningProject.value = project
  loadingEmployees.value = true
  showAssignModal.value = true

  const { data } = await supabase.from('profiles').select('id, full_name').eq('role', 'EMPLOYEE').order('full_name')
  employeeOptions.value = data || []

  selectedEmployees.value = project.assignments?.map(a => a.employee_id) || []
  loadingEmployees.value = false
}

async function saveAssignments() {
  saving.value = true
  try {
    // Delete all current assignments
    await supabase.from('project_assignments').delete().eq('project_id', assigningProject.value.id)

    // Insert new ones
    if (selectedEmployees.value.length) {
      const inserts = selectedEmployees.value.map(eid => ({
        project_id: assigningProject.value.id,
        employee_id: eid
      }))
      const { error } = await supabase.from('project_assignments').insert(inserts)
      if (error) throw error
    }

    toast.success('Assignments saved')
    showAssignModal.value = false
    await fetchProjects()
  } catch (err) {
    toast.error(err.message)
  } finally {
    saving.value = false
  }
}

function confirmDelete(project) { deletingProject.value = project; showDeleteModal.value = true }

async function deleteProject() {
  saving.value = true
  try {
    await supabase.from('projects').delete().eq('id', deletingProject.value.id)
    toast.success('Project deleted')
    showDeleteModal.value = false
    await fetchProjects()
  } catch (err) {
    toast.error(err.message)
  } finally {
    saving.value = false
  }
}

function formatDate(ts) {
  return new Date(ts).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })
}
</script>
