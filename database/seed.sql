USE simk;

-- Password: admin123 / kasir123 / produksi123 (bcrypt cost 10)
INSERT INTO users (name, email, password, role) VALUES
('Administrator', 'admin@simk.id', '$2y$10$3ozJhPr9F.2vOEAOL54NNOv1kTELdciUmb/gtqzHDUNtb2x/oaKKe', 'admin'),
('Budi Santoso', 'kasir@simk.id', '$2y$10$jIdy6sCr5Z03bouypATjh.h95XN/8HKsxQhXOtKhx6O3qaQrzlk/y', 'kasir'),
('Siti Aminah', 'produksi@simk.id', '$2y$10$y5u0zSqKuDd8m5p5CDPsYeEfWJ5tICJS5r1ZxaQN0SpfsCswbHSpq', 'staff_produksi');

INSERT INTO customers (name, phone, email, address) VALUES
('PT Maju Jaya', '081234567890', 'info@majujaya.com', 'Jl. Sudirman No. 10'),
('Ibu Dewi', '081298765432', '', 'Perumahan Green Valley Blok A5'),
('Kantor BPKAD', '0274123456', 'bpkad@go.id', 'Jl. Pemuda No. 1'),
('Pak Hartono', '085612345678', '', 'Jl. Merdeka No. 25');

INSERT INTO recipe_categories (name, description) VALUES
('Menu Utama', 'Hidangan utama katering'),
('Snack', 'Camilan dan kue'),
('Minuman', 'Minuman segar');

INSERT INTO recipes (category_id, name, description, price, servings) VALUES
(1, 'Nasi Box Ayam Bakar', 'Nasi box dengan ayam bakar', 35000, 1),
(1, 'Nasi Box Ikan Goreng', 'Nasi box dengan ikan goreng', 38000, 1),
(1, 'Prasmanan Nasi Kuning', 'Prasmanan nasi kuning lengkap', 45000, 1),
(2, 'Kue Tart Coklat', 'Tart coklat ukuran sedang', 250000, 20),
(3, 'Es Teh Manis', 'Es teh manis segar', 5000, 1);

INSERT INTO ingredients (name, unit, stock, min_stock, price) VALUES
('Beras', 'kg', 50, 20, 12000),
('Ayam Potong', 'kg', 15, 10, 35000),
('Ikan Kakap', 'kg', 8, 10, 55000),
('Minyak Goreng', 'liter', 25, 10, 18000),
('Gula Pasir', 'kg', 5, 8, 14000),
('Telur', 'kg', 12, 5, 28000);

INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity) VALUES
(1, 1, 0.2), (1, 2, 0.15), (1, 4, 0.05),
(2, 1, 0.2), (2, 3, 0.12), (2, 4, 0.06),
(3, 1, 0.25), (3, 2, 0.1);

INSERT INTO recipe_steps (recipe_id, step_number, instruction) VALUES
(1, 1, 'Masak beras hingga matang'),
(1, 2, 'Bakar ayam dengan bumbu'),
(1, 3, 'Sajikan dalam box');

INSERT INTO orders (order_number, customer_id, status, total_amount, payment_status, order_date) VALUES
('ORD-20240610-001', 1, 'inProduction', 2000000, 'paid', '2024-06-10 08:30:00'),
('ORD-20240610-002', 2, 'confirmed', 500000, 'pending', '2024-06-10 10:15:00'),
('ORD-20240609-003', 3, 'ready', 4500000, 'paid', '2024-06-09 14:00:00');

INSERT INTO order_items (order_id, recipe_id, portions, price, subtotal) VALUES
(1, 1, 50, 35000, 1750000), (1, 5, 50, 5000, 250000),
(2, 4, 2, 250000, 500000),
(3, 3, 100, 45000, 4500000);

INSERT INTO production_schedules (order_id, recipe_name, portions, scheduled_date, status, assigned_to) VALUES
(1, 'Nasi Box Ayam Bakar', 50, '2024-06-10 06:00:00', 'in_progress', 'Siti Aminah'),
(2, 'Kue Tart Coklat', 2, '2024-06-10 07:00:00', 'scheduled', 'Siti Aminah'),
(3, 'Prasmanan Nasi Kuning', 100, '2024-06-09 05:00:00', 'completed', 'Siti Aminah');

INSERT INTO payments (order_id, amount, method, status, paid_at) VALUES
(1, 2000000, 'Transfer Bank', 'confirmed', '2024-06-10 09:00:00'),
(3, 4500000, 'Transfer Bank', 'confirmed', '2024-06-09 15:30:00');
