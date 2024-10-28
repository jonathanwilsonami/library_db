-- call drop_all_objects_in_schema('public'); -- Use this to start fresh

/*
////////////////////////////
---- QUESTIONS -------///////
/////////////////////////////
*/

-- 1. Which materials are currently available in the library? A material is considered unavailable 
-- if it has been borrowed and not yet returned.
-- select material_id, title 
-- from Material 
-- where (material_id) NOT IN (select material_id 
-- 				from Borrow
-- 				where return_date IS NULL);
-- SELECT * FROM available_materials; -- View

-- 2. Which materials are currently overdue? Suppose today is 04/01/2023, and show the
-- borrow date and due date of each material.
-- WITH today_date AS (
--     SELECT '2023-04-01'::DATE AS date_value -- Set arbitrary date variable
-- )
-- SELECT borrow_date, due_date
-- FROM Borrow, today_date
-- WHERE (return_date > due_date OR return_date IS NULL)
--   AND due_date < today_date.date_value;

-- Currently overdue
-- SELECT borrow_date, due_date
-- FROM Borrow
-- WHERE return_date IS NULL;
-- SELECT * FROM currently_overdue; -- View

-- 3. What are the top 10 most borrowed materials in the library? Show the title of each
-- material and order them based on their available counts.
-- select m.title, count(m.title)
-- from Borrow as b, Material as m
-- where b.material_id = m.material_id
-- group by b.material_id, m.title
-- limit 10;
-- select * from show_top_10_materials; --View

-- 4. How many materials has the author Lucas Piki written?
-- select count(name) AS number_of_authorings 
-- from (select * 
-- 		from Author as a, Authorship as b
-- 		where a.author_id = b.author_id AND name = 'Lucas Piki');

-- 5. How many materials were written by two or more authors?
-- select count(*) AS material_by_2_or_more_authors
-- from (select material_id 
-- 		from Authorship 
-- 		group by material_id
-- 		having count(author_id) > 1);

-- 6. What are the most popular genres in the library ranked by the total number of borrowed
-- times of each genre?
-- select g.name, count(*) AS total_borrowed
-- from Borrow as b 
-- JOIN Material AS m ON b.material_id = m.material_id
-- JOIN Genre AS g ON m.genre_id = g.genre_id
-- GROUP BY g.name
-- ORDER BY total_borrowed DESC;

-- -- 7. How many materials had been borrowed from 09/2020-10/2020?
-- select count(*) AS total_books_borrowed 
-- from Borrow
-- WHERE borrow_date BETWEEN '09/01/2020' AND '10/31/2020';

-- 8. How do you update the “Harry Potter and the Philosopher's Stone” when it is returned on
-- 04/01/2023?
-- UPDATE Borrow
-- SET return_date = '04/01/2023'
-- WHERE material_id IN (select material_id 
-- 						from Material 
-- 						where title = 'Harry Potter and the Philosopher''s Stone');
-- CALL update_return_date('Harry Potter and the Philosopher''s Stone', '04/01/2023');

-- 9. How do you delete the member Emily Miller and all her related records from the database?
-- DELETE FROM Member
-- WHERE name = 'Emily Miller';

-- 10. How do you add the following material to the database?
-- CALL add_material(
--     'New Book', 
--     '2020-08-01', 
--     'E-Books', 
--     'Mystery & Thriller', 
--     'Lucas Luke'
-- );

/*
Title: New book
Date: 2020-08-01
Catalog: E-Books
Genre: Mystery & Thriller
Author: Lucas Luke
*/