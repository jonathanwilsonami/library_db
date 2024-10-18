-- Install: sudo apt-get install postgresql-16-pgtap
-- CREATE EXTENSION pgtap; -- Run this one to enble 
SET client_min_messages = NOTICE;

ROLLBACK;
BEGIN;

-- Number of tests you want to run 
SELECT plan(2);

SELECT diag('Test that the Material table has exactly 31 rows');
SELECT is( (SELECT count(*) FROM Material)::int, 31, 'Table has 31 rows');

SELECT diag('Test that the Catalog table has exactly 10 rows');
SELECT is( (SELECT count(*) FROM Catalog)::int, 10, 'Table has 10 rows');

SELECT * FROM finish();
ROLLBACK;

-- To Run
-- pg_prove -d library_db -f library_unit_testing.sql