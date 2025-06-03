-- -------------------------------------------------------------
-- Library Management System - Full MySQL Script (Project 2)
-- -------------------------------------------------------------

-- Drop existing tables to avoid FK dependency issues
DROP TABLE IF EXISTS return_status;
DROP TABLE IF EXISTS issued_status;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS members;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS branch;

-- ----------------------
-- Table Definitions
-- ----------------------

-- Branch Table
CREATE TABLE branch (
    branch_id VARCHAR(10) PRIMARY KEY,
    manager_id VARCHAR(10),
    branch_address VARCHAR(30),
    contact_no VARCHAR(15)
);

-- Employees Table
CREATE TABLE employees (
    emp_id VARCHAR(10) PRIMARY KEY,
    emp_name VARCHAR(30),
    position VARCHAR(30),
    salary DECIMAL(10,2),
    branch_id VARCHAR(10),
    FOREIGN KEY (branch_id) REFERENCES branch(branch_id)
);

-- Members Table
CREATE TABLE members (
    member_id VARCHAR(10) PRIMARY KEY,
    member_name VARCHAR(30),
    member_address VARCHAR(30),
    reg_date DATE
);

-- Books Table
CREATE TABLE books (
    isbn VARCHAR(50) PRIMARY KEY,
    book_title VARCHAR(80),
    category VARCHAR(30),
    rental_price DECIMAL(10,2),
    status VARCHAR(10),
    author VARCHAR(30),
    publisher VARCHAR(30)
);

-- Issued Status Table
CREATE TABLE issued_status (
    issued_id VARCHAR(10) PRIMARY KEY,
    issued_member_id VARCHAR(10),
    issued_book_isbn VARCHAR(50),
    issued_date DATE,
    issued_emp_id VARCHAR(10),
    FOREIGN KEY (issued_member_id) REFERENCES members(member_id),
    FOREIGN KEY (issued_emp_id) REFERENCES employees(emp_id),
    FOREIGN KEY (issued_book_isbn) REFERENCES books(isbn)
);

-- Return Status Table
CREATE TABLE return_status (
    return_id VARCHAR(10) PRIMARY KEY,
    issued_id VARCHAR(10),
    return_date DATE,
    return_book_isbn VARCHAR(50),
    book_quality VARCHAR(10),
    FOREIGN KEY (issued_id) REFERENCES issued_status(issued_id),
    FOREIGN KEY (return_book_isbn) REFERENCES books(isbn)
);

-- ----------------------
-- Task 1: Add Book
-- ----------------------
INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

-- ----------------------
-- Task 2: Update Member Address
-- ----------------------
UPDATE members
SET member_address = '124 Oak St'
WHERE member_id = 'C103';

-- ----------------------
-- Task 3: Delete Issued Record
-- ----------------------
DELETE FROM issued_status
WHERE issued_id = 'IS121';

-- ----------------------
-- Task 4: Books Issued by Specific Employee
-- ----------------------
SELECT * FROM issued_status
WHERE issued_emp_id = 'E101';

-- ----------------------
-- Task 5: Employees Who Issued More Than 1 Book
-- ----------------------
SELECT issued_emp_id, COUNT(*) AS total_issued
FROM issued_status
GROUP BY issued_emp_id
HAVING COUNT(*) > 1;

-- ----------------------
-- Task 6: Create Summary Table of Book Issue Count
-- ----------------------
CREATE TABLE book_issued_cnt AS 
SELECT 
    b.isbn, 
    b.book_title, 
    COUNT(ist.issued_id) AS issue_count
FROM issued_status ist
JOIN books b ON ist.issued_book_isbn = b.isbn
GROUP BY b.isbn, b.book_title;

-- ----------------------
-- Task 7: Retrieve All Books in a Specific Category
-- ----------------------
SELECT * FROM books
WHERE category = 'Classic';

-- ----------------------
-- Task 8: Total Rental Income by Category
-- ----------------------
SELECT 
    b.category, 
    SUM(b.rental_price) AS total_income,
    COUNT(*) AS books_issued
FROM issued_status ist
JOIN books b ON b.isbn = ist.issued_book_isbn
GROUP BY b.category;

-- ----------------------
-- Task 9: Members Registered in Last 180 Days
-- ----------------------
SELECT * FROM members
WHERE reg_date >= CURDATE() - INTERVAL 180 DAY;

-- ----------------------
-- Task 10: Employees with Manager and Branch Info
-- ----------------------
SELECT 
    e1.emp_id, e1.emp_name, e1.position, e1.salary,
    b.branch_id, b.branch_address,
    e2.emp_name AS manager_name
FROM employees e1
JOIN branch b ON e1.branch_id = b.branch_id    
JOIN employees e2 ON e2.emp_id = b.manager_id;

-- ----------------------
-- Task 11: Create Table for Expensive Books
-- ----------------------
CREATE TABLE expensive_books AS
SELECT * FROM books
WHERE rental_price > 7.00;

-- ----------------------
-- Task 12: Books Not Yet Returned
-- ----------------------
SELECT ist.*
FROM issued_status ist
LEFT JOIN return_status rs ON rs.issued_id = ist.issued_id
WHERE rs.return_id IS NULL;

-- ----------------------
-- Task 13: Overdue Books (Over 30 Days)
-- ----------------------
SELECT 
    ist.issued_member_id,
    m.member_name,
    bk.book_title,
    ist.issued_date,
    DATEDIFF(CURDATE(), ist.issued_date) AS overdue_days
FROM issued_status ist
JOIN members m ON m.member_id = ist.issued_member_id
JOIN books bk ON bk.isbn = ist.issued_book_isbn
LEFT JOIN return_status rs ON rs.issued_id = ist.issued_id
WHERE rs.return_id IS NULL AND DATEDIFF(CURDATE(), ist.issued_date) > 30
ORDER BY overdue_days DESC;

-- ----------------------
-- Task 14: Procedure to Add Return and Update Book
-- ----------------------
DELIMITER //

CREATE PROCEDURE add_return_records (
    IN p_return_id VARCHAR(10),
    IN p_issued_id VARCHAR(10),
    IN p_book_quality VARCHAR(10)
)
BEGIN
    DECLARE v_isbn VARCHAR(50);
    DECLARE v_book_name VARCHAR(80);

    INSERT INTO return_status (return_id, issued_id, return_date, book_quality)
    VALUES (p_return_id, p_issued_id, CURDATE(), p_book_quality);

    SELECT b.isbn, b.book_title
    INTO v_isbn, v_book_name
    FROM issued_status ist
    JOIN books b ON ist.issued_book_isbn = b.isbn
    WHERE ist.issued_id = p_issued_id;

    UPDATE books SET status = 'yes'
    WHERE isbn = v_isbn;

    SELECT CONCAT('Thank you for returning the book: ', v_book_name) AS message;
END //

DELIMITER ;

-- ----------------------
-- Task 15: Branch Performance Report
-- ----------------------
CREATE TABLE branch_reports AS
SELECT 
    b.branch_id,
    b.manager_id,
    COUNT(ist.issued_id) AS number_book_issued,
    COUNT(rs.return_id) AS number_of_book_return,
    SUM(bk.rental_price) AS total_revenue
FROM issued_status ist
JOIN employees e ON e.emp_id = ist.issued_emp_id
JOIN branch b ON e.branch_id = b.branch_id
LEFT JOIN return_status rs ON rs.issued_id = ist.issued_id
JOIN books bk ON ist.issued_book_isbn = bk.isbn
GROUP BY b.branch_id, b.manager_id;

-- ----------------------
-- Task 16: Create Table for Active Members (Last 2 Months)
-- ----------------------
CREATE TABLE active_members AS
SELECT * FROM members
WHERE member_id IN (
    SELECT DISTINCT issued_member_id
    FROM issued_status
    WHERE issued_date >= CURDATE() - INTERVAL 2 MONTH
);

-- ----------------------
-- Task 17: Top 3 Employees by Book Issues
-- ----------------------
SELECT 
    e.emp_name,
    b.branch_address,
    COUNT(ist.issued_id) AS no_book_issued
FROM issued_status ist
JOIN employees e ON e.emp_id = ist.issued_emp_id
JOIN branch b ON e.branch_id = b.branch_id
GROUP BY e.emp_id, e.emp_name, b.branch_address
ORDER BY no_book_issued DESC
LIMIT 3;

-- ----------------------
-- Task 18: Members Who Returned 'Damaged' Books > 2 Times
-- ----------------------
SELECT 
    m.member_name,
    b.book_title,
    COUNT(*) AS times_damaged
FROM return_status rs
JOIN issued_status ist ON rs.issued_id = ist.issued_id
JOIN books b ON ist.issued_book_isbn = b.isbn
JOIN members m ON ist.issued_member_id = m.member_id
WHERE rs.book_quality = 'Damaged'
GROUP BY m.member_id, b.book_title
HAVING COUNT(*) > 2;

-- ----------------------
-- Task 19: Procedure to Issue Book
-- ----------------------
DELIMITER //

CREATE PROCEDURE issue_book (
    IN p_issued_id VARCHAR(10), 
    IN p_issued_member_id VARCHAR(30), 
    IN p_issued_book_isbn VARCHAR(30), 
    IN p_issued_emp_id VARCHAR(10)
)
BEGIN
    DECLARE v_status VARCHAR(10);

    SELECT status INTO v_status
    FROM books
    WHERE isbn = p_issued_book_isbn;

    IF v_status = 'yes' THEN
        INSERT INTO issued_status (
            issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id
        ) VALUES (
            p_issued_id, p_issued_member_id, CURDATE(), p_issued_book_isbn, p_issued_emp_id
        );

        UPDATE books
        SET status = 'no'
        WHERE isbn = p_issued_book_isbn;

        SELECT CONCAT('Book issued successfully: ', p_issued_book_isbn) AS message;
    ELSE
        SELECT CONCAT('Book not available: ', p_issued_book_isbn) AS message;
    END IF;
END //

DELIMITER ;

-- ----------------------
-- Task 20: Create Table of Overdue Books with Fines
-- ----------------------
CREATE TABLE overdue_fines AS
SELECT 
    ist.issued_member_id AS member_id,
    COUNT(CASE WHEN DATEDIFF(CURDATE(), ist.issued_date) > 30 THEN 1 END) AS overdue_books,
    SUM(
        CASE 
            WHEN DATEDIFF(CURDATE(), ist.issued_date) > 30 
            THEN (DATEDIFF(CURDATE(), ist.issued_date) - 30) * 0.5
            ELSE 0 
        END
    ) AS total_fine,
    COUNT(*) AS total_books_issued
FROM issued_status ist
LEFT JOIN return_status rs ON ist.issued_id = rs.issued_id
WHERE rs.return_id IS NULL
GROUP BY ist.issued_member_id;
