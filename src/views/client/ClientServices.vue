<template>
  <div>
    <div class="page-header">
      <div>
        <h2 class="page-title">Request a Service</h2>
        <p class="page-subtitle">Browse our services and submit a request</p>
      </div>
    </div>

    <!-- Available Services -->
    <div class="mb-8">
      <h3 class="text-base font-semibold text-gray-700 mb-4">Available Services</h3>
      <LoadingSpinner v-if="loading" text="Loading services..." />
      <div v-else-if="!services.length" class="empty-state">
        <div class="empty-state-icon">⚙️</div>
        <p class="text-gray-500">No services available yet. Contact admin.</p>
      </div>
      <div v-else class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
        <div
          v-for="service in services"
          :key="service.id"
          class="card card-body cursor-pointer transition-all duration-200 hover:shadow-md"
          :class="selectedService?.id === service.id ? 'ring-2 ring-primary-500' : ''"
          @click="selectService(service)"
        >
          <div class="flex items-start justify-between mb-3">
            <div class="w-10 h-10 bg-primary-100 rounded-xl flex items-center justify-center text-xl">⚙️</div>
            <div v-if="selectedService?.id === service.id" class="w-5 h-5 bg-primary-600 rounded-full flex items-center justify-center">
              <svg class="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
              </svg>
            </div>
          </div>
          <h3 class="font-semibold text-gray-900 mb-1">{{ service.name }}</h3>
          <p class="text-sm text-gray-500 mb-3 line-clamp-2">{{ service.description }}</p>
          <p class="font-bold text-primary-700">
            {{ service.price ? `₹${Number(service.price).toLocaleString('en-IN')}` : 'Custom Pricing' }}
          </p>
        </div>
      </div>
    </div>

    <!-- Request form -->
    <div v-if="selectedService" class="card card-body max-w-xl">
      <h3 class="font-semibold text-gray-900 mb-1">Submit Request</h3>
      <p class="text-sm text-gray-500 mb-4">Service: <strong>{{ selectedService.name }}</strong></p>
      <form @submit.prevent="submitRequest" class="space-y-4">
        <div class="form-group">
          <label class="form-label">Additional Message (optional)</label>
          <textarea
            v-model="requestMessage"
            class="form-textarea"
            rows="3"
            placeholder="Describe your requirements, timeline, or any specific details..."
          ></textarea>
        </div>
        <div class="flex gap-3">
          <button type="button" @click="selectedService = null" class="btn-secondary">Cancel</button>
          <button type="submit" class="btn-primary" :disabled="saving">
            <span v-if="saving" class="spinner w-4 h-4"></span>
            Submit Request
          </button>
        </div>
      </form>
    </div>

    <!-- Past requests -->
    <div class="mt-8">
      <h3 class="text-base font-semibold text-gray-700 mb-4">My Requests</h3>
      <div class="card">
        <LoadingSpinner v-if="loading" size="sm" />
        <div v-else-if="!myRequests.length" class="p-8 text-center">
          <p class="text-gray-400 text-sm">No requests submitted yet</p>
        </div>
        <div v-else class="table-container">
          <table class="table">
            <thead>
              <tr>
                <th>Service</th>
                <th>Message</th>
                <th>Status</th>
                <th>Date</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="req in myRequests" :key="req.id">
                <td class="font-medium">{{ req.service?.name }}</td>
                <td class="text-gray-500 max-w-xs">
                  <p class="truncate">{{ req.message || '—' }}</p>
                </td>
                <td><StatusBadge :status="req.status" /></td>
                <td>{{ formatDate(req.created_at) }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'
import { useToast } from 'vue-toastification'
import LoadingSpinner from '@/components/shared/LoadingSpinner.vue'
import StatusBadge from '@/components/shared/StatusBadge.vue'

const authStore = useAuthStore()
const toast = useToast()
const loading = ref(true)
const saving = ref(false)
const services = ref([])
const myRequests = ref([])
const selectedService = ref(null)
const requestMessage = ref('')

onMounted(async () => {
  await Promise.all([fetchServices(), fetchMyRequests()])
  loading.value = false
})

async function fetchServices() {
  const { data } = await supabase.from('services').select('*').order('name')
  services.value = data || []
}

async function fetchMyRequests() {
  const { data } = await supabase
    .from('service_requests')
    .select('*, service:services(name)')
    .eq('client_id', authStore.user.id)
    .order('created_at', { ascending: false })
  myRequests.value = data || []
}

function selectService(service) {
  selectedService.value = selectedService.value?.id === service.id ? null : service
  requestMessage.value = ''
}

async function submitRequest() {
  saving.value = true
  try {
    const { error } = await supabase.from('service_requests').insert({
      client_id: authStore.user.id,
      service_id: selectedService.value.id,
      message: requestMessage.value || null,
      status: 'Pending',
    })
    if (error) throw error
    toast.success('Request submitted! Admin will review it shortly. 🎉')
    selectedService.value = null
    requestMessage.value = ''
    await fetchMyRequests()
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
