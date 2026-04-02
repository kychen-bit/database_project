from typing import Any

from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware

from backend.database import execute_query

app = FastAPI(title="Animal Rescue Dashboard API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/api/funds-sankey")
def get_funds_sankey(days: int = Query(365, ge=1, le=3650)) -> list[dict[str, Any]]:
    sql = """
    SELECT
        TransType,
        SUM(Amount) AS TotalAmount
    FROM dbo.TransactionSummary
    WHERE TransDate >= DATEADD(DAY, -?, SYSDATETIME())
    GROUP BY TransType
    ORDER BY TotalAmount DESC;
    """
    rows = execute_query(sql, (days,))
    return [
        {
            "name": row["TransType"],
            "value": float(row["TotalAmount"]),
        }
        for row in rows
    ]


@app.get("/api/device-heatmap")
def get_device_heatmap(days: int = Query(30, ge=1, le=3650)) -> list[dict[str, Any]]:
    sql = """
    SELECT
        DeviceID,
        DATEPART(HOUR, EventTime) AS [Hour],
        COUNT(1) AS EventCount
    FROM dbo.DeviceLog
    WHERE EventTime >= DATEADD(DAY, -?, SYSDATETIME())
    GROUP BY DeviceID, DATEPART(HOUR, EventTime)
    ORDER BY DeviceID ASC, [Hour] ASC;
    """
    rows = execute_query(sql, (days,))
    return [
        {
            "deviceId": int(row["DeviceID"]),
            "hour": int(row["Hour"]),
            "count": int(row["EventCount"]),
        }
        for row in rows
    ]


@app.get("/api/top-adopters")
def get_top_adopters(
    min_animals: int = Query(2, ge=1, le=100),
) -> list[dict[str, Any]]:
    sql = """
    SELECT
        pu.UserID,
        pu.UserName,
        COUNT(DISTINCT ca.AnimalID) AS AnimalCount,
        SUM(ca.MonthlyAmount) AS TotalAmount
    FROM dbo.PlatformUser AS pu
    INNER JOIN dbo.CloudAdoption AS ca
        ON pu.UserID = ca.UserID
    GROUP BY pu.UserID, pu.UserName
    HAVING COUNT(DISTINCT ca.AnimalID) >= ?
    ORDER BY TotalAmount DESC, pu.UserID ASC;
    """
    rows = execute_query(sql, (min_animals,))
    return [
        {
            "userId": int(row["UserID"]),
            "userName": row["UserName"],
            "animalCount": int(row["AnimalCount"]),
            "totalAmount": float(row["TotalAmount"]),
        }
        for row in rows
    ]
