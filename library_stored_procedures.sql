CREATE OR REPLACE PROCEDURE drop_all_objects_in_schema(schema_name TEXT)
LANGUAGE plpgsql
AS
$do$
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
END
$do$;

-- Usage: call drop_all_objects_in_schema('public')