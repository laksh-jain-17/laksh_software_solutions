<template>
  <div>
    <div class="page-header">
      <div>
        <h2 class="page-title">Service Requests</h2>
        <p class="page-subtitle">Review and approve client service requests</p>
      </div>
    </div>

    <!-- Tabs -->
    <div class="flex gap-1 mb-5 bg-gray-100 p-1 rounded-lg w-fit">
      <button
        v-for="tab in tabs"
        :key="tab.value"
        @click="activeTab = tab.value"
        class="px-4 py-2 rounded-md text-sm font-medium transition-all duration-200"
        :class="activeTab === tab.value ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-700'"
      >
        {{ tab.label }}
        <span
          v-if="tab.count > 0"
          class="ml-1.5 px-1.5 py-0.5 rounded-full text-xs"
          :class="activeTab === tab.value ? 'bg-primary-100 text-primary-700' : 'bg-gray-200 text-gray-600'"
        >{{ tab.count }}</span>
      </button>
    </div>

    <div class="card">
      <LoadingSpinner v-if="loading" text="Loading requests..." />
      <div v-else-if="!filteredRequests.length" class="empty-state">
        <div class="empty-state-icon">📋</div>
        <p class="font-medium text-gray-700">No {{ activeTab.toLowerCase() }} requests</p>
      </div>
      <div v-else class="divide-y divide-gray-50">
        <div
          v-for="req in filteredRequests"
          :key="req.id"
          class="p-5 hover:bg-gray-50 transition-colors"
        >
          <div class="flex items-start justify-between gap-4">
            <div class="flex-1">
              <div class="flex items-center gap-2 mb-1">
                <h3 class="font-semibold text-gray-900">{{ req.service?.name }}</h3>
                <StatusBadge :status="req.status" />
              </div>
              <p class="text-sm text-gray-500 mb-2">Requested by <span class="font-medium text-gray-700">{{ req.client?.full_name }}</span></p>
              <p v-if="req.message" class="text-sm text-gray-600 bg-gray-50 rounded-lg p-3 border border-gray-100">"{{ req.message }}"</p>
              <p class="text-xs text-gray-400 mt-2">{{ formatDate(req.created_at) }}</p>
            </div>
            <div v-if="req.status === 'Pending'" class="flex gap-2 flex-shrink-0">
              <button @click="openApproveModal(req)" class="btn-success btn-sm">
                ✓ Approve
              </button>
              <button @click="rejectRequest(req)" class="btn-danger btn-sm" :disabled="saving">
                ✗ Reject
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Approve + Create Project Modal -->
    <AppModal
      :show="showApproveModal"
      title="Approve Request & Create Project"
      subtitle="Approving will automatically create a project for this client"
      @close="showApproveModal = false"
      size="lg"
    >
      <form @submit.prevent="approveRequest" class="space-y-4">
        <div class="bg-primary-50 border border-primary-100 rounded-xl p-4 mb-2">
          <p class="text-sm font-medium text-primary-800">Service: {{ approvingRequest?.service?.name }}</p>
          <p class="text-sm text-primary-700">Client: {{ approvingRequest?.client?.full_name }}</p>
        </div>
        <div class="form-group">
          <label class="form-label">Project Name <span class="text-red-500">*</span></label>
          <input v-model="approveForm.name" type="text" class="form-input" required />
        </div>
        <div class="form-group">
          <label class="form-label">Project Description</label>
          <textarea v-model="approveForm.description" class="form-textarea" rows="3"></textarea>
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <button type="button" @click="showApproveModal = false" class="btn-secondary">Cancel</button>
          <button type="submit" class="btn-success" :disabled="saving">
            <span v-if="saving" class="spinner w-4 h-4"></span>
            Approve & Create Project
          </button>
        </div>
      </form>
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
const requests = ref([])
const loading = ref(true)
const saving = ref(false)
const showApproveModal = ref(false)
const approvingRequest = ref(null)
const activeTab = ref('Pending')

const approveForm = ref({ name: '', description: '' })

const tabs = computed(() => [
  { label: 'Pending', value: 'Pending', count: requests.value.filter(r => r.status === 'Pending').length },
  { label: 'Approved', value: 'Approved', count: 0 },
  { label: 'Rejected', value: 'Rejected', count: 0 },
])

const filteredRequests = computed(() =>
  requests.value.filter(r => r.status === activeTab.value)
)

onMounted(fetchRequests)

async function fetchRequests() {
  loading.value = true
  const { data } = await supabase
    .from('service_requests')
    .select(`
      *,
      service:services(name, price),
      client:profiles!service_requests_client_id_fkey(id, full_name)
    `)
    .order('created_at', { ascending: false })
  requests.value = data || []
  loading.value = false
}

function openApproveModal(req) {
  approvingRequest.value = req
  approveForm.value = {
    name: `${req.service?.name} - ${req.client?.full_name}`,
    description: req.message || ''
  }
  showApproveModal.value = true
}

async function approveRequest() {
  saving.value = true
  try {
    // 1. Update request status
    const { error: reqErr } = await supabase
      .from('service_requests')
      .update({ status: 'Approved' })
      .eq('id', approvingRequest.value.id)
    if (reqErr) throw reqErr

    // 2. Create project
    const { error: projErr } = await supabase.from('projects').insert({
      name: approveForm.value.name,
      description: approveForm.value.description,
      client_id: approvingRequest.value.client_id,
      service_id: approvingRequest.value.service_id,
      service_request_id: approvingRequest.value.id,
      status: 'Pending'
    })
    if (projErr) throw projErr

    toast.success('Request approved and project created! 🎉')
    showApproveModal.value = false
    await fetchRequests()
  } catch (err) {
    toast.error(err.message)
  } finally {
    saving.value = false
  }
}

async function rejectRequest(req) {
  saving.value = true
  try {
    await supabase.from('service_requests').update({ status: 'Rejected' }).eq('id', req.id)
    toast.success('Request rejected')
    await fetchRequests()
  } catch (err) {
    toast.error(err.message)
  } finally {
    saving.value = false
  }
}

function formatDate(ts) {
  return new Date(ts).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' })
}
</script>
