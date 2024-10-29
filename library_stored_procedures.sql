/*
////////////////////////////////
///////Stored Procedures///////
///////////////////////////////
*/

-- Util for dropping everything and starting over
CREATE OR REPLACE PROCEDURE drop_all_objects_in_schema(schema_name TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
BEGIN
    -- Drop all tables
    FOR rec IN
        SELECT tablename FROM pg_tables WHERE schemaname = schema_name
    LOOP
        EXECUTE format('DROP TABLE IF EXISTS %I.%I CASCADE', schema_name, rec.tablename);
    END LOOP;

    -- Drop all sequences
    FOR rec IN
        SELECT sequencename FROM pg_sequences WHERE schemaname = schema_name
    LOOP
        EXECUTE format('DROP SEQUENCE IF EXISTS %I.%I CASCADE', schema_name, rec.sequencename);
    END LOOP;

    RAISE NOTICE 'All tables and sequences in schema % have been dropped.', schema_name;
END $$;

-- Q1 
CREATE OR REPLACE VIEW available_materials AS
SELECT material_id, title
FROM Material
WHERE material_id NOT IN (
    SELECT material_id
    FROM Borrow
    WHERE return_date IS NULL
);

-- Q2 
CREATE OR REPLACE VIEW currently_overdue AS
SELECT borrow_date, due_date
FROM Borrow
WHERE return_date IS NULL;

-- Q3 
CREATE OR REPLACE VIEW show_top_10_materials AS
select m.title, count(m.title)
from Borrow as b, Material as m
where b.material_id = m.material_id
group by b.material_id, m.title
limit 10;

-- Q8
CREATE OR REPLACE PROCEDURE update_return_date(material_title VARCHAR, new_return_date DATE)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE Borrow
    SET return_date = new_return_date
    WHERE material_id IN (
        SELECT material_id
        FROM Material
        WHERE title = material_title
    );
END;
$$;

/*
Input...

Title: New book
Date: 2020-08-01
Catalog: E-Books
Genre: Mystery & Thriller
Author: Lucas Luke
*/

-- Q10
CREATE OR REPLACE PROCEDURE add_material(
    p_title VARCHAR(500),
    p_publication_date DATE,
    p_catalog VARCHAR(500),
    p_genre VARCHAR(255),
    p_author VARCHAR(255)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_catalog_id INT;
    v_genre_id INT;
    v_author_id INT;
    v_material_id INT;
	v_authorship_id INT;
BEGIN
    -- Catalog
	SELECT catalog_id INTO v_catalog_id
    FROM Catalog
    WHERE name = p_catalog;

	IF v_catalog_id IS NULL THEN
        INSERT INTO Catalog (name)
	    VALUES (p_catalog)
	    ON CONFLICT (name) DO NOTHING
	    RETURNING catalog_id INTO v_catalog_id;
    END IF;

	-- Genre
	SELECT genre_id INTO v_genre_id
    FROM Genre
    WHERE name = p_genre;

	IF v_genre_id IS NULL THEN
		INSERT INTO Genre (name)
		VALUES (p_genre)
	    ON CONFLICT (name) DO NOTHING
		RETURNING genre_id INTO v_genre_id;
    END IF;

	-- Author 
	SELECT author_id INTO v_author_id
    FROM Author
    WHERE name = p_author;

	IF v_author_id IS NULL THEN
		INSERT INTO Author (name)
    	VALUES (p_author)
    	ON CONFLICT (name) DO NOTHING
		RETURNING author_id INTO v_author_id;
    END IF;

    -- Material
	SELECT material_id INTO v_material_id
    FROM Material
    WHERE title = p_title AND publication_date = p_publication_date;

	IF v_material_id IS NULL THEN
		INSERT INTO Material (title, publication_date, catalog_id, genre_id)
    	VALUES (p_title, p_publication_date, v_catalog_id, v_genre_id)
    	RETURNING material_id INTO v_material_id;

		RAISE NOTICE 'Material added with ID % and title %', v_material_id, p_title;
	ELSE
		RAISE NOTICE 'Material with title % already exists! Nothing Added.', p_title;
    END IF;

	-- Authorship
	SELECT authorship_id INTO v_authorship_id
    FROM Authorship
    WHERE material_id = v_material_id;

	IF v_authorship_id IS NULL THEN
    	INSERT INTO Authorship (author_id, material_id)
    	VALUES (v_author_id, v_material_id)
	    ON CONFLICT (author_id, material_id) DO NOTHING
	    RETURNING authorship_id INTO v_authorship_id;

		RAISE NOTICE 'Authorship added with ID % and authors %', v_authorship_id, v_author_id;
	ELSE
		RAISE NOTICE 'Authorship with ID % already exists! Nothing Added.', v_authorship_id;
    END IF;
	
END $$;

-- Extra Features 

-- CREATE OR REPLACE FUNCTION get_overdue_members()
-- RETURNS TABLE(member_id INT) AS $$
-- BEGIN
--     RETURN QUERY
--     SELECT member_id
--     FROM Membership
--     WHERE overdue_occurrences = 3
--       AND (status = 'active' OR status IS NULL);
-- END;
-- $$ LANGUAGE plpgsql;


Drop function process_overdue_materials();
CREATE OR REPLACE FUNCTION process_overdue_materials()
RETURNS TABLE(member_id INT, material_id INT) AS $$
BEGIN
    RETURN QUERY
    SELECT b.member_id, b.material_id
    FROM Borrow as b
    WHERE b.return_date IS NULL
      AND b.due_date < CURRENT_DATE;

    UPDATE Membership
    SET overdue_occurrences = 
        CASE 
			WHEN fee_paid = TRUE THEN 0
            WHEN overdue_occurrences < 3 THEN overdue_occurrences + 1
            ELSE overdue_occurrences
        END,
		-- Set active or deactivated status
        status = 
        CASE
			WHEN fee_paid = TRUE THEN 'active'
            WHEN overdue_occurrences + 1 >= 3 THEN 'deactivated'
            ELSE status
        END,
		-- Reactivate member as needed
		fee_paid = 
            CASE 
                WHEN fee_paid = TRUE THEN NULL
                ELSE fee_paid
            END
    WHERE Membership.member_id IN (
        SELECT b.member_id
        FROM Borrow as b
        WHERE b.return_date IS NULL
          AND b.due_date < CURRENT_DATE
    );
END;
$$ LANGUAGE plpgsql;