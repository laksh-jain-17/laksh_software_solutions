import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null)
  const profile = ref(null)
  const loading = ref(true)

  const isAdmin = computed(() => profile.value?.role === 'ADMIN')
  const isEmployee = computed(() => profile.value?.role === 'EMPLOYEE')
  const isClient = computed(() => profile.value?.role === 'CLIENT')
  const role = computed(() => profile.value?.role)
  const isAuthenticated = computed(() => !!user.value)

  async function fetchProfile(userId) {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single()

    if (error) {
      console.error('Error fetching profile:', error)
      return null
    }
    profile.value = data
    return data
  }

  async function initialize() {
    loading.value = true
    try {
      const { data: { session } } = await supabase.auth.getSession()
      if (session?.user) {
        user.value = session.user
        await fetchProfile(session.user.id)
      }
    } catch (e) {
      console.error('Auth init error:', e)
    } finally {
      loading.value = false
    }

    // Listen for auth changes
    supabase.auth.onAuthStateChange(async (event, session) => {
      if (event === 'SIGNED_IN' && session?.user) {
        user.value = session.user
        await fetchProfile(session.user.id)
      } else if (event === 'SIGNED_OUT') {
        user.value = null
        profile.value = null
      }
    })
  }

  async function login(email, password) {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw error
    user.value = data.user
    await fetchProfile(data.user.id)
    return profile.value
  }

  async function logout() {
    await supabase.auth.signOut()
    user.value = null
    profile.value = null
  }

  async function updateProfile(updates) {
    const { data, error } = await supabase
      .from('profiles')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', user.value.id)
      .select()
      .single()

    if (error) throw error
    profile.value = data
    return data
  }

  return {
    user,
    profile,
    loading,
    isAdmin,
    isEmployee,
    isClient,
    role,
    isAuthenticated,
    initialize,
    login,
    logout,
    updateProfile,
    fetchProfile
  }
})
