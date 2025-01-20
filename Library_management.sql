USE library_management;

-- Create Database

CREATE DATABASE library_management;
use library_management;

-- creating Tables
DROP TABLE IF EXISTS branch;

CREATE TABLE branch (
    branch_id VARCHAR(10) PRIMARY KEY,
    manager_id VARCHAR(10),
    branch_address VARCHAR(15),
    contact_no VARCHAR(15)
);

DROP TABLE IF EXISTS employees;
CREATE TABLE employees (
    emp_id VARCHAR(10) PRIMARY KEY,
    emp_name VARCHAR(20),
    designation VARCHAR(15),
    salary INTEGER,
    branch_id VARCHAR(10)
);

DROP TABLE IF EXISTS books;
CREATE TABLE books (
    isbn VARCHAR(25) PRIMARY KEY,
    book_title VARCHAR(65),
    category VARCHAR(20),
    rental_price FLOAT,
    status VARCHAR(10),
    author VARCHAR(30),
    publisher VARCHAR(30)
);

DROP TABLE IF EXISTS members;
CREATE TABLE members (
    member_id VARCHAR(10) PRIMARY KEY,
    member_name VARCHAR(20),
    member_address VARCHAR(20),
    reg_date DATE
);

DROP TABLE IF EXISTS issued_status;
CREATE TABLE issued_status (
    issued_id VARCHAR(10) PRIMARY KEY,
    issued_member_id VARCHAR(10),
    issued_book_name VARCHAR(65),
    issued_date DATE,
    issued_book_isbn VARCHAR(25),
    issued_emp_id VARCHAR(10)
);

DROP TABLE IF EXISTS return_status;
CREATE TABLE return_status (
    return_id VARCHAR(10) PRIMARY KEY,
    issued_id VARCHAR(10),
    return_book_name VARCHAR(65),
    return_date DATE,
    return_book_isbn VARCHAR(25)
);


-- Foreign key 

ALTER TABLE issued_status
ADD CONSTRAINT fk_members
FOREIGN KEY (issued_member_id)
REFERENCES members(member_id);

ALTER TABLE issued_status
ADD CONSTRAINT fk_books
FOREIGN KEY (issued_book_isbn)
REFERENCES books(isbn);

ALTER TABLE issued_status
ADD CONSTRAINT fk_empid
FOREIGN KEY (issued_emp_id)
REFERENCES employees(emp_id);

ALTER TABLE employees 
ADD CONSTRAINT fk_branch
FOREIGN KEY (branch_id)
REFERENCES branch(branch_id);

ALTER TABLE return_status
ADD CONSTRAINT fk_issuedid
FOREIGN KEY (issued_id)
REFERENCES issued_status(issued_id);

-- Check Tables

SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT * FROM members;
SELECT * FROM return_status;

-- Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
SELECT * FROM books;

-- Task 2: Update an Existing Member's Address
UPDATE members
SET member_address = '125 Main St'
WHERE member_id ='C101';
SELECT * FROM members;

-- Task 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
DELETE FROM issued_status
WHERE issued_id = 'IS121';
SELECT * FROM issued_status;

-- Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.
select * from issued_status
where issued_emp_id ='E101';

-- Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.


SELECT 
    m.member_id, COUNT(i.issued_member_id) AS no_of_books_issued
FROM
    members m
        JOIN
    issued_status i ON m.member_id = i.issued_member_id
GROUP BY m.member_id
HAVING no_of_books_issued > 1
ORDER BY no_of_books_issued ASC;

-- CTAS
-- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**

CREATE TABLE book_cnt AS SELECT b.isbn,
    ist.issued_book_name,
    COUNT(ist.issued_book_name) AS no_of_times_book_issued FROM
    books b
        JOIN
    issued_status ist ON b.isbn = ist.issued_book_isbn
GROUP BY b.isbn , ist.issued_book_name;

SELECT 
    *
FROM
    book_cnt;
    
-- Task 7. Retrieve All Books in a Specific Category:

SELECT * 
FROM 
	books
WHERE category = 'Classic';

-- Task 8: Find Total Rental Income by Category:

SELECT 
    b.category, SUM(rental_price) AS Total_rental_price
FROM
    books b
        JOIN
    issued_status ist ON b.isbn = ist.issued_book_isbn
GROUP BY category;

-- List Members Who Registered in the Last 180 Days:

UPDATE members
SET reg_date = ' 2024-10-11'
WHERE member_id = 'C118';

SELECT * FROM members
WHERE reg_date >= current_date() - INTERVAL 180 DAY;

-- List Employees with Their Branch Manager's Name and their branch details:
 
SELECT 
    e.emp_id, e.emp_name, b.branch_id, b.manager_id, e2.emp_name as manager_name
FROM
    employees e
        JOIN
    branch b ON e.branch_id = b.branch_id
        JOIN
    employees e2 ON b.manager_id = e2.emp_id;
    
-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold 10USD:
CREATE TABLE Rental_book AS SELECT * FROM
    books
WHERE
    rental_price > 7;

SELECT * FROM rental_book;

-- Task 12. Retrieve the List of Books Not Yet Returned


SELECT 
    i.issued_id, i.issued_book_name
FROM
    issued_status i
WHERE
    i.issued_id NOT IN (SELECT 
            r.issued_id
        FROM
            return_status r);

SELECT 
    *
FROM
    issued_status i
        LEFT JOIN
    return_Status r ON i.issued_id = r.issued_id
WHERE
    return_id IS NULL;

/*
Task 13: Identify Members with Overdue Books
Q. Write a query to identify members who have overdue books (assume a 30-day return period). 
Display the member's_id, member's name, book title, issue date, and days overdue.
*/
select curdate();
-- members== book== issue_date == return
-- overdue books

SELECT 
    i.issued_member_id,
    m.member_name,
    b.book_title,
    i.issued_date,
    DATEDIFF(CURRENT_DATE(), i.issued_date) AS overdue_days
FROM
    issued_status i
        JOIN
    members m ON m.member_id = i.issued_member_id
        JOIN
    books b ON b.isbn = i.issued_book_isbn
        LEFT JOIN
    return_status r ON r.issued_id = i.issued_id
WHERE
    r.return_id IS NULL
        AND DATEDIFF(CURRENT_DATE(), i.issued_date) > 30;

/* Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "Yes" 
when they are returned (based on entries in the return_status table).
*/

DELIMITER $$
CREATE PROCEDURE book_returned(IN p_return_id VARCHAR(10), IN p_issued_id VARCHAR(10))
BEGIN
DECLARE 
	v_isbn VARCHAR(25);
DECLARE
    v_book_name VARCHAR (65);
    
    --  Insert into return_status based on user input
INSERT INTO return_status(return_id, issued_id, return_date)
VALUES(p_return_id, p_issued_id,CURRENT_DATE());

-- Retrieve book details from issued_status
SELECT 
    issued_book_isbn, issued_book_name
INTO v_isbn , v_book_name FROM
    issued_status
WHERE
    issued_id = p_issued_id;
    
-- Update the books table to mark the book as returned
UPDATE books 
SET 
    status = 'yes'
WHERE
    isbn = v_isbn;

SELECT 
    CONCAT('Thankyou for returning book: ',
            v_book_name) AS message;
END$$
DELIMITER ;



/*
Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, 
showing the number of books issued, the number of books returned, 
and the total revenue generated from book rentals
    */

CREATE TABLE branch_report AS SELECT b.branch_id,
    b.manager_id,
    COUNT(i.issued_id) AS no_books_issued,
    COUNT(r.return_id) AS no_books_returned,
    SUM(bk.rental_price) AS total_revenue FROM
    issued_status i
        JOIN
    employees e ON i.issued_emp_id = e.emp_id
        JOIN
    branch b ON b.branch_id = e.branch_id
        LEFT JOIN
    return_status r ON r.issued_id = i.issued_id
        JOIN
    books bk ON bk.isbn = i.issued_book_isbn
GROUP BY b.branch_id , b.manager_id;

SELECT * FROM branch_report;

/*
Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members 
who have issued at least one book in the last 11 months.
*/

CREATE TABLE active_members AS SELECT * FROM
    members
WHERE
    member_id IN (SELECT DISTINCT
            (issued_member_id)
        FROM
            issued_status
        WHERE
            issued_date >= CURRENT_DATE() - INTERVAL 11 MONTH);
 
/* Task 17
Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues. 
Display the employee name, number of books processed, and their branch.
*/

SELECT 
    e.emp_name,
    COUNT(issued_id) AS no_of_books_issued,
    e.branch_id
FROM
    issued_status i
        JOIN
    employees e ON e.emp_id = i.issued_emp_id
        JOIN
    branch b ON b.branch_id = e.branch_id
GROUP BY e.emp_name , e.branch_id
ORDER BY no_of_books_issued DESC
LIMIT 3;


/*
Task 18: Stored Procedure Objective: Create a stored procedure to manage the status of books in a library system. 
Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 
The procedure should function as follows: The stored procedure should take the book_id as an input parameter. 
The procedure should first check if the book is available (status = 'yes'). 
If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 
If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.
*/
select* from books;
select * from issued_status;

DELIMITER $$
CREATE PROCEDURE issue_book(IN p_issued_id VARCHAR(10), IN p_issued_member_id VARCHAR(30), IN p_issued_book_isbn VARCHAR(30), IN p_issued_emp_id VARCHAR(10))
BEGIN
DECLARE 
v_status VARCHAR(10);
	SELECT 
    status
INTO v_status FROM
    books
WHERE
    isbn = p_issued_book_isbn;
    
    IF v_status = 'yes' THEN
    INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn,issued_emp_id)
    VALUES(p_issued_id, p_issued_member_id, CURDATE(), p_issued_book_isbn, p_issued_emp_id);
    
UPDATE books 
SET 
    status = 'no'
WHERE
    isbn = p_issued_book_isbn;
    
SELECT 
    CONCAT('book record added successfully for book isbn: ',
            p_issued_book_isbn) AS message;
    ELSE 
		SELECT 
    CONCAT('Sorry to inform you the book you have requested is unavailable book_isbn: ',p_issued_book_isbn) AS message;
    END IF;
    END $$
    DELIMITER ;
    

-- Testing The function
SELECT * FROM books;
-- "978-0-553-29698-2" -- yes
-- "978-0-375-41398-8" -- no
SELECT * FROM issued_status;

CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104');
CALL issue_book('IS156', 'C108', '978-0-375-41398-8', 'E104');

SELECT * FROM books
WHERE isbn = '978-0-553-29698-2';

SELECT * FROM books
WHERE isbn = '978-0-375-41398-8';
 
 /*
Task 19: Create Table As Select (CTAS) Objective: Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.
Description: Write a CTAS query to create a new table that lists each member and the books they have issued but not returned within 30 days. 
The table should include: The number of overdue books. The total fines, with each day's fine calculated at $0.50. 
The number of books issued by each member. The resulting table should show: Member ID Number of overdue books Total fines
*/

SELECT 
    m.member_id,
    COUNT(i.issued_id) AS no_overdue_books,
    DATEDIFF(CURRENT_DATE(), i.issued_date) * 0.50 AS fine
FROM
    issued_status i
        JOIN
    members m ON i.issued_member_id = m.member_id
        LEFT JOIN
    return_status r ON r.issued_id = i.issued_id
WHERE
    r.return_id IS NULL
        AND DATEDIFF(CURRENT_DATE(), i.issued_date) > 30
GROUP BY m.member_id , i.issued_date