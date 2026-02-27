<template>
  <div>
    <div class="page-header">
      <div>
        <h2 class="page-title">Services</h2>
        <p class="page-subtitle">Define the services your company offers</p>
      </div>
      <button @click="openCreateModal" class="btn-primary">
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
        </svg>
        Add Service
      </button>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
      <LoadingSpinner v-if="loading" class="col-span-3" text="Loading services..." />
      <div v-else-if="!services.length" class="col-span-3 empty-state">
        <div class="empty-state-icon">⚙️</div>
        <p class="font-medium text-gray-700">No services defined yet</p>
        <button @click="openCreateModal" class="btn-primary mt-4">Create Service</button>
      </div>
      <div
        v-for="service in services"
        :key="service.id"
        class="card card-body hover:shadow-md transition-shadow"
      >
        <div class="flex items-start justify-between mb-3">
          <div class="w-10 h-10 bg-primary-100 text-primary-700 rounded-xl flex items-center justify-center text-xl flex-shrink-0">
            ⚙️
          </div>
          <div class="flex gap-1">
            <button @click="openEditModal(service)" class="p-1.5 text-gray-400 hover:text-primary-600 hover:bg-primary-50 rounded-lg transition-colors">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
              </svg>
            </button>
            <button @click="confirmDelete(service)" class="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
            </button>
          </div>
        </div>
        <h3 class="font-semibold text-gray-900 mb-1">{{ service.name }}</h3>
        <p class="text-sm text-gray-500 mb-3 line-clamp-2">{{ service.description || 'No description provided' }}</p>
        <div class="flex items-center justify-between">
          <span class="text-lg font-bold text-primary-700">
            {{ service.price ? `₹${Number(service.price).toLocaleString('en-IN')}` : 'Custom pricing' }}
          </span>
          <span class="badge badge-green">Active</span>
        </div>
      </div>
    </div>

    <!-- Create/Edit Modal -->
    <AppModal :show="showModal" :title="editing ? 'Edit Service' : 'Add Service'" @close="closeModal">
      <form @submit.prevent="saveService" class="space-y-4">
        <div class="form-group">
          <label class="form-label">Service Name <span class="text-red-500">*</span></label>
          <input v-model="form.name" type="text" class="form-input" placeholder="E.g. Web Development" required />
        </div>
        <div class="form-group">
          <label class="form-label">Description</label>
          <textarea v-model="form.description" class="form-textarea" rows="3" placeholder="What does this service include?"></textarea>
        </div>
        <div class="form-group">
          <label class="form-label">Price (₹)</label>
          <input v-model="form.price" type="number" step="0.01" min="0" class="form-input" placeholder="Leave empty for custom pricing" />
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <button type="button" @click="closeModal" class="btn-secondary">Cancel</button>
          <button type="submit" class="btn-primary" :disabled="saving">
            <span v-if="saving" class="spinner w-4 h-4"></span>
            {{ editing ? 'Save Changes' : 'Create Service' }}
          </button>
        </div>
      </form>
    </AppModal>

    <!-- Delete Modal -->
    <AppModal :show="showDeleteModal" title="Delete Service" @close="showDeleteModal = false">
      <p class="text-gray-600 text-sm mb-4">Delete <strong>{{ deletingService?.name }}</strong>? Existing requests for this service won't be affected.</p>
      <div class="flex justify-end gap-3">
        <button @click="showDeleteModal = false" class="btn-secondary">Cancel</button>
        <button @click="deleteService" class="btn-danger" :disabled="saving">
          <span v-if="saving" class="spinner w-4 h-4"></span>
          Delete
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
const services = ref([])
const loading = ref(true)
const saving = ref(false)
const showModal = ref(false)
const showDeleteModal = ref(false)
const editing = ref(null)
const deletingService = ref(null)
const form = ref({ name: '', description: '', price: '' })

onMounted(fetchServices)

async function fetchServices() {
  loading.value = true
  const { data } = await supabase.from('services').select('*').order('name')
  services.value = data || []
  loading.value = false
}

function openCreateModal() { editing.value = null; form.value = { name: '', description: '', price: '' }; showModal.value = true }
function openEditModal(s) { editing.value = s; form.value = { name: s.name, description: s.description || '', price: s.price || '' }; showModal.value = true }
function closeModal() { showModal.value = false; editing.value = null }

async function saveService() {
  saving.value = true
  try {
    const payload = { ...form.value, price: form.value.price || null }
    if (editing.value) {
      await supabase.from('services').update(payload).eq('id', editing.value.id)
      toast.success('Service updated')
    } else {
      await supabase.from('services').insert(payload)
      toast.success('Service created')
    }
    closeModal(); await fetchServices()
  } catch (err) { toast.error(err.message) }
  finally { saving.value = false }
}

function confirmDelete(s) { deletingService.value = s; showDeleteModal.value = true }

async function deleteService() {
  saving.value = true
  try {
    await supabase.from('services').delete().eq('id', deletingService.value.id)
    toast.success('Service deleted')
    showDeleteModal.value = false; await fetchServices()
  } catch (err) { toast.error(err.message) }
  finally { saving.value = false }
}
</script>
