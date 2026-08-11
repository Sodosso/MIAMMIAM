-- ============================================================
-- Restaurant Database Schema
-- Upscale healthy-focused restaurant, Seattle area
-- Author: [Your Name]
-- ============================================================

DROP DATABASE IF EXISTS restaurant_db;
CREATE DATABASE restaurant_db;
USE restaurant_db;

-- ============================================================
-- LOOKUP TABLES
-- ============================================================

CREATE TABLE Positions (
    position_id     INT AUTO_INCREMENT PRIMARY KEY,
    title           VARCHAR(50)  NOT NULL,
    department      VARCHAR(50)  NOT NULL
);

CREATE TABLE Vendors (
    vendor_id       INT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    category        VARCHAR(50)  NOT NULL,
    contact_name    VARCHAR(100),
    phone           VARCHAR(20),
    email           VARCHAR(100)
);

CREATE TABLE Menu_Categories (
    category_id   INT AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(50) NOT NULL
);

CREATE TABLE Cuisines (
    cuisine_id    INT AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(50) NOT NULL
);

CREATE TABLE Dish_Styles (
    style_id      INT AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(50) NOT NULL
);

CREATE TABLE Ingredients (
    ingredient_id   INT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    unit            VARCHAR(20)  NOT NULL,
    allergen_flag   VARCHAR(50)
);

-- ============================================================
-- PEOPLE: EMPLOYEES (with EER specialization)
-- ============================================================

CREATE TABLE Employees (
    employee_id       INT AUTO_INCREMENT PRIMARY KEY,
    first_name        VARCHAR(50) NOT NULL,
    last_name         VARCHAR(50) NOT NULL,
    phone             VARCHAR(20),
    email             VARCHAR(100),
    hire_date         DATE NOT NULL,
    employment_status ENUM('full-time','part-time','on-call','temporary') NOT NULL,
    employee_category ENUM('direct','contractor') NOT NULL,
    position_id       INT NOT NULL,
    FOREIGN KEY (position_id) REFERENCES Positions(position_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE Direct_Employees (
    employee_id       INT PRIMARY KEY,
    salary_type       ENUM('hourly','salaried') NOT NULL,
    pay_rate          DECIMAL(8,2) NOT NULL,
    benefits_eligible BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE Contractors (
    employee_id       INT PRIMARY KEY,
    contract_company  VARCHAR(100) NOT NULL,
    contract_start    DATE NOT NULL,
    contract_end      DATE,
    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE Employee_Shifts (
    shift_id      INT AUTO_INCREMENT PRIMARY KEY,
    employee_id   INT NOT NULL,
    shift_date    DATE NOT NULL,
    start_time    TIME NOT NULL,
    end_time      TIME NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- ============================================================
-- CUSTOMERS & SEATING
-- ============================================================

CREATE TABLE Customers (
    customer_id          INT AUTO_INCREMENT PRIMARY KEY,
    first_name           VARCHAR(50) NOT NULL,
    last_name             VARCHAR(50) NOT NULL,
    phone                VARCHAR(20),
    email                VARCHAR(100),
    loyalty_signup_date  DATE
);

CREATE TABLE Restaurant_Tables (
    table_id         INT AUTO_INCREMENT PRIMARY KEY,
    table_number     INT NOT NULL,
    seating_capacity INT NOT NULL,
    section          VARCHAR(50) NOT NULL
);

CREATE TABLE Reservations (
    reservation_id    INT AUTO_INCREMENT PRIMARY KEY,
    customer_id       INT NOT NULL,
    table_id          INT NOT NULL,
    reservation_date  DATE NOT NULL,
    reservation_time  TIME NOT NULL,
    party_size        INT NOT NULL,
    status            ENUM('confirmed','seated','cancelled','no-show') NOT NULL DEFAULT 'confirmed',
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (table_id) REFERENCES Restaurant_Tables(table_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ============================================================
-- MENU (with category, cuisine, and style classification)
-- ============================================================

CREATE TABLE Menu_Items (
    menu_item_id  INT AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    category_id   INT NOT NULL,
    cuisine_id    INT NOT NULL,
    style_id      INT,
    price         DECIMAL(6,2) NOT NULL,
    description   TEXT,
    dietary_tags  VARCHAR(100),
    FOREIGN KEY (category_id) REFERENCES Menu_Categories(category_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (cuisine_id) REFERENCES Cuisines(cuisine_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (style_id) REFERENCES Dish_Styles(style_id)
        ON UPDATE CASCADE ON DELETE SET NULL
);

CREATE TABLE Recipe_Ingredients (
    menu_item_id   INT NOT NULL,
    ingredient_id  INT NOT NULL,
    quantity       DECIMAL(6,2) NOT NULL,
    PRIMARY KEY (menu_item_id, ingredient_id),
    FOREIGN KEY (menu_item_id) REFERENCES Menu_Items(menu_item_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES Ingredients(ingredient_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ============================================================
-- ORDERS
-- ============================================================

CREATE TABLE Orders (
    order_id      INT AUTO_INCREMENT PRIMARY KEY,
    customer_id   INT,
    table_id      INT NOT NULL,
    employee_id   INT NOT NULL,
    order_date    DATETIME NOT NULL,
    status        ENUM('open','in-progress','completed','cancelled') NOT NULL DEFAULT 'open',
    total_amount  DECIMAL(8,2) NOT NULL DEFAULT 0.00,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    FOREIGN KEY (table_id) REFERENCES Restaurant_Tables(table_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE Order_Items (
    order_id             INT NOT NULL,
    menu_item_id         INT NOT NULL,
    quantity             INT NOT NULL DEFAULT 1,
    subtotal             DECIMAL(8,2) NOT NULL,
    special_instructions VARCHAR(200),
    PRIMARY KEY (order_id, menu_item_id),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (menu_item_id) REFERENCES Menu_Items(menu_item_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ============================================================
-- DISCOUNTS, GIFT CARDS, PAYMENTS
-- ============================================================

CREATE TABLE Discounts (
    discount_id        INT AUTO_INCREMENT PRIMARY KEY,
    name               VARCHAR(100) NOT NULL,
    type               ENUM('promo','employee-meal','kitchen-error-comp','gift-card-redemption','loyalty') NOT NULL,
    amount_or_percent  DECIMAL(6,2) NOT NULL
);

CREATE TABLE Order_Discounts (
    order_id      INT NOT NULL,
    discount_id   INT NOT NULL,
    approved_by   INT,
    PRIMARY KEY (order_id, discount_id),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (discount_id) REFERENCES Discounts(discount_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (approved_by) REFERENCES Employees(employee_id)
        ON UPDATE CASCADE ON DELETE SET NULL
);

CREATE TABLE Gift_Cards (
    gift_card_id  INT AUTO_INCREMENT PRIMARY KEY,
    customer_id   INT,
    balance       DECIMAL(8,2) NOT NULL,
    issue_date    DATE NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
        ON UPDATE CASCADE ON DELETE SET NULL
);

CREATE TABLE Payments (
    payment_id      INT AUTO_INCREMENT PRIMARY KEY,
    order_id        INT NOT NULL,
    payment_method  ENUM('cash','card','gift-card','split') NOT NULL,
    amount          DECIMAL(8,2) NOT NULL,
    tip             DECIMAL(6,2) DEFAULT 0.00,
    gift_card_id    INT,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (gift_card_id) REFERENCES Gift_Cards(gift_card_id)
        ON UPDATE CASCADE ON DELETE SET NULL
);

-- ============================================================
-- VENDORS / SUPPLIES / EXPENSES
-- ============================================================

CREATE TABLE Supplies (
    supply_id   INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    unit        VARCHAR(20)  NOT NULL,
    vendor_id   INT NOT NULL,
    FOREIGN KEY (vendor_id) REFERENCES Vendors(vendor_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE Expenses (
    expense_id    INT AUTO_INCREMENT PRIMARY KEY,
    category      ENUM('payroll','rent','utilities','supplies','marketing','other') NOT NULL,
    amount        DECIMAL(10,2) NOT NULL,
    expense_date  DATE NOT NULL,
    vendor_id     INT,
    FOREIGN KEY (vendor_id) REFERENCES Vendors(vendor_id)
        ON UPDATE CASCADE ON DELETE SET NULL
);
