import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

// Auth
import LoginView from '@/views/auth/LoginView.vue'

// Admin
import AdminLayout from '@/views/admin/AdminLayout.vue'
import AdminDashboard from '@/views/admin/AdminDashboard.vue'
import AdminEmployees from '@/views/admin/AdminEmployees.vue'
import AdminClients from '@/views/admin/AdminClients.vue'
import AdminProjects from '@/views/admin/AdminProjects.vue'
import AdminServices from '@/views/admin/AdminServices.vue'
import AdminRequests from '@/views/admin/AdminRequests.vue'
import AdminMessages from '@/views/admin/AdminMessages.vue'
import AdminUsers from '@/views/admin/AdminUsers.vue'
import AdminProfile from '@/views/admin/AdminProfile.vue'

// Employee
import EmployeeLayout from '@/views/employee/EmployeeLayout.vue'
import EmployeeDashboard from '@/views/employee/EmployeeDashboard.vue'
import EmployeeProjects from '@/views/employee/EmployeeProjects.vue'
import EmployeeMessages from '@/views/employee/EmployeeMessages.vue'
import EmployeeProfile from '@/views/employee/EmployeeProfile.vue'

// Client
import ClientLayout from '@/views/client/ClientLayout.vue'
import ClientDashboard from '@/views/client/ClientDashboard.vue'
import ClientProjects from '@/views/client/ClientProjects.vue'
import ClientServices from '@/views/client/ClientServices.vue'
import ClientMessages from '@/views/client/ClientMessages.vue'
import ClientProfile from '@/views/client/ClientProfile.vue'

const routes = [
  {
    path: '/',
    redirect: '/login'
  },
  {
    path: '/login',
    name: 'Login',
    component: LoginView,
    meta: { guest: true }
  },

  // Admin routes
  {
    path: '/admin',
    component: AdminLayout,
    meta: { requiresAuth: true, role: 'ADMIN' },
    children: [
      { path: '', redirect: '/admin/dashboard' },
      { path: 'dashboard', name: 'AdminDashboard', component: AdminDashboard },
      { path: 'employees', name: 'AdminEmployees', component: AdminEmployees },
      { path: 'clients', name: 'AdminClients', component: AdminClients },
      { path: 'projects', name: 'AdminProjects', component: AdminProjects },
      { path: 'services', name: 'AdminServices', component: AdminServices },
      { path: 'requests', name: 'AdminRequests', component: AdminRequests },
      { path: 'messages', name: 'AdminMessages', component: AdminMessages },
      { path: 'users', name: 'AdminUsers', component: AdminUsers },
      { path: 'profile', name: 'AdminProfile', component: AdminProfile },
    ]
  },

  // Employee routes
  {
    path: '/employee',
    component: EmployeeLayout,
    meta: { requiresAuth: true, role: 'EMPLOYEE' },
    children: [
      { path: '', redirect: '/employee/dashboard' },
      { path: 'dashboard', name: 'EmployeeDashboard', component: EmployeeDashboard },
      { path: 'projects', name: 'EmployeeProjects', component: EmployeeProjects },
      { path: 'messages', name: 'EmployeeMessages', component: EmployeeMessages },
      { path: 'profile', name: 'EmployeeProfile', component: EmployeeProfile },
    ]
  },

  // Client routes
  {
    path: '/client',
    component: ClientLayout,
    meta: { requiresAuth: true, role: 'CLIENT' },
    children: [
      { path: '', redirect: '/client/dashboard' },
      { path: 'dashboard', name: 'ClientDashboard', component: ClientDashboard },
      { path: 'projects', name: 'ClientProjects', component: ClientProjects },
      { path: 'services', name: 'ClientServices', component: ClientServices },
      { path: 'messages', name: 'ClientMessages', component: ClientMessages },
      { path: 'profile', name: 'ClientProfile', component: ClientProfile },
    ]
  },

  // Catch-all
  {
    path: '/:pathMatch(.*)*',
    redirect: '/login'
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior() {
    return { top: 0 }
  }
})

// Navigation guard
router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore()

  // Wait for initialization
  if (authStore.loading) {
    await authStore.initialize()
  }

  if (to.meta.requiresAuth) {
    if (!authStore.isAuthenticated) {
      return next('/login')
    }
    if (to.meta.role && authStore.role !== to.meta.role) {
      // Redirect to appropriate portal
      const roleRedirects = {
        ADMIN: '/admin/dashboard',
        EMPLOYEE: '/employee/dashboard',
        CLIENT: '/client/dashboard',
      }
      return next(roleRedirects[authStore.role] || '/login')
    }
  }

  if (to.meta.guest && authStore.isAuthenticated) {
    const roleRedirects = {
      ADMIN: '/admin/dashboard',
      EMPLOYEE: '/employee/dashboard',
      CLIENT: '/client/dashboard',
    }
    return next(roleRedirects[authStore.role] || '/login')
  }

  next()
})

export default router
