-- 1.Create a view called "sales_revenue_by_category_qtr" that shows the film category and total sales revenue for the current quarter. The view should only display categories with at least one sale in the current quarter. The current quarter should be determined dynamically.
create or replace view public.sales_revenue_by_category_qtr as
select
    c.name as category,
    extract(quarter from p.payment_date) as quarter,
    coalesce(sum(p.amount), 0::numeric) AS total_sales_revenue
from payment p
join rental r on p.rental_id = r.rental_id
join inventory i on r.inventory_id = i.inventory_id
join film f on i.film_id = f.film_id
join film_category fc on f.film_id = fc.film_id
join category c on fc.category_id = c.category_id
where
   extract(quarter from p.payment_date) = extract(quarter from current_date)
   and extract(year from p.payment_date) = extract(year from current_date)
group by c.name, extract(quarter from p.payment_date)
having count(distinct p.payment_id) > 0;
-- 2.Create a query language function called "get_sales_revenue_by_category_qtr" that accepts one parameter representing the current quarter and returns the same result as the "sales_revenue_by_category_qtr" view. 
create or replace function get_sales_revenue_by_category_qtr(current_qtr numeric)
returns table(category_result text, quarter_result numeric, total_sales_revenue_result numeric)
language 'plpgsql'
as 
$$
begin
  return query
  select * from sales_revenue_by_category_qtr
  where quarter = current_qtr;
end;
$$;

select * from get_sales_revenue_by_category_qtr(extract(quarter from current_date));


/* 3. Create a procedure language function called "new_movie" that takes a movie title 
as a parameter and inserts a new movie with the given title in the film table. The function should generate a new unique film ID, set the rental rate to 4.99, 
the rental duration to three days, the replacement cost to 19.99, the release year to the current year, and "language" as Klingon. 
The function should also verify that the language exists in the "language" table. Then, ensure that no such function has been created before; if so, replace it*/
create or replace procedure new_movie(movie_title varchar)
language plpgsql
as $$
declare
    s_language_id int;
    new_film_id int;
begin
    
    select language_id into s_language_id
    from language
    where name = 'Klingon';

    if s_language_id is null then
        raise exception 'Language "Klingon" does not exist in the language table.';
    end if;

    select coalesce(max(film_id), 0) + 1 into new_film_id
    from film;
  
    insert into film (film_id, title, rental_rate, rental_duration, replacement_cost, release_year, language_id)
    values (new_film_id, movie_title, 4.99, 3, 19.99, extract(year from current_date), s_language_id);
end;
$$;

call new_movie('The Green Elephant: Adventures of Bratishka');