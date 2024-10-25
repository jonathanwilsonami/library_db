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

/*
Title: New book
Date: 2020-08-01
Catalog: E-Books
Genre: Mystery & Thriller
Author: Lucas Luke
*/

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

		RAISE NOTICE 'Material added with ID % and title %', v_catalog_id, p_title;
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

-- Usage: call drop_all_objects_in_schema('public')