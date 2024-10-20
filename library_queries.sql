---- Utils -------

select * from Borrow; 

-- call drop_all_objects_in_schema('public')

---- QUESTIONS -------

-- 1. Which materials are currently available in the library? A material is considered unavailable 
-- if it has been borrowed and not yet returned.
-- select * from Material;

-- 2. Which materials are currently overdue? Suppose today is 04/01/2023, and show the
-- borrow date and due date of each material.

-- Get materials that were overdue in the past
-- select material_id, title 
-- from Material 
-- where (material_id) IN (select material_id 
-- 				from Borrow
-- 				where return_date > due_date);

-- Get materials that are currently overdue
-- select material_id, title 
-- from Material 
-- where (material_id) IN (select material_id 
-- 				from Borrow
-- 				where CURRENT_DATE > due_date AND return_date IS NULL);

-- Set arbitrary date variable
WITH today_date AS (
    SELECT '04/01/2023'::DATE AS date_value
)
SELECT borrow_date, due_date
FROM Borrow
WHERE  = (SELECT date_value FROM today_date);

-- select material_id, title 
-- from Material 
-- where (material_id) IN (select material_id 
-- 				from Borrow
-- 				where return_date > due_date);

-- 3. What are the top 10 most borrowed materials in the library? Show the title of each
-- material and order them based on their available counts.

-- 4. How many materials has the author Lucas Piki written?

-- 5. How many materials were written by two or more authors?
-- select count(*) 
-- from (select material_id 
-- 		from Authorship 
-- 		group by material_id
-- 		having count(author_id) > 1);

-- 6. What are the most popular genres in the library ranked by the total number of borrowed
-- times of each genre?

-- 7. How many materials had been borrowed from 09/2020-10/2020?

-- 8. How do you update the “Harry Poper and the Philosopher's Stone” when it is returned on
-- 04/01/2023?

-- 9. How do you delete the member Emily Miller and all her related records from the database?

-- 10. How do you add the following material to the database?

/*
Title: New book
Date: 2020-08-01
Catalog: E-Books
Genre: Mystery & Thriller
Author: Lucas Luke
*/