					-- MUSIC_STORE DATABASE CREATION

/* CREATE DATABASE (music_store) BEFORE CREATING TABLE:
 CREATE DATABASE music_score; */

					-- TABLE CREATION

-- employee table
Create Table employee(
employee_id int primary key,
last_name varchar(20),
first_name varchar(20),
title varchar(30),
reports_to int,
levels varchar(10),
birthdate date,
hire_date date,
address varchar(50),
city varchar(20),
state varchar(20),
country varchar(20),
postal_code varchar(20),
phone varchar(30),
email varchar(50)

);

-- customer table
Create Table customer(
customer_id int primary key,
first_name varchar(20) not null,
last_name varchar(20),
company varchar(25),
address varchar(50),
city varchar(25),
state varchar(20),
country varchar(25),
email varchar(50),
support_rep_id int

);

-- invoice table
Create Table invoice(
invoice_id int primary key,
customer_id int,
invoice_date date,
billing_address varchar(150),
billing_city varchar(20),
billing_state varchar(10),
billing_country varchar(20),
total int,
foreign key (customer_id) REFERENCES customer(customer_id)

);

-- artist table
Create Table artist(
artist_id int primary key,
name varchar(150)

);

-- album table
Create Table album(
album_id int primary key,
title varchar(255),
artist_id int,
foreign key (artist_id) REFERENCES artist(artist_id)

);


-- genre table
CREATE TABLE genre (
    genre_id INT PRIMARY KEY,
    name VARCHAR(255)
);


-- media_type table
CREATE TABLE media_type (
    media_type_id INT PRIMARY KEY,
    name VARCHAR(255)
);


-- playlist table
CREATE TABLE playlist (
    playlist_id INT PRIMARY KEY,
    name VARCHAR(255)
);


-- track table 
CREATE TABLE track (
    track_id INT PRIMARY KEY,
    name VARCHAR(255),
    album_id INT,
    media_type_id INT,
    genre_id INT,
    composer VARCHAR(255),
    milliseconds INT,
    bytes INT,
    unit_price DECIMAL(10, 2),
    FOREIGN KEY (album_id) REFERENCES album(album_id),
    FOREIGN KEY (media_type_id) REFERENCES media_type(media_type_id),
    FOREIGN KEY (genre_id) REFERENCES genre(genre_id)
);


-- invoice_line table
CREATE TABLE invoice_line (
    invoice_line_id INT PRIMARY KEY,
    invoice_id INT,
    track_id INT,
    unit_price DECIMAL(10, 2),
    quantity INT,
    FOREIGN KEY (invoice_id) REFERENCES invoice(invoice_id),
    FOREIGN KEY (track_id) REFERENCES track(track_id)
);


					-- 1. Easy Level Queries


		-- Q1: Find the most senior employee based on job title. 
		--Hint: Use the employee table and sort by the levels column in descending order.
		
SELECT *
FROM employee
ORDER BY levels DESC
LIMIT 1;


		--  Q2: Determine which countries have the most invoices.
		-- Hint: Group the invoice data by billing_country, then count and sort the results.

SELECT billing_country, COUNT(*) AS invoice_count
FROM invoice
GROUP BY billing_country
ORDER BY invoice_count DESC;


		-- Q3: Identify the top 3 invoice totals.
		--Hint: Sort the invoice table by the total column. 

SELECT *
FROM invoice
ORDER BY total DESC
LIMIT 3;


		-- Q4: Find the city with the highest total invoice amount to determine the best location for a promotional event. 

SELECT billing_city, SUM(total) AS total_sales
FROM invoice
GROUP BY billing_city
ORDER BY total_sales DESC
LIMIT 1;


		-- Q5: Identify the customer who has spent the most money. 
		-- Hint: Use a join between customer and invoice, group by customer_id, and sum the totals. 

SELECT c.customer_id, c.first_name, c.last_name, SUM(i.total) AS total_spent
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC
LIMIT 1;



					-- 2. Moderate Level Queries


		-- Q1: Find the email, first name, and last name of customers who listen to Rock music.
		-- Hint: Use joins across customer, invoice, invoice_line, and track, filtering for the 

SELECT DISTINCT c.email, c.first_name, c.last_name  Rock 
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock';


		-- Q2: Identify the top 10 rock artists based on track count.
		-- Hint: Use joins across artist, album, and track and filter by the genre Rock.Count tracks per artist.

SELECT a.name AS artist_name, COUNT(t.track_id) AS track_count
FROM artist a
JOIN album al ON a.artist_id = al.artist_id
JOIN track t ON al.album_id = t.album_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
GROUP BY a.name
ORDER BY track_count DESC
LIMIT 10;


		-- Q3: Find all track names that are longer than the average track length. 
		-- Hint: Calculate the average length and compare each track’s length to this average.

SELECT name, milliseconds
FROM track
WHERE milliseconds > (
    SELECT AVG(milliseconds)
    FROM track
);



					-- Advanced Level Queries


		-- Q1: Calculate how much each customer has spent on each artist.
		--Hint: Use a CTE to calculate the earnings per artist from invoice_line, then join it with customer, invoice, and artist.

WITH artist_sales AS (
    SELECT
        a.artist_id,
        a.name AS artist_name,
        c.customer_id,
        SUM(il.unit_price * il.quantity) AS amount_spent
    FROM invoice_line il
    JOIN invoice i ON il.invoice_id = i.invoice_id
    JOIN customer c ON i.customer_id = c.customer_id
    JOIN track t ON il.track_id = t.track_id
    JOIN album al ON t.album_id = al.album_id
    JOIN artist a ON al.artist_id = a.artist_id
    GROUP BY a.artist_id, a.name, c.customer_id
)
SELECT *
FROM artist_sales
ORDER BY customer_id, amount_spent DESC;


		-- Q2: Determine the most popular music genre for each country based on purchases. 
		-- Hint: Use a CTE or window function to rank genres by purchase count per country. 

WITH genre_ranked AS (
    SELECT
        i.billing_country,
        g.name AS genre_name,
        COUNT(*) AS genre_count,
        RANK() OVER (PARTITION BY i.billing_country ORDER BY COUNT(*) DESC) AS genre_rank
    FROM invoice i
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    JOIN track t ON il.track_id = t.track_id
    JOIN genre g ON t.genre_id = g.genre_id
    GROUP BY i.billing_country, g.name
)
SELECT billing_country, genre_name, genre_count
FROM genre_ranked
WHERE genre_rank = 1;


			--  Q3: Identify the top-spending customer for each country. 
			--Hint: Calculate the total spending per customer per country and filter for the highest spending. 

WITH customer_spending AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        i.billing_country,
        SUM(i.total) AS total_spent,
        RANK() OVER (PARTITION BY i.billing_country ORDER BY SUM(i.total) DESC) AS spending_rank
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, i.billing_country
)
SELECT *
FROM customer_spending
WHERE spending_rank = 1;





