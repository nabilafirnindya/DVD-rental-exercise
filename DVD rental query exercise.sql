-- 1.Siapa saja cust yang aktif (customer_id, first_name, last_name, active)yang aktif
SELECT customer_id, first_name, last_name from customer
WHERE active = 1;

-- 2.Data customer (customer_id, first_name, last_name, active) yang nama depannya diawali huruf Y
SELECT customer_id, first_name, last_name 
FROM CUSTOMER
WHERE active = 1 and first_name LIKE 'Y%';

--3.Pelanggan yang menyewa DVD di toko yang berada di queensland (store_id = 2) urutkan berdasarkan abjad pelanggan 
SELECT first_name, last_name, email from customer
where store_id = 2 
ORDER BY First_name;

-- 4. pegawai terbaik yang paling sering menangani customer, dengan id dan nama pegawai
with data_store_id as (
	SELECT store_id, count(customer_id) jumlah from customer
group by store_id
	) 
	select staff_id, first_name, jumlah
	from data_store_id
	join staff using(store_id);
	
-- 5. store yang paling sering dibeli cust
 select store_id, count(customer_id) from customer
 group by 1
 order by 2 desc;

-- 6. customer yang telah banyak melakukan rental film, yang meminjam lebih dari 175$ akan dapet member eksklusif, siapa saja customernya dan ID nya apa
SELECT customer_id, first_name, sum(amount) as total from customer
join payment using(customer_id)
group by 1
having sum(amount) > '175'
order by 3;

-- 7.manager ingin membuat rangking untuk film PG, dibuat tanpa adanya gap, film apa saja yang durasinya paling lama?
Rangking film duration
select title, length, rating, 
dense_rank() over (partition by rating order by length desc) as rangking
from film
WHERE rating = 'PG';

-- 8.Banyak stock film 'Alone Trip' di inventory
SELECT f.title, count(i.film_id) from film as f 
join inventory as i using(film_id)
group by 1
having title = 'ALONE TRIP';
-- cara kedua
With alone_trip as (
select title, film_id from film
where title = 'ALONE TRIP')
select title, count(film_id) from inventory
join alone_trip using(film_id)
group by title;

-- 9. Aktor di film 'Academy Dinosaur'
select a.actor_id,a.first_name, a.last_name from actor a
join film_actor as fa using(actor_id)
join film as f using(film_id)
where title = 'ACADEMY DINOSAUR';
--cara 2 
select actor_id, first_name,last_name 
from actor 
where actor_id in (select actor_id 
				   from film_actor 
                   where film_id in( select film_id 
									 from film 
                                     where title = 'ACADEMY DINOSAUR'));

-- 10.TOP 10 kategori film yang paling banyak dirental
SELECT name, count(category_id) as sewa 
from rental
join inventory using(inventory_id)
join film_category using(film_id)
join film using(film_id)
join category using(category_id)
group by 1
order by 2 desc
limit 10;

-- 11.Kategori film yang paling banyak sales
select name, category_id, sum(amount) as salescategory 
from payment
join rental using(rental_id)
join inventory using(inventory_id)
join film using(film_id)
join film_category using(film_id)
join category using(category_id)
group by 1,2
order by 3 desc;

-- 12. TOP 5 cust dengan total bayar terbanyak
select distinct customer_id, concat(first_name,' ',last_name) as name, sum(amount) as total from customer
join payment using(customer_id)
group by 1
order by 3 desc
LIMIT 5;

--13.Tanggal dan jumlah transaksi pertama, yang dilakukan oleh cust Sulawesi Utara, West Java, Central Java, Jakarta Raya
with firsttimeorder as 
(SELECT concat(first_name,' ',last_name) as name, payment_date, district, amount,
FIRST_VALUE(payment_date) OVER(PARTITION BY concat(first_name,' ',last_name)) as firstpaymentdate,
FIRST_VALUE(amount) OVER(PARTITION BY concat(first_name,' ',last_name)) as totalfirstpayment
from payment
join customer using(customer_id)
join address using(address_id)
WHERE district in ('Sulawesi Utara', 'West Java', 'Central Java', 'Jakarta Raya')
)
SELECT name,firstpaymentdate, totalfirstpayment
from firsttimeorder
group by 1,2,3;

--14 Tanggal berapa rental banyak dilakukan oleh cust (untuk membuat diskon  tiap bulan selama 5 hari)
SELECT extract(day from rental_date) as day, count(rental_id) n_sewa from rental
group by 1
order by 2 desc;

--15. pada hari promo, ada skema diskon ( cust_name, n_rent, percent_disc)
n > 30 = disc 20%
n > 20 = disc 15%
n > 15 = disc 10%
n < 15 = disc = 0 %
WITH rental_user AS (
    SELECT 
        customer_id, 
        COUNT(rental_id) AS n_rent 
    FROM 
        rental 
    GROUP BY 
        1
)
SELECT 
    customer_id, 
    CONCAT(first_name,' ',last_name) AS fullname, 
    n_rent,
    CASE 
        WHEN n_rent > 30 THEN 'disc 30%'
        WHEN n_rent > 20 THEN 'disc 20%'
        WHEN n_rent > 15 THEN 'disc 10%'
        ELSE 'disc 0%'
    END AS diskon
FROM 
    rental_user
JOIN 
    customer USING(customer_id)
GROUP BY 
    1,2,3
ORDER BY 
    3 DESC;
-- cara 2 
WITH n_rent_customer AS(
SELECT CONCAT(first_name,' ', last_name) full_name,
	   COUNT(rental_id) n_rent
FROM customer
JOIN rental
	USING(customer_id)
GROUP BY 1
ORDER BY 2 DESC)

SELECT *,
	   CASE 
       WHEN n_rent > 30 THEN 20
       WHEN n_rent > 20 THEN 15
       WHEN n_rent > 15 THEN 10
       ELSE 0
       END percent_discount
FROM n_rent_customer;

-- 16. film terakhir yang ditonton tiap cust, dan film yang paling banyak disewa
WITH last_film_rent AS(
SELECT CONCAT(first_name,' ', last_name) full_name,
	   rental_date,
       title,
       LAST_VALUE(title) OVER(PARTITION BY CONCAT(first_name,' ', last_name) ORDER BY rental_date RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) last_film_rent
FROM customer
JOIN payment
	USING(customer_id)
JOIN rental
	USING(rental_id)
JOIN inventory 
	USING(inventory_id)
JOIN film
	USING(film_id))
	
SELECT last_film_rent, 
	   COUNT(*) n_rent
FROM last_film_rent
GROUP BY 1
ORDER BY 2 DESC;

