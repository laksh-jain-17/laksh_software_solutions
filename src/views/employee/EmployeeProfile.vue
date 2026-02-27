<template>
  <div class="max-w-2xl">
    <div class="page-header">
      <div>
        <h2 class="page-title">My Profile</h2>
        <p class="page-subtitle">Manage your employee account</p>
      </div>
    </div>

    <div class="card card-body">
      <div class="flex items-center gap-5 mb-8 pb-8 border-b border-gray-100">
        <div class="avatar w-20 h-20 text-2xl bg-emerald-100 text-emerald-700">{{ initials }}</div>
        <div>
          <h3 class="text-xl font-bold text-gray-900">{{ authStore.profile?.full_name }}</h3>
          <p class="text-gray-500">{{ authStore.profile?.email }}</p>
          <span class="badge badge-green mt-1">EMPLOYEE</span>
        </div>
      </div>

      <form @submit.prevent="saveProfile" class="space-y-5">
        <div class="form-group">
          <label class="form-label">Full Name</label>
          <input v-model="form.full_name" type="text" class="form-input" />
        </div>
        <div class="form-group">
          <label class="form-label">Email Address</label>
          <input :value="authStore.profile?.email" type="email" class="form-input bg-gray-50 cursor-not-allowed" disabled />
        </div>
        <div class="pt-2">
          <button type="submit" class="btn-primary" :disabled="saving">
            <span v-if="saving" class="spinner w-4 h-4"></span>
            Save Changes
          </button>
        </div>
      </form>
    </div>

    <div class="card card-body mt-4">
      <h3 class="font-semibold text-gray-900 mb-4">Security</h3>
      <div class="flex items-center justify-between p-4 bg-gray-50 rounded-xl">
        <div>
          <p class="font-medium text-gray-900">Password</p>
          <p class="text-sm text-gray-500">Update your login password</p>
        </div>
        <button @click="showPasswordModal = true" class="btn-secondary btn-sm">Change</button>
      </div>
    </div>
  </div>

  <AppModal :show="showPasswordModal" title="Change Password" @close="showPasswordModal = false">
    <form @submit.prevent="changePassword" class="space-y-4">
      <div class="form-group">
        <label class="form-label">New Password</label>
        <input v-model="passwordForm.password" type="password" class="form-input" minlength="8" required />
      </div>
      <div class="form-group">
        <label class="form-label">Confirm Password</label>
        <input v-model="passwordForm.confirm" type="password" class="form-input" required />
        <p v-if="passwordForm.confirm && passwordForm.password !== passwordForm.confirm" class="form-error">Passwords don't match</p>
      </div>
      <div class="flex justify-end gap-3 pt-2">
        <button type="button" @click="showPasswordModal = false" class="btn-secondary">Cancel</button>
        <button type="submit" class="btn-primary" :disabled="saving || passwordForm.password !== passwordForm.confirm">
          <span v-if="saving" class="spinner w-4 h-4"></span>
          Update
        </button>
      </div>
    </form>
  </AppModal>
</template>

<script setup>
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'
import { useToast } from 'vue-toastification'
import AppModal from '@/components/shared/AppModal.vue'

const authStore = useAuthStore()
const toast = useToast()
const saving = ref(false)
const showPasswordModal = ref(false)
const form = ref({ full_name: authStore.profile?.full_name || '' })
const passwordForm = ref({ password: '', confirm: '' })

const initials = computed(() => {
  return authStore.profile?.full_name?.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2) || 'E'
})

async function saveProfile() {
  saving.value = true
  try {
    await authStore.updateProfile({ full_name: form.value.full_name })
    toast.success('Profile updated')
  } catch (err) {
    toast.error(err.message)
  } finally {
    saving.value = false
  }
}

async function changePassword() {
  saving.value = true
  try {
    const { error } = await supabase.auth.updateUser({ password: passwordForm.value.password })
    if (error) throw error
    toast.success('Password updated')
    showPasswordModal.value = false
    passwordForm.value = { password: '', confirm: '' }
  } catch (err) {
    toast.error(err.message)
  } finally {
    saving.value = false
  }
}
</script>
