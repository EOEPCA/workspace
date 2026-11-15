"""Install PgSTAC and set up the API login in the catalog database."""

import os
import sys

import psycopg
from psycopg import sql
from pypgstac.db import PgstacDB
from pypgstac.migrate import Migrate


try:
    with PgstacDB() as database:
        Migrate(database).run_migration()
except Exception:
    sys.exit("PgSTAC migration failed. Check the database extensions and access.")

with psycopg.connect("") as connection:
    if not connection.execute(
        "SELECT 1 FROM pg_roles WHERE rolname = %s", ("stac_catalog",)
    ).fetchone():
        connection.execute("CREATE ROLE stac_catalog LOGIN")
    connection.execute(
        sql.SQL("ALTER ROLE stac_catalog PASSWORD {}").format(
            sql.Literal(os.environ["CATALOG_PASSWORD"])
        )
    )
    connection.execute("GRANT pgstac_ingest TO stac_catalog")

print("PgSTAC schema and API login are ready.")
