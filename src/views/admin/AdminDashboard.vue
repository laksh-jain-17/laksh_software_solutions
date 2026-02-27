<template>
  <div>
    <!-- Stats grid -->
    <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4 mb-6">
      <div
        v-for="stat in stats"
        :key="stat.label"
        class="stat-card hover:shadow-md transition-shadow cursor-default"
      >
        <div class="stat-icon" :class="stat.iconBg">{{ stat.icon }}</div>
        <div class="flex-1">
          <p class="text-2xl font-bold text-gray-900">{{ loading ? '—' : stat.value }}</p>
          <p class="text-sm text-gray-500 mt-0.5">{{ stat.label }}</p>
          <div class="flex items-center gap-1 mt-2">
            <span class="text-xs font-medium" :class="stat.trendUp ? 'text-emerald-600' : 'text-gray-400'">
              {{ stat.trend }}
            </span>
          </div>
        </div>
      </div>
    </div>

    <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
      <!-- Recent Projects -->
      <div class="xl:col-span-2 card">
        <div class="card-header">
          <h3 class="font-semibold text-gray-900">Recent Projects</h3>
          <router-link to="/admin/projects" class="text-sm text-primary-600 hover:text-primary-700 font-medium">View all</router-link>
        </div>
        <div class="overflow-hidden">
          <LoadingSpinner v-if="loading" size="sm" text="Loading..." />
          <div v-else-if="!recentProjects.length" class="empty-state">
            <div class="empty-state-icon">📁</div>
            <p class="text-gray-500 font-medium">No projects yet</p>
          </div>
          <table v-else class="table">
            <thead>
              <tr>
                <th>Project</th>
                <th>Client</th>
                <th>Status</th>
                <th>Created</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="project in recentProjects" :key="project.id">
                <td>
                  <p class="font-medium text-gray-900">{{ project.name }}</p>
                  <p class="text-xs text-gray-400 mt-0.5 line-clamp-1">{{ project.description }}</p>
                </td>
                <td>{{ project.client?.full_name || '—' }}</td>
                <td><StatusBadge :status="project.status" /></td>
                <td>{{ formatDate(project.created_at) }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Right column -->
      <div class="space-y-5">
        <!-- Pending requests -->
        <div class="card">
          <div class="card-header">
            <h3 class="font-semibold text-gray-900">Pending Requests</h3>
            <router-link to="/admin/requests" class="text-sm text-primary-600 hover:text-primary-700 font-medium">View all</router-link>
          </div>
          <div class="divide-y divide-gray-50">
            <LoadingSpinner v-if="loading" size="sm" />
            <div v-else-if="!pendingRequests.length" class="p-6 text-center">
              <p class="text-gray-400 text-sm">No pending requests</p>
            </div>
            <div
              v-for="req in pendingRequests"
              :key="req.id"
              class="p-4 hover:bg-gray-50 transition-colors"
            >
              <p class="text-sm font-medium text-gray-900">{{ req.service?.name }}</p>
              <p class="text-xs text-gray-500 mt-0.5">by {{ req.client?.full_name }}</p>
              <div class="flex items-center justify-between mt-2">
                <span class="badge badge-yellow">Pending</span>
                <router-link to="/admin/requests" class="text-xs text-primary-600 hover:underline">Review →</router-link>
              </div>
            </div>
          </div>
        </div>

        <!-- Quick actions -->
        <div class="card card-body">
          <h3 class="font-semibold text-gray-900 mb-3">Quick Actions</h3>
          <div class="space-y-2">
            <router-link to="/admin/employees" class="flex items-center gap-3 p-3 rounded-lg hover:bg-gray-50 transition-colors group">
              <span class="text-lg">👥</span>
              <span class="text-sm font-medium text-gray-700 group-hover:text-primary-700">Add Employee</span>
            </router-link>
            <router-link to="/admin/clients" class="flex items-center gap-3 p-3 rounded-lg hover:bg-gray-50 transition-colors group">
              <span class="text-lg">🏢</span>
              <span class="text-sm font-medium text-gray-700 group-hover:text-primary-700">Add Client</span>
            </router-link>
            <router-link to="/admin/projects" class="flex items-center gap-3 p-3 rounded-lg hover:bg-gray-50 transition-colors group">
              <span class="text-lg">📁</span>
              <span class="text-sm font-medium text-gray-700 group-hover:text-primary-700">Create Project</span>
            </router-link>
            <router-link to="/admin/services" class="flex items-center gap-3 p-3 rounded-lg hover:bg-gray-50 transition-colors group">
              <span class="text-lg">⚙️</span>
              <span class="text-sm font-medium text-gray-700 group-hover:text-primary-700">Add Service</span>
            </router-link>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import LoadingSpinner from '@/components/shared/LoadingSpinner.vue'
import StatusBadge from '@/components/shared/StatusBadge.vue'

const loading = ref(true)
const recentProjects = ref([])
const pendingRequests = ref([])

const stats = ref([
  { label: 'Total Employees', icon: '👥', value: 0, iconBg: 'bg-blue-100', trend: 'Active staff', trendUp: true },
  { label: 'Active Projects', icon: '📁', value: 0, iconBg: 'bg-emerald-100', trend: 'In progress', trendUp: true },
  { label: 'Clients', icon: '🏢', value: 0, iconBg: 'bg-purple-100', trend: 'Registered', trendUp: true },
  { label: 'Pending Requests', icon: '📋', value: 0, iconBg: 'bg-amber-100', trend: 'Awaiting review', trendUp: false },
])

onMounted(async () => {
  await Promise.all([fetchStats(), fetchRecentProjects(), fetchPendingRequests()])
  loading.value = false
})

async function fetchStats() {
  const [emp, proj, clients, requests] = await Promise.all([
    supabase.from('profiles').select('id', { count: 'exact' }).eq('role', 'EMPLOYEE'),
    supabase.from('projects').select('id', { count: 'exact' }).neq('status', 'Completed'),
    supabase.from('profiles').select('id', { count: 'exact' }).eq('role', 'CLIENT'),
    supabase.from('service_requests').select('id', { count: 'exact' }).eq('status', 'Pending'),
  ])

  stats.value[0].value = emp.count || 0
  stats.value[1].value = proj.count || 0
  stats.value[2].value = clients.count || 0
  stats.value[3].value = requests.count || 0
}

async function fetchRecentProjects() {
  const { data } = await supabase
    .from('projects')
    .select('*, client:profiles!projects_client_id_fkey(full_name)')
    .order('created_at', { ascending: false })
    .limit(5)
  recentProjects.value = data || []
}

async function fetchPendingRequests() {
  const { data } = await supabase
    .from('service_requests')
    .select('*, service:services(name), client:profiles!service_requests_client_id_fkey(full_name)')
    .eq('status', 'Pending')
    .order('created_at', { ascending: false })
    .limit(5)
  pendingRequests.value = data || []
}

function formatDate(ts) {
  return new Date(ts).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })
}
</script>
