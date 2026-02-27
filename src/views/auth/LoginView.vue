<template>
  <div class="min-h-screen flex bg-gray-50">
    <!-- Left panel - branding -->
    <div class="hidden lg:flex lg:w-1/2 bg-gradient-to-br from-primary-700 via-primary-800 to-primary-900 flex-col justify-between p-12 relative overflow-hidden">
      <!-- Decorative circles -->
      <div class="absolute -top-20 -right-20 w-80 h-80 bg-white/5 rounded-full"></div>
      <div class="absolute -bottom-32 -left-20 w-96 h-96 bg-white/5 rounded-full"></div>
      <div class="absolute top-1/2 right-0 w-48 h-48 bg-white/5 rounded-full"></div>

      <!-- Logo -->
      <div class="relative z-10">
        <div class="flex items-center gap-3 mb-2">
          <div class="w-10 h-10 bg-white/20 rounded-xl flex items-center justify-center backdrop-blur-sm">
            <svg class="w-6 h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4" />
            </svg>
          </div>
          <span class="text-white font-bold text-xl">Laksh Software Solutions</span>
        </div>
        <p class="text-primary-300 text-sm">Company Management Portal</p>
      </div>

      <!-- Content -->
      <div class="relative z-10">
        <h1 class="text-4xl font-bold text-white mb-4 leading-tight">
          Manage your team<br/>& clients with ease
        </h1>
        <p class="text-primary-300 text-lg mb-10">
          A unified platform for admins, employees, and clients to collaborate seamlessly.
        </p>

        <!-- Features -->
        <div class="space-y-3">
          <div v-for="feat in features" :key="feat" class="flex items-center gap-3 text-primary-200">
            <div class="w-5 h-5 rounded-full bg-primary-500/40 flex items-center justify-center flex-shrink-0">
              <svg class="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
              </svg>
            </div>
            <span class="text-sm">{{ feat }}</span>
          </div>
        </div>
      </div>

      <!-- Bottom -->
      <div class="relative z-10">
        <p class="text-primary-400 text-xs">© 2025 Laksh Software Solutions. Built with Vue 3 + Supabase</p>
      </div>
    </div>

    <!-- Right panel - form -->
    <div class="w-full lg:w-1/2 flex items-center justify-center p-8">
      <div class="w-full max-w-md">
        <!-- Mobile logo -->
        <div class="lg:hidden flex items-center gap-2 mb-8">
          <div class="w-8 h-8 bg-primary-600 rounded-lg flex items-center justify-center">
            <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4" />
            </svg>
          </div>
          <span class="font-bold text-gray-900">Laksh Software Solutions</span>
        </div>

        <h2 class="text-2xl font-bold text-gray-900 mb-1">Welcome back 👋</h2>
        <p class="text-gray-500 text-sm mb-8">Sign in to your portal to continue</p>

        <form @submit.prevent="handleLogin" class="space-y-4">
          <div class="form-group">
            <label class="form-label">Email address</label>
            <input
              v-model="form.email"
              type="email"
              class="form-input"
              placeholder="you@example.com"
              autocomplete="email"
              required
            />
          </div>

          <div class="form-group">
            <label class="form-label">Password</label>
            <div class="relative">
              <input
                v-model="form.password"
                :type="showPassword ? 'text' : 'password'"
                class="form-input pr-10"
                placeholder="••••••••"
                autocomplete="current-password"
                required
              />
              <button
                type="button"
                @click="showPassword = !showPassword"
                class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
              >
                <svg v-if="!showPassword" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                </svg>
                <svg v-else class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                </svg>
              </button>
            </div>
          </div>

          <div v-if="error" class="bg-red-50 border border-red-200 rounded-lg px-4 py-3 text-sm text-red-700 flex items-start gap-2">
            <svg class="w-4 h-4 mt-0.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
            </svg>
            {{ error }}
          </div>

          <button type="submit" class="btn-primary w-full btn-lg" :disabled="loading">
            <span v-if="loading" class="spinner w-4 h-4"></span>
            <span>{{ loading ? 'Signing in...' : 'Sign in' }}</span>
          </button>
        </form>

        <!-- Demo credentials -->
        <div class="mt-8">
          <div class="relative flex items-center mb-4">
            <div class="flex-1 border-t border-gray-200"></div>
            <span class="px-3 text-xs text-gray-400 font-medium">DEMO CREDENTIALS</span>
            <div class="flex-1 border-t border-gray-200"></div>
          </div>

          <div class="grid grid-cols-3 gap-2">
            <button
              v-for="cred in demoCredentials"
              :key="cred.role"
              @click="fillDemo(cred)"
              class="flex flex-col items-center p-3 rounded-xl border-2 transition-all duration-200 hover:shadow-sm text-left"
              :class="[
                activeDemoRole === cred.role
                  ? 'border-primary-500 bg-primary-50'
                  : 'border-gray-100 hover:border-primary-200'
              ]"
            >
              <span class="text-xl mb-1">{{ cred.emoji }}</span>
              <span class="text-xs font-semibold text-gray-700">{{ cred.role }}</span>
              <span class="text-xs text-gray-400 truncate w-full text-center">{{ cred.label }}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useToast } from 'vue-toastification'

const router = useRouter()
const authStore = useAuthStore()
const toast = useToast()

const form = ref({ email: '', password: '' })
const loading = ref(false)
const error = ref('')
const showPassword = ref(false)
const activeDemoRole = ref('')

const features = [
  'Role-based access control for Admins, Employees & Clients',
  'Project management with employee assignment',
  'Service request workflow with approval system',
  'Real-time messaging between all roles',
  'Clean dashboard with key metrics'
]

const demoCredentials = [
  { role: 'Admin', emoji: '🔑', label: 'Full access', email: 'admin@laksh.dev', password: 'Admin@123' },
  { role: 'Employee', emoji: '👨‍💻', label: 'Dev portal', email: 'emp@laksh.dev', password: 'Emp@123' },
  { role: 'Client', emoji: '🏢', label: 'Client portal', email: 'client@laksh.dev', password: 'Client@123' },
]

function fillDemo(cred) {
  form.value.email = cred.email
  form.value.password = cred.password
  activeDemoRole.value = cred.role
  error.value = ''
}

async function handleLogin() {
  loading.value = true
  error.value = ''
  try {
    const profile = await authStore.login(form.value.email, form.value.password)
    toast.success(`Welcome back, ${profile.full_name || 'User'}! 👋`)

    const redirectMap = {
      ADMIN: '/admin/dashboard',
      EMPLOYEE: '/employee/dashboard',
      CLIENT: '/client/dashboard',
    }
    router.push(redirectMap[profile.role] || '/login')
  } catch (err) {
    error.value = err.message === 'Invalid login credentials'
      ? 'Invalid email or password. Please try again.'
      : err.message
  } finally {
    loading.value = false
  }
}
</script>
