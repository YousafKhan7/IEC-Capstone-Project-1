#RFM ANALYSIS

WITH customer_rfm AS (
 SELECT
 customer.customer_id,
 MAX(rental.rental_date) AS most_recent_rental,
 COUNT(DISTINCT rental.rental_date) AS frequency,
 SUM(payment.amount) AS monetary_value
 FROM
 customer
 JOIN
 rental ON customer.customer_id = rental.customer_id
 JOIN
 payment ON rental.rental_id = payment.rental_id
 GROUP BY
 customer.customer_id
 )
 SELECT
 customer_rfm.customer_id,
 DATEDIFF(CURRENT_DATE(), customer_rfm.most_recent_rental) AS recency,
 customer_rfm.frequency,
 customer_rfm.monetary_value,
 RANK() OVER (PARTITION BY customer_rfm.frequency ORDER BY DATEDIFF(CURRENT_DATE(), customer_rfm.most_recent_rental) DESC) AS R,
 RANK() OVER (PARTITION BY customer_rfm.monetary_value ORDER BY DATEDIFF(CURRENT_DATE(), customer_rfm.most_recent_rental) DESC) AS F,
 RANK() OVER (PARTITION BY DATEDIFF(CURRENT_DATE(), customer_rfm.most_recent_rental) ORDER BY customer_rfm.frequency DESC, customer_rfm.monetary_value DESC) AS M
 FROM
 customer_rfm


# How many distinct users have rented each genre? 
SELECT c.name AS genre , count(distinct cu.customer_id) AS Total_rent_demand 
FROM category c
JOIN film_category fc USING (category_id)
JOIN film f using (film_id)
JOIN inventory i using (film_id)
JOIN rental r using(inventory_id)
JOIN customer cu using(customer_id)
group by 1
ORDER BY 2 desc

#Sales by months?

WITH Monthly_Sales AS (
  SELECT MONTH(payment_date) AS Month, SUM(amount) AS Sales
  FROM payment
  GROUP BY MONTH(payment_date))
SELECT Month, Sales
FROM Monthly_Sales
ORDER BY Sales DESC;

#What is the Average rental rate for each genre?
SELECT c.name AS genre , round(AVG(f.rental_rate),2) AS Average_rental_rate 
FROM category c
JOIN film_category fc USING (category_id)
JOIN film f using (film_id)
JOIN inventory i using (film_id)
group by 1
ORDER BY 2 desc


#Return Type?
SELECT 
    case
        when rental_duration > DATEDIFF(return_date, rental_date) THEN 'Returned Early'
        when rental_duration = DATEDIFF(return_date, rental_date) THEN 'Returned on Time'
        else 'Returned Late'
    END as Return_Status, 
    COUNT(*) AS Total_noof_films
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
GROUP BY Return_Status
ORDER BY Total_noof_films DESC



#What are the total sales in each country? 
SELECT country,count(distinct customer_id) AS Customer_Number, SUM(amount)
 AS total_sales
FROM country
JOIN city USING( country_id)
JOIN address USING(city_id)
JOIN customer USING(address_id)
JOIN payment USING(customer_id)
GROUP BY 1
ORDER BY 2 DESC



#Who are the top 5 customers per total sales?
WITH t1 AS ( 
  SELECT CONCAT(first_name , ' ' , last_name) AS full_name  
  FROM customer
) 
SELECT   t1.full_name,   customer.email,   address.address,   city.city,   country.country, 
  SUM(payment.amount) AS Total_purchase_in_currency 
FROM   t1 
  JOIN customer ON t1.full_name = CONCAT(customer.first_name, ' ', customer.last_name)
  JOIN address ON address.address_id = customer.address_id
  JOIN city ON city.city_id = address.city_id
  JOIN country ON country.country_id = city.country_id
  JOIN payment ON payment.customer_id = customer.customer_id
GROUP BY  t1.full_name, customer.email,   address.address,   city.city,   country.country
ORDER BY t1.full_name,  6 DESC 
LIMIT 5

#What are the most popular rental days of the week?

SELECT DAYNAME(rental_date) as rental_day, COUNT(*) as rental_count
FROM rental
GROUP BY rental_day
ORDER BY rental_count DESC;

#What is the average rental duration for a DVD?

SELECT AVG(DATEDIFF(return_date, rental_date)) as avg_duration
FROM rental
WHERE return_date IS NOT NULL;


#How many films are in each category?

SELECT category.name, COUNT(film.film_id) as film_count
FROM category
JOIN film_category ON film_category.category_id = category.category_id
JOIN film ON film.film_id = film_category.film_id
GROUP BY category.name



#Which store location has the most rentals?

SELECT store.store_id, COUNT(rental.rental_id) as rental_count
FROM store 
JOIN inventory ON inventory.store_id = store.store_id
JOIN rental ON rental.inventory_id = inventory.inventory_id
GROUP BY store.store_id
ORDER BY rental_count DESC


#How many rentals were made by each staff member?

SELECT staff.first_name, staff.last_name, COUNT(rental.rental_id) as rental_count
FROM staff
JOIN rental ON rental.staff_id = staff.staff_id
GROUP BY staff.first_name, staff.last_name
ORDER BY rental_count DESC


#What is the average rental duration for a customer?

SELECT AVG(DATEDIFF(return_date, rental_date)) as avg_duration, customer.first_name, customer.last_name
FROM rental
JOIN customer ON customer.customer_id = rental.customer_id
WHERE return_date IS NOT NULL
GROUP BY rental.customer_id
ORDER BY avg_duration DESC


#Which films are most overdue?

SELECT film.title, COUNT(*) as overdue_count
FROM rental
JOIN inventory ON inventory.inventory_id = rental.inventory_id
JOIN film ON film.film_id = inventory.film_id
WHERE return_date > rental_date + INTERVAL rental_duration DAY
GROUP BY film.title
ORDER BY overdue_count DESC


#How many films are in each rating?

SELECT rating, COUNT(film_id) as film_count
FROM film
GROUP BY rating


#Average Rent duration by Genre?

SELECT c.name AS genre , round(AVG(f.rental_rate),2) AS Average_rental_rate 
FROM category c
JOIN film_category fc USING (category_id)
JOIN film f
using (film_id)
JOIN inventory i
using (film_id)
group by 1

Who are our loyal customers?


WITH Loyal_Customers AS (
  SELECT  c.first_name,c.last_name, COUNT(*) AS Rentals
  FROM Rental Join customer c using (customer_id)
  GROUP BY c.first_name,c.last_name
)
SELECT first_name, last_name, Rentals
FROM Loyal_Customers
WHERE Rentals >= (SELECT AVG(Rentals) FROM Loyal_Customers);

WITH Customer_Spending AS (
SELECT customer_id, SUM(amount) AS Total_Spending
FROM payment
GROUP BY customer_id
)
SELECT c.first_name, c.last_name, cs.Total_Spending
FROM Customer_Spending cs
JOIN customer c ON cs.customer_id = c.customer_id
ORDER BY cs.Total_Spending Asc
LIMIT 10;

