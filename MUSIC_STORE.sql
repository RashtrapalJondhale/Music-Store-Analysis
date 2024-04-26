
--      ==========================MUSIC STORE ANALYSIS==================================

-- Q1.  Who is the senior most employee based on job title?
SELECT * FROM employee
ORDER BY levels DESC
LIMIT 1;

-- Q.2 Which countries have the most invoices?
SELECT billing_country AS Country , COUNT(invoice_id) AS Total_invoices
FROM invoice
GROUP BY country
ORDER BY Total_invoices DESC;

-- Q.3 What are top 3 values of total invoice?
SELECT * FROM invoice
ORDER BY total DESC
LIMIT 3;

--   Q4. Which city has the best customer? We would like to throw a promotional music festival in the city we
--       made the most money. Write a query returns one city has the highest sum of invoices total. 
--       Return both city name and sum of all invoices total.

SELECT billing_city AS City, SUM(total) AS Total_amt
FROM invoice
GROUP BY City
ORDER BY Total_amt DESC LIMIT 1;

--   Q.5 Who is the best customer ? The customer who spent the most  money will be declared the best customer. 
--       Write a query that returns the customer who  has spent the most money. 

SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));


SELECT a.customer_id, a.first_name , a.last_name,SUM(b.total) AS Total_amt
FROM customer a INNER JOIN invoice b ON a.customer_id = b.customer_id
GROUP BY customer_id
ORDER BY Total_amt DESC LIMIT 1;


-- QUESTION SET 2 (MODERATE QUESTIONS)
--   Q.1 Write a query to return the  email , first_name , last name  and genre of all rock music listeners. 
--       Return your list ordered alphabetecally by email starting with A.

SELECT g.genre_name, g.customer_id , h.first_name ,h.last_name, h.email FROM
(SELECT e.*, f.customer_id FROM 
(SELECT c.* , d.invoice_id FROM 
(SELECT a.genre_id, a.name AS genre_name, b.track_id FROM genre a 
INNER JOIN track b ON a.genre_id = b.genre_id)c 
INNER JOIN invoice_line d ON c.track_id = d.track_id)e
INNER JOIN invoice f ON e.invoice_id = f.invoice_id)g
INNER JOIN customer h ON g.customer_id = h.customer_id
WHERE genre_id=1
GROUP BY customer_id
ORDER BY email;
 
 
 --    Q.2 Lets invite the artist who have written the most rock music in our dataset. 
 --        Write a query that returns the artist name and total track count of the top 10 rock bands.
 
SELECT e.artist_id, e.artist_name, COUNT(e.artist_id) AS total_track_cnt  FROM
(SELECT c.*, d.name AS  artist_name FROM
(SELECT  a.track_id ,a.genre_id, b.album_id , b.artist_id FROM
 track a  JOIN album b ON a.album_id = b.album_id)c
 JOIN artist d ON c.artist_id = d.artist_id)e
 JOIN genre f ON e.genre_id = f.genre_id
 WHERE  f.name LIKE "rock"
 GROUP BY e.artist_id
 ORDER BY total_track_cnt DESC
 LIMIT 10;
 
 --  Q.3 Return all the track names that have a song length longer than the average song legnth. Return the name and milliseconds for
 --     for each track. Order by the song length with longest song on top of the list. 
 
 SELECT track_id, name 	AS track_name, milliseconds
FROM track
WHERE milliseconds > (SELECT AVG(milliseconds) FROM track)
ORDER BY milliseconds DESC;
 
 
--  ADVANCE LEVEL
-- Q.1. Find how much money spent by each customer on artists. Write a query to return customer name , artist name  and total spent. 

WITH best_selling_artist AS (
SELECT artist.artist_id AS artist_id, artist.name AS artist_name,
SUM(invoice_line.quantity*invoice_line.unit_price) AS total_sales
FROM invoice_line
JOIN track ON track.track_id = invoice_line.track_id
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
GROUP BY 1
ORDER BY 3 DESC
)
SELECT c.customer_id , c.first_name, c.last_name, bsa.artist_name,
CAST(
SUM(il.quantity*il.unit_price) AS DECIMAL (10,2)) AS amount_spent
FROM invoice i
JOIN customer c ON i.customer_id = c.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC
LIMIT 10;

-- alternative query without CTE

SELECT  c.customer_id, c.first_name, c.last_name, artist.name AS artist_name,
    SUM(il.quantity * il.unit_price) AS amount_spent
FROM invoice i
JOIN customer c ON i.customer_id = c.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN artist ON artist.artist_id = alb.artist_id
GROUP BY c.customer_id, c.first_name, c.last_name, artist.name
ORDER BY 
    amount_spent DESC;
    
    -- Q.2  We want to find out the most popular music genre for each country. We determine the most popular 
    --     genre as  the genre with the highest amount of purchases. Write a query that returns each country 
    --     along with the top genre. For countries where the maximum number of purchases is shared return all
    --     genres. 
    
  WITH popular_genre AS
      (   
      SELECT billing_country AS country, COUNT(invoice_line.quantity) AS total_purchases, genre.name , genre.genre_id,
      ROW_NUMBER() OVER(PARTITION BY invoice.billing_country ORDER BY COUNT(invoice_line.quantity)DESC) AS RowNo  
      FROM invoice_line
      JOIN invoice ON invoice_line.invoice_id = invoice.invoice_id 
      JOIN track ON track.track_id = invoice_line.track_id 
      JOIN genre ON genre.genre_id = track.genre_id 
      GROUP BY 1,3,4
      ORDER BY 1 ASC,2 DESC
      )
      SELECT * FROM  popular_genre 
      WHERE RowNo = 1;
    
    --  Q.3 	Write the query that determines the customer that has spent the most on music for each country. Write a 
    --          query that returns the country along with the top customer and how much they spent. For countries where
    --          the top amount spent is shared, provide all customers who spent this amount. 
    
    WITH RECURSIVE customer_with_country AS (
    SELECT c.customer_id, c.first_name, c.last_name, country, 
	SUM(invoice.total) AS total_spending
    FROM invoice
    JOIN customer c ON c.customer_id = invoice.customer_id
    GROUP BY 1, 2, 3, 4
    ORDER BY 5 DESC
),
country_max_spending AS (
    SELECT country, MAX(total_spending) AS max_spending
    FROM customer_with_country
    GROUP BY country
)
SELECT cc.country, cc.total_spending, cc.first_name, cc.last_name
FROM customer_with_country cc
JOIN country_max_spending ms ON cc.country = ms.country
WHERE cc.total_spending = ms.max_spending
ORDER BY cc.country;

-- alternative method
WITH customer_with_country AS
(
SELECT cc.customer_id, first_name, last_name, country, SUM(total) AS total_spending,
ROW_NUMBER() OVER(PARTITION BY country ORDER BY SUM(total)DESC) AS RowNo
FROM invoice
JOIN customer cc ON cc.customer_id = invoice.customer_id
GROUP BY 1,2,3,4
ORDER BY 4 ASC, 5 DESC)
SELECT * FROM customer_with_country
WHERE RowNo = 1;
    
    



