-- =====================================================
-- Laksh Software Solutions - Complete Database Setup
-- Run this in your Supabase SQL Editor
-- =====================================================

-- 1. Create ENUM for user roles
CREATE TYPE user_role AS ENUM ('ADMIN', 'EMPLOYEE', 'CLIENT');

-- 2. Profiles table (synced with auth.users)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  full_name TEXT,
  email TEXT UNIQUE,
  role user_role DEFAULT 'CLIENT',
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Services table
CREATE TABLE services (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Service Requests table (client requests a service)
CREATE TABLE service_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  service_id INT REFERENCES services(id) ON DELETE SET NULL,
  status TEXT DEFAULT 'Pending' CHECK (status IN ('Pending', 'Approved', 'Rejected')),
  message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Projects table
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'Pending' CHECK (status IN ('Pending', 'In Progress', 'Completed', 'On Hold', 'Cancelled')),
  client_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  service_id INT REFERENCES services(id) ON DELETE SET NULL,
  service_request_id UUID REFERENCES service_requests(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Project Assignments (many-to-many: projects ↔ employees)
CREATE TABLE project_assignments (
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  employee_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  PRIMARY KEY (project_id, employee_id)
);

-- 7. Messages
CREATE TABLE messages (
  id SERIAL PRIMARY KEY,
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  receiver_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- TRIGGER: Auto-create profile on signup
-- =====================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'CLIENT')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- PROFILES POLICIES
CREATE POLICY "Authenticated users can view all profiles"
  ON profiles FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Admin can insert profiles"
  ON profiles FOR INSERT
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN')
  );

-- SERVICES POLICIES
CREATE POLICY "Authenticated can view services"
  ON services FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Admin can manage services"
  ON services FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN')
  );

-- SERVICE REQUESTS POLICIES
CREATE POLICY "Client can view own requests"
  ON service_requests FOR SELECT
  USING (client_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN'));

CREATE POLICY "Client can create requests"
  ON service_requests FOR INSERT
  WITH CHECK (client_id = auth.uid());

CREATE POLICY "Admin can update requests"
  ON service_requests FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN')
  );

-- PROJECTS POLICIES
CREATE POLICY "Admin can manage all projects"
  ON projects FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN')
  );

CREATE POLICY "Client sees own projects"
  ON projects FOR SELECT
  USING (client_id = auth.uid());

CREATE POLICY "Employee sees assigned projects"
  ON projects FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM project_assignments
      WHERE project_id = projects.id AND employee_id = auth.uid()
    )
  );

CREATE POLICY "Employee can update project status"
  ON projects FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM project_assignments
      WHERE project_id = projects.id AND employee_id = auth.uid()
    )
  );

-- PROJECT ASSIGNMENTS POLICIES
CREATE POLICY "Everyone can view assignments"
  ON project_assignments FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Admin can manage assignments"
  ON project_assignments FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN')
  );

-- MESSAGES POLICIES
CREATE POLICY "Users can see their own messages"
  ON messages FOR SELECT
  USING (sender_id = auth.uid() OR receiver_id = auth.uid());

CREATE POLICY "Users can send messages"
  ON messages FOR INSERT
  WITH CHECK (sender_id = auth.uid());

-- =====================================================
-- SEED DATA (Optional - update after creating admin user)
-- =====================================================

-- After creating admin via Supabase Auth Dashboard, run:
-- UPDATE profiles SET role = 'ADMIN' WHERE email = 'your-admin@email.com';

-- Sample services
INSERT INTO services (name, description, price) VALUES
  ('Web Development', 'Custom website and web application development using modern technologies.', 50000),
  ('Mobile App Development', 'iOS and Android app development for your business needs.', 80000),
  ('UI/UX Design', 'User interface and experience design with Figma prototyping.', 25000),
  ('SEO & Digital Marketing', 'Search engine optimization and digital marketing campaigns.', 15000),
  ('Cloud Infrastructure', 'AWS/GCP cloud setup, DevOps, and infrastructure management.', 40000),
  ('API Integration', 'Third-party API integration and backend development services.', 30000);
