DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    CREATE TYPE user_role AS ENUM ('ADMIN', 'EMPLOYEE', 'CLIENT');
  END IF;
END$$;

CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  full_name TEXT,
  email TEXT UNIQUE,
  role user_role DEFAULT 'CLIENT',
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS services (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS service_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  service_id INT REFERENCES services(id) ON DELETE SET NULL,
  status TEXT DEFAULT 'Pending' CHECK (status IN ('Pending', 'Approved', 'Rejected')),
  message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'Pending' CHECK (status IN ('Pending', 'In Progress', 'Completed', 'On Hold', 'Cancelled')),
  client_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS project_assignments (
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  employee_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  PRIMARY KEY (project_id, employee_id)
);

CREATE TABLE IF NOT EXISTS messages (
  id SERIAL PRIMARY KEY,
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  receiver_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name='projects' AND column_name='service_id'
  ) THEN
    ALTER TABLE projects ADD COLUMN service_id INT REFERENCES services(id) ON DELETE SET NULL;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name='projects' AND column_name='service_request_id'
  ) THEN
    ALTER TABLE projects ADD COLUMN service_request_id UUID REFERENCES service_requests(id) ON DELETE SET NULL;
  END IF;
END$$;

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

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

ALTER TABLE profiles          ENABLE ROW LEVEL SECURITY;
ALTER TABLE services          ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_requests  ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects          ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages          ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT policyname, tablename FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('profiles','services','service_requests','projects','project_assignments','messages')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', r.policyname, r.tablename);
  END LOOP;
END$$;

CREATE POLICY "profiles_select" ON profiles FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "profiles_update_own" ON profiles FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

CREATE POLICY "services_select" ON services FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "services_admin_all" ON services FOR ALL
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN'))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN'));

CREATE POLICY "service_requests_select" ON service_requests FOR SELECT
  USING (client_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN'));
CREATE POLICY "service_requests_insert" ON service_requests FOR INSERT WITH CHECK (client_id = auth.uid());
CREATE POLICY "service_requests_update_admin" ON service_requests FOR UPDATE
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN'))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN'));

CREATE POLICY "projects_admin_all" ON projects FOR ALL
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN'))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN'));
CREATE POLICY "projects_client_select" ON projects FOR SELECT USING (client_id = auth.uid());
CREATE POLICY "projects_employee_select" ON projects FOR SELECT
  USING (EXISTS (SELECT 1 FROM project_assignments WHERE project_id = projects.id AND employee_id = auth.uid()));
CREATE POLICY "projects_employee_update" ON projects FOR UPDATE
  USING (EXISTS (SELECT 1 FROM project_assignments WHERE project_id = projects.id AND employee_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM project_assignments WHERE project_id = projects.id AND employee_id = auth.uid()));

CREATE POLICY "assignments_select" ON project_assignments FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "assignments_admin_all" ON project_assignments FOR ALL
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN'))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN'));

CREATE POLICY "messages_select" ON messages FOR SELECT USING (sender_id = auth.uid() OR receiver_id = auth.uid());
CREATE POLICY "messages_insert" ON messages FOR INSERT WITH CHECK (sender_id = auth.uid());

INSERT INTO services (name, description, price)
SELECT v.name, v.description, v.price
FROM (VALUES
  ('Web Development', 'Custom website and web application development using modern technologies.', 50000),
  ('Mobile App Development', 'iOS and Android app development for your business needs.', 80000),
  ('UI/UX Design', 'User interface and experience design with Figma prototyping.', 25000),
  ('SEO & Digital Marketing', 'Search engine optimization and digital marketing campaigns.', 15000),
  ('Cloud Infrastructure', 'AWS/GCP cloud setup, DevOps, and infrastructure management.', 40000),
  ('API Integration', 'Third-party API integration and backend development services.', 30000)
) AS v(name, description, price)
WHERE NOT EXISTS (SELECT 1 FROM services LIMIT 1);

SELECT 'Database setup complete! ✅' AS status;
