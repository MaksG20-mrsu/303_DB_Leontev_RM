PRAGMA foreign_keys = ON;

-- =========================
-- Таблица сотрудников
-- =========================
CREATE TABLE IF NOT EXISTS employees (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    last_name       TEXT    NOT NULL,
    first_name      TEXT    NOT NULL,
    middle_name     TEXT,
    phone           TEXT,
    email           TEXT,
    position        TEXT    NOT NULL DEFAULT 'master',
    salary_percent  REAL    NOT NULL DEFAULT 20.0
                            CHECK (salary_percent >= 0 AND salary_percent <= 100),
    hire_date       TEXT    NOT NULL DEFAULT (date('now')),
    fire_date       TEXT,
    is_active       INTEGER NOT NULL DEFAULT 1
                            CHECK (is_active IN (0, 1))
);

-- =========================
-- Таблица услуг
-- =========================
CREATE TABLE IF NOT EXISTS services (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    name            TEXT    NOT NULL UNIQUE,
    description     TEXT,
    duration_min    INTEGER NOT NULL
                            CHECK (duration_min > 0 AND duration_min <= 480),
    price           REAL    NOT NULL
                            CHECK (price >= 0),
    is_active       INTEGER NOT NULL DEFAULT 1
                            CHECK (is_active IN (0, 1))
);

-- =========================
-- Таблица клиентов
-- =========================
CREATE TABLE IF NOT EXISTS customers (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name   TEXT    NOT NULL,
    phone       TEXT,
    email       TEXT
);

-- =========================
-- Таблица автомобилей
-- =========================
CREATE TABLE IF NOT EXISTS cars (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_id     INTEGER NOT NULL,
    license_plate   TEXT    NOT NULL UNIQUE,
    brand           TEXT,
    model           TEXT,
    year            INTEGER CHECK (year BETWEEN 1900 AND 2100),
    FOREIGN KEY (customer_id) REFERENCES customers(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- =========================
-- Таблица графика работы мастеров
-- =========================
CREATE TABLE IF NOT EXISTS work_schedules (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    employee_id     INTEGER NOT NULL,
    work_date       TEXT    NOT NULL,      -- 'YYYY-MM-DD'
    start_time      TEXT    NOT NULL,      -- 'HH:MM'
    end_time        TEXT    NOT NULL,      -- 'HH:MM'
    FOREIGN KEY (employee_id) REFERENCES employees(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CHECK (end_time > start_time),
    UNIQUE (employee_id, work_date, start_time)
);

-- =========================
-- Таблица заказов / записей
-- =========================
CREATE TABLE IF NOT EXISTS work_orders (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    car_id          INTEGER NOT NULL,
    employee_id     INTEGER NOT NULL,
    planned_start   TEXT    NOT NULL,   -- 'YYYY-MM-DD HH:MM'
    planned_end     TEXT,
    status          TEXT    NOT NULL DEFAULT 'planned'
                            CHECK (status IN ('planned','in_progress','done','cancelled')),
    created_at      TEXT    NOT NULL DEFAULT (datetime('now')),
    closed_at       TEXT,
    total_amount    REAL    NOT NULL DEFAULT 0
                            CHECK (total_amount >= 0),
    notes           TEXT,
    FOREIGN KEY (car_id) REFERENCES cars(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES employees(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- =========================
-- Таблица услуг в заказе (M:N)
-- =========================
CREATE TABLE IF NOT EXISTS work_order_services (
    work_order_id   INTEGER NOT NULL,
    service_id      INTEGER NOT NULL,
    quantity        INTEGER NOT NULL DEFAULT 1
                            CHECK (quantity > 0),
    unit_price      REAL    NOT NULL
                            CHECK (unit_price >= 0),
    line_total      REAL    NOT NULL
                            CHECK (line_total >= 0),
    PRIMARY KEY (work_order_id, service_id),
    FOREIGN KEY (work_order_id) REFERENCES work_orders(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- ===========================================
-- Тестовые данные
-- ===========================================

-- Сотрудники
INSERT INTO employees (last_name, first_name, middle_name, phone, email, position, salary_percent, hire_date, fire_date, is_active)
VALUES
('Иванов', 'Пётр', 'Сергеевич', '+79990000001', 'ivanov@example.com', 'master', 25.0, '2022-01-10', NULL, 1),
('Сидоров', 'Алексей', 'Игоревич', '+79990000002', 'sidorov@example.com', 'master', 30.0, '2021-05-15', NULL, 1),
('Павлова', 'Мария', 'Олеговна', '+79990000003', 'pavlova@example.com', 'master', 28.0, '2019-03-01', '2024-06-30', 0); -- уволенный мастер

-- Услуги
INSERT INTO services (name, description, duration_min, price, is_active)
VALUES
('Диагностика подвески', 'Проверка элементов подвески автомобиля', 60, 2500, 1),
('Замена масла', 'Замена моторного масла и масляного фильтра', 45, 1800, 1),
('Развал-схождение', 'Регулировка углов установки колёс', 90, 3200, 1),
('Мойка кузова', 'Стандартная мойка кузова', 30, 700, 1);

-- Клиенты
INSERT INTO customers (full_name, phone, email)
VALUES
('Петров Николай Андреевич', '+79991112233', 'petrov@example.com'),
('Смирнова Ольга Викторовна', '+79992223344', 'smirnova@example.com');

-- Автомобили
INSERT INTO cars (customer_id, license_plate, brand, model, year)
VALUES
(1, 'A123BC96', 'Toyota', 'Camry', 2018),
(1, 'E777KX96', 'Hyundai', 'Solaris', 2020),
(2, 'M555TT96', 'Volkswagen', 'Polo', 2019);

-- График работы мастеров
INSERT INTO work_schedules (employee_id, work_date, start_time, end_time)
VALUES
(1, '2025-12-04', '09:00', '18:00'),
(2, '2025-12-04', '10:00', '19:00'),
(1, '2025-12-05', '09:00', '18:00'),
(3, '2024-06-15', '09:00', '17:00'); -- день из прошлого уволенного мастера

-- Заказы (часть — запланированные, часть — выполненные)
INSERT INTO work_orders (car_id, employee_id, planned_start, planned_end, status, created_at, closed_at, total_amount, notes)
VALUES
-- предстоящая запись
(1, 1, '2025-12-04 10:00', '2025-12-04 11:30', 'planned', '2025-12-03 12:00', NULL, 0, 'Предварительная запись на диагностику и замену масла'),
-- уже выполненный заказ
(2, 2, '2025-11-28 15:00', '2025-11-28 17:00', 'done', '2025-11-27 16:20', '2025-11-28 17:10', 4300, 'Выполнены работы без замечаний'),
-- старый заказ уволенного мастера
(3, 3, '2024-06-15 10:00', '2024-06-15 12:00', 'done', '2024-06-10 10:00', '2024-06-15 12:05', 5700, 'Работа у бывшего сотрудника');

-- Привязка услуг к заказам
-- Заказ 1 (пока planned) – диагностика + замена масла
INSERT INTO work_order_services (work_order_id, service_id, quantity, unit_price, line_total)
VALUES
(1, 1, 1, 2500, 2500), -- Диагностика подвески
(1, 2, 1, 1800, 1800); -- Замена масла

-- Заказ 2 (done) – развал-схождение
INSERT INTO work_order_services (work_order_id, service_id, quantity, unit_price, line_total)
VALUES
(2, 3, 1, 3200, 3200),
(2, 4, 1, 1100, 1100);

-- Заказ 3 (старый, уволенный мастер) – несколько услуг
INSERT INTO work_order_services (work_order_id, service_id, quantity, unit_price, line_total)
VALUES
(3, 2, 1, 1800, 1800),
(3, 3, 1, 3200, 3200),
(3, 4, 1, 700, 700);