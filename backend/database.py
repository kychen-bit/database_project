import os
from contextlib import contextmanager
from typing import Any, Iterable

import pyodbc


def _resolve_driver() -> str:
    env_driver = os.getenv("DB_DRIVER")
    if env_driver:
        return env_driver

    installed = set(pyodbc.drivers())
    preferred = [
        "ODBC Driver 18 for SQL Server",
        "ODBC Driver 17 for SQL Server",
        "SQL Server",
    ]
    for driver in preferred:
        if driver in installed:
            return driver

    return "SQL Server"


def _build_connection_string() -> str:
    driver = _resolve_driver()
    server = os.getenv("DB_SERVER", "localhost")
    database = os.getenv("DB_DATABASE", "AnimalRescueDB")
    username = os.getenv("DB_USERNAME")
    password = os.getenv("DB_PASSWORD")

    if username and password:
        return (
            f"DRIVER={{{driver}}};"
            f"SERVER={server};"
            f"DATABASE={database};"
            f"UID={username};"
            f"PWD={password};"
            "TrustServerCertificate=yes;"
        )

    return (
        f"DRIVER={{{driver}}};"
        f"SERVER={server};"
        f"DATABASE={database};"
        "Trusted_Connection=yes;"
        "TrustServerCertificate=yes;"
    )


@contextmanager
def get_connection():
    conn = pyodbc.connect(_build_connection_string())
    try:
        yield conn
    finally:
        conn.close()


def execute_query(sql: str, params: Iterable[Any] = ()) -> list[dict[str, Any]]:
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(sql, tuple(params))
        columns = [col[0] for col in cursor.description] if cursor.description else []
        rows = cursor.fetchall()
        return [dict(zip(columns, row)) for row in rows]
