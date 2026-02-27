# Laksh Software Solutions 🚀

A full-featured **role-based company management portal** built with Vue 3 + Supabase.

**Live Demo → [lakshsoftwaresolutions.vercel.app](https://lakshsoftwaresolutions.vercel.app)**

![Dashboard Preview](https://placehold.co/900x450/2563eb/white?text=Laksh+Software+Solutions)

---

## 🔑 Test Login Credentials

| Role | Email | Password |
|------|-------|----------|
| **Admin** | admin@laksh.dev | Admin@123 |
| **Employee** | emp@laksh.dev | Emp@123 |
| **Client** | client@laksh.dev | Client@123 |

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Vue 3 (Composition API + `<script setup>`) |
| **State Management** | Pinia |
| **Routing** | Vue Router 4 (with navigation guards) |
| **Styling** | Tailwind CSS v3 |
| **Backend / Auth / DB** | Supabase (PostgreSQL + Auth + RLS) |
| **Build Tool** | Vite |
| **Deployment** | Vercel (frontend) + Supabase Cloud (backend) |

---

## ✨ Features

### 🔑 Authentication
- Email/password login via Supabase Auth
- Role-based access control: **Admin**, **Employee**, **Client**
- Automatic redirect to the correct portal after login
- Route guards prevent unauthorized access

### 👨‍💼 Admin Portal
- **Dashboard** — Live stats: employees, projects, clients, pending requests
- **Employees** — Create, edit, remove employee accounts
- **Clients** — Create, edit, remove client accounts
- **Projects** — Create, update, delete projects; assign/unassign employees
- **Services** — Define company services with pricing
- **Service Requests** — Review pending client requests; approve creates a project automatically
- **Messages** — Chat with any employee or client
- **User Management** — View all users with role filter
- **Profile** — Edit name, change password

### 👨‍💻 Employee Portal
- **Dashboard** — Summary of assigned projects by status
- **My Projects** — View all assigned projects; update project status
- ⚠️ Employees **cannot** unassign themselves from projects
- **Messages** — Chat with admin and project clients
- **Profile** — Edit name, change password

### 🏢 Client Portal
- **Dashboard** — Project overview and pending request count
- **My Projects** — View projects with assigned team members and status
- **Request Service** — Browse available services and submit requests
- **Messages** — Chat with admin and assigned employees
- **Profile** — Edit name, change password

### 💬 Messaging
- Simple non-realtime messaging between all roles
- Admin ↔ Employee, Admin ↔ Client, Client ↔ Employee
- Contact list filtered by role and project relationships

---

## 🗄 Database Schema

```
profiles          — user accounts (id synced with auth.users)
services          — company services catalog
service_requests  — client service requests (Pending → Approved/Rejected)
projects          — projects (created when admin approves a request)
project_assignments — many-to-many: employees assigned to projects
messages          — messages between any two users
```

All tables are protected with **Row Level Security (RLS)** policies:
- Clients only see their own projects and requests
- Employees only see projects they're assigned to
- Only admins can create/update/delete users, projects, services

---

## 🚀 Setup Instructions

### Prerequisites
- Node.js 18+
- A [Supabase](https://supabase.com) account (free tier works)

### 1. Clone the repository
```bash
git clone https://github.com/laksh-jain-17/laksh_software_solutions.git
cd laksh_software_solutions
```

### 2. Install dependencies
```bash
npm install
```

### 3. Set up Supabase

1. Create a new project on [supabase.com](https://supabase.com)
2. Go to **SQL Editor** → run the migration file:
   ```
   supabase/migrations/001_initial_schema.sql
   ```
3. Go to **Project Settings → API** and copy:
   - **Project URL**
   - **anon/public key**

### 4. Configure environment variables
```bash
cp .env.example .env
```

Edit `.env`:
```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

### 5. Create the admin user

In Supabase Dashboard → **Authentication → Users → Add user**:
- Email: `admin@laksh.dev`
- Password: `Admin@123`
- Auto-confirm: ✅

Then in SQL Editor:
```sql
UPDATE profiles SET role = 'ADMIN', full_name = 'Laksh Admin'
WHERE email = 'admin@laksh.dev';
```

### 6. Create employee & client users

Login as admin and use the **Employees** and **Clients** pages to create users. Or manually via Supabase Auth Dashboard.

### 7. Run the app
```bash
npm run dev
```

Visit: `http://localhost:5173`

---

## 📦 Build for Production
```bash
npm run build
```

## 🌐 Deploy to Vercel

1. Push to GitHub
2. Import repo on [vercel.com](https://vercel.com)
3. Set environment variables in Vercel dashboard
4. Deploy!

---

## 📁 Project Structure

```
src/
├── assets/
│   └── main.css              # Tailwind + custom component styles
├── components/
│   └── shared/
│       ├── AppHeader.vue     # Top navigation bar
│       ├── AppModal.vue      # Reusable modal dialog
│       ├── AppSidebar.vue    # Collapsible sidebar with nav
│       ├── LoadingSpinner.vue
│       ├── MessagingPanel.vue # Chat UI used by all roles
│       └── StatusBadge.vue
├── lib/
│   └── supabase.js           # Supabase client initialization
├── router/
│   └── index.js              # Vue Router + role-based guards
├── stores/
│   └── auth.js               # Pinia auth store
└── views/
    ├── auth/
    │   └── LoginView.vue
    ├── admin/
    │   ├── AdminLayout.vue
    │   ├── AdminDashboard.vue
    │   ├── AdminEmployees.vue
    │   ├── AdminClients.vue
    │   ├── AdminProjects.vue
    │   ├── AdminServices.vue
    │   ├── AdminRequests.vue
    │   ├── AdminMessages.vue
    │   ├── AdminUsers.vue
    │   └── AdminProfile.vue
    ├── employee/
    │   ├── EmployeeLayout.vue
    │   ├── EmployeeDashboard.vue
    │   ├── EmployeeProjects.vue
    │   ├── EmployeeMessages.vue
    │   └── EmployeeProfile.vue
    └── client/
        ├── ClientLayout.vue
        ├── ClientDashboard.vue
        ├── ClientProjects.vue
        ├── ClientServices.vue
        ├── ClientMessages.vue
        └── ClientProfile.vue
```

---

## 🔒 Security Design

- **Supabase RLS policies** enforce data isolation at the database level — even if someone bypasses the frontend, they cannot access unauthorized data
- **Vue Router guards** redirect unauthenticated/unauthorized users immediately
- **Role stored in `profiles`** table, not just JWT metadata — tamper-proof
- **Admin-only user creation** via `supabase.auth.admin.createUser()` — clients/employees cannot self-register

---

## 💡 Architecture Decisions

1. **Vue 3 Composition API** — Modern, tree-shakeable, better TypeScript support
2. **Pinia** — Lighter than Vuex, better DevTools integration, TypeScript-first
3. **Supabase as full backend** — Eliminates need for a separate Express server; real-time capable
4. **Tailwind CSS** — Utility-first, no CSS conflicts, fast to build consistent UIs
5. **Component reuse** — `MessagingPanel`, `AppSidebar`, `AppModal` shared across all 3 roles

---

## 📸 Screenshots

*Admin Dashboard, Employee Projects, Client Service Request, Messaging*

---

Built with ❤️ by Laksh Jain
