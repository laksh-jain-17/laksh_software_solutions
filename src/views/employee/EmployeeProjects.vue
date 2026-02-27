<template>
  <div>
    <div class="page-header">
      <div>
        <h2 class="page-title">My Projects</h2>
        <p class="page-subtitle">Projects assigned to you</p>
      </div>
    </div>

    <!-- Status filter -->
    <div class="flex gap-2 flex-wrap mb-5">
      <button
        v-for="tab in tabs"
        :key="tab"
        @click="activeTab = tab"
        class="px-3 py-1.5 rounded-full text-sm font-medium transition-all duration-200"
        :class="activeTab === tab ? 'bg-primary-600 text-white' : 'bg-white text-gray-600 border border-gray-200 hover:border-primary-300'"
      >
        {{ tab }}
      </button>
    </div>

    <LoadingSpinner v-if="loading" text="Loading your projects..." />

    <div v-else-if="!filteredProjects.length" class="empty-state">
      <div class="empty-state-icon">📁</div>
      <p class="font-medium text-gray-700">No {{ activeTab === 'All' ? '' : activeTab.toLowerCase() + ' ' }}projects</p>
      <p class="text-sm text-gray-400 mt-1">You will see projects here once assigned by admin</p>
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
      <div
        v-for="project in filteredProjects"
        :key="project.id"
        class="card card-body hover:shadow-md transition-shadow"
      >
        <!-- Project header -->
        <div class="flex items-start justify-between mb-3">
          <div class="w-10 h-10 bg-primary-100 rounded-xl flex items-center justify-center text-xl flex-shrink-0">📁</div>
          <StatusBadge :status="project.status" />
        </div>

        <h3 class="font-semibold text-gray-900 mb-1">{{ project.name }}</h3>
        <p class="text-sm text-gray-500 mb-3 line-clamp-2">{{ project.description || 'No description' }}</p>

        <div class="flex items-center gap-2 text-xs text-gray-500 mb-4">
          <span>🏢 {{ project.client?.full_name }}</span>
          <span class="text-gray-300">•</span>
          <span>📅 {{ formatDate(project.created_at) }}</span>
        </div>

        <!-- Status update - employee can update status only -->
        <div class="pt-3 border-t border-gray-100">
          <label class="form-label text-xs">Update Status</label>
          <div class="flex gap-2">
            <select
              :value="project.status"
              @change="updateStatus(project, $event.target.value)"
              class="form-select flex-1 text-sm"
            >
              <option v-for="s in statuses" :key="s" :value="s">{{ s }}</option>
            </select>
          </div>
          <p class="text-xs text-gray-400 mt-1.5">⚠️ Only admin can reassign employees</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'
import { useToast } from 'vue-toastification'
import LoadingSpinner from '@/components/shared/LoadingSpinner.vue'
import StatusBadge from '@/components/shared/StatusBadge.vue'

const authStore = useAuthStore()
const toast = useToast()
const loading = ref(true)
const projects = ref([])
const activeTab = ref('All')

const tabs = ['All', 'Pending', 'In Progress', 'Completed', 'On Hold']
const statuses = ['Pending', 'In Progress', 'Completed', 'On Hold']

const filteredProjects = computed(() => {
  if (activeTab.value === 'All') return projects.value
  return projects.value.filter(p => p.status === activeTab.value)
})

onMounted(fetchProjects)

async function fetchProjects() {
  const { data } = await supabase
    .from('project_assignments')
    .select(`
      project:projects(
        id, name, description, status, created_at,
        client:profiles!projects_client_id_fkey(full_name)
      )
    `)
    .eq('employee_id', authStore.user.id)

  projects.value = data?.map(d => d.project).filter(Boolean) || []
  loading.value = false
}

async function updateStatus(project, newStatus) {
  try {
    const { error } = await supabase
      .from('projects')
      .update({ status: newStatus })
      .eq('id', project.id)
    if (error) throw error
    project.status = newStatus
    toast.success(`Status updated to "${newStatus}"`)
  } catch (err) {
    toast.error(err.message)
  }
}

function formatDate(ts) {
  return new Date(ts).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })
}
</script>
