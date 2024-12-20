/*///////////////////
///////Create DB//////
/////////////////////
*/

DO
$do$
BEGIN
   IF EXISTS (SELECT FROM pg_database WHERE datname = 'library_db') THEN
      RAISE NOTICE 'Database already exists'; 
   ELSE
      EXECUTE 'CREATE DATABASE library_db';
   END IF;
END
$do$;

/*//////////////////////////////////
///////Create Relation Schemas//////
///////////////////////////////////
*/

-- Represents a record of library materials with information on their availability and location.
CREATE TABLE IF NOT EXISTS Catalog (
    catalog_id SERIAL PRIMARY KEY, 
    name VARCHAR(500) NOT NULL UNIQUE, -- The name of the catalog.
	location VARCHAR(500) DEFAULT NULL -- The location of the material within the library.
);

-- Represents the various genres or categories of library materials.
CREATE TABLE IF NOT EXISTS Genre (
    genre_id SERIAL PRIMARY KEY, 
    name VARCHAR(255) NOT NULL UNIQUE, 
    description TEXT -- A brief introduction or description of the genre.
);

-- Represents individual items available in the library, such as books, magazines, e-books, and audiobooks.
CREATE TABLE IF NOT EXISTS Material (
    material_id SERIAL PRIMARY KEY, -- A unique identﬁer for each material.
    title VARCHAR(500) NOT NULL, -- The title of the material.
    publication_date DATE, -- The date of publication of the material
	catalog_id INT DEFAULT NULL, -- A reference to the catalog entry for the material.
	genre_id INT DEFAULT NULL, -- A reference to the genre of the material.
	FOREIGN KEY (catalog_id) 
		REFERENCES Catalog(catalog_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE, 
	FOREIGN KEY (genre_id) 
		REFERENCES Genre(genre_id) 
		ON DELETE SET NULL
		ON UPDATE CASCADE
);

-- Represents library members who can borrow and reserve materials.
CREATE TABLE IF NOT EXISTS Member (
    member_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL, -- The name of the member.
    contact_info VARCHAR(255), -- Email address or phone number of the member.
    join_date DATE NOT NULL -- The date the member joined the library.
);

-- Represents library staff who manage resources and assist members.
CREATE TABLE IF NOT EXISTS Staff (
    staff_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    contact_info VARCHAR(255), -- Email address or phone number of the staff member.
    job_title VARCHAR(100), -- The job title of the staff member (e.g., librarian, assistant librarian).
    hire_date DATE NOT NULL -- The date the staff member was hired by the library.
);

-- Represents the borrowing activity of library materials by members.
CREATE TABLE IF NOT EXISTS Borrow (
    borrow_id SERIAL PRIMARY KEY, 
    material_id INT NOT NULL,
    member_id INT NOT NULL,
    staff_id INT NOT NULL,
	borrow_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    return_date DATE,
	FOREIGN KEY (material_id) 
		REFERENCES Material(material_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE, 
	FOREIGN KEY (member_id) 
		REFERENCES Member(member_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE, 
	FOREIGN KEY (staff_id) 
		REFERENCES Staff(staff_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE, 
	CONSTRAINT check_return_date CHECK (return_date IS NULL OR return_date >= borrow_date),
    CONSTRAINT check_due_date CHECK (due_date >= borrow_date),
	CONSTRAINT unique_identifying_relations UNIQUE (material_id, member_id, borrow_date)
);

-- Represents authors who have created library materials.
CREATE TABLE IF NOT EXISTS Author (
    author_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE, -- The name of the author.
    birth_date DATE DEFAULT NULL,
    nationality VARCHAR(100) DEFAULT NULL -- The nationality of the author (optional).
);

-- Represents the relationship between authors and the materials they have created.
CREATE TABLE IF NOT EXISTS Authorship (
    authorship_id SERIAL PRIMARY KEY, 
    author_id INT NOT NULL,
    material_id INT NOT NULL,
	FOREIGN KEY (author_id) 
		REFERENCES Author(author_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE, 
	FOREIGN KEY (material_id) 
		REFERENCES Material(material_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	CONSTRAINT unique_author_material UNIQUE (author_id, material_id)
);

-- Membership 
CREATE TABLE IF NOT EXISTS Membership (
    member_id INT PRIMARY KEY,
    status VARCHAR(12) DEFAULT 'active' CHECK (status IN ('active', 'deactivated')),
    overdue_occurrences INT DEFAULT 0 CHECK (overdue_occurrences BETWEEN 0 AND 3),
    fee_paid BOOLEAN DEFAULT NULL,
    FOREIGN KEY (member_id) REFERENCES Member(member_id)
);

/*///////////////////
///////Triggers//////
/////////////////////
*/

-- Trigger to synchronize the key sequences for insertions (work around for keys not updating)
-- it basically just gets what the max key is (an Int) and increments it by 1 for the next insertion
CREATE OR REPLACE FUNCTION sync_sequence_on_insert() RETURNS TRIGGER AS $$
DECLARE
    sequence_name TEXT;
BEGIN
    SELECT pg_get_serial_sequence(TG_TABLE_NAME, TG_ARGV[0]) INTO sequence_name;
    
    EXECUTE format('SELECT setval(%L, COALESCE((SELECT MAX(%I) FROM %I), 1) + 1, false)', sequence_name, TG_ARGV[0], TG_TABLE_NAME);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER sync_catalog_sequence_on_insert
AFTER INSERT ON Catalog
FOR EACH ROW
EXECUTE FUNCTION sync_sequence_on_insert('catalog_id');

CREATE TRIGGER sync_genre_sequence_on_insert
AFTER INSERT ON Genre
FOR EACH ROW
EXECUTE FUNCTION sync_sequence_on_insert('genre_id');

CREATE TRIGGER sync_material_sequence_on_insert
AFTER INSERT ON Material
FOR EACH ROW
EXECUTE FUNCTION sync_sequence_on_insert('material_id');

CREATE TRIGGER sync_member_sequence_on_insert
AFTER INSERT ON Member
FOR EACH ROW
EXECUTE FUNCTION sync_sequence_on_insert('member_id');

CREATE TRIGGER sync_staff_sequence_on_insert
AFTER INSERT ON Staff
FOR EACH ROW
EXECUTE FUNCTION sync_sequence_on_insert('staff_id');

CREATE TRIGGER sync_borrow_sequence_on_insert
AFTER INSERT ON Borrow
FOR EACH ROW
EXECUTE FUNCTION sync_sequence_on_insert('borrow_id');

CREATE TRIGGER sync_author_sequence_on_insert
AFTER INSERT ON Author
FOR EACH ROW
EXECUTE FUNCTION sync_sequence_on_insert('author_id');

CREATE TRIGGER sync_authorship_sequence_on_insert
AFTER INSERT ON Authorship
FOR EACH ROW
EXECUTE FUNCTION sync_sequence_on_insert('authorship_id');

/*////////////////////////////////////////
///////init tables with sample data//////
/////////////////////////////////////////
*/
DO $$
BEGIN
	
	IF (SELECT COUNT(*) FROM Catalog) = 0 THEN
        COPY Catalog(catalog_id, name, location)
        FROM '/var/lib/postgresql/init_data/Catalog.csv'
        DELIMITER ','
        CSV HEADER;
    END IF;
	
	IF (SELECT COUNT(*) FROM Genre) = 0 THEN
        COPY Genre(genre_id, name, description)
        FROM '/var/lib/postgresql/init_data/Genre.csv'
        DELIMITER ','
        CSV HEADER;
    END IF;

	IF (SELECT COUNT(*) FROM Material) = 0 THEN
        COPY Material(material_id, title, publication_date, catalog_id, genre_id)
        FROM '/var/lib/postgresql/init_data/Material.csv'
        DELIMITER ','
        CSV HEADER;
    END IF;

	IF (SELECT COUNT(*) FROM Member) = 0 THEN
        COPY Member(member_id, name, contact_info, join_date)
        FROM '/var/lib/postgresql/init_data/Member.csv'
        DELIMITER ','
        CSV HEADER;
    END IF;

    IF (SELECT COUNT(*) FROM Staff) = 0 THEN
        COPY Staff(staff_id, name, contact_info, job_title, hire_date)
        FROM '/var/lib/postgresql/init_data/Staff.csv'
        DELIMITER ','
        CSV HEADER;
    END IF;

    IF (SELECT COUNT(*) FROM Borrow) = 0 THEN
        COPY Borrow(borrow_id, material_id, member_id, staff_id, borrow_date, due_date, return_date)
        FROM '/var/lib/postgresql/init_data/Borrow.csv'
        DELIMITER ','
        CSV HEADER;
    END IF;

    IF (SELECT COUNT(*) FROM Author) = 0 THEN
        COPY Author(author_id, name, birth_date, nationality)
        FROM '/var/lib/postgresql/init_data/Author.csv'
        DELIMITER ','
        CSV HEADER;
    END IF;

    IF (SELECT COUNT(*) FROM Authorship) = 0 THEN
        COPY Authorship(authorship_id, author_id, material_id)
        FROM '/var/lib/postgresql/init_data/Authorship.csv'
        DELIMITER ','
        CSV HEADER;
    END IF;

	-- Auto populate with member_id defaults 
	INSERT INTO Membership (member_id)
    SELECT member_id
    FROM Member
    ON CONFLICT (member_id) DO NOTHING;
	
END $$;

/*
___NOTE___
Making a File Accessible to PostgreSQL Server:
1. sudo cp -r init_data/ /var/lib/postgresql/
2. sudo chown -R postgres:postgres /var/lib/postgresql/init_data
3. sudo chmod 755 /var/lib/postgresql/init_data
4. sudo systemctl restart postgresql
*/



