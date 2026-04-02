from fastapi.testclient import TestClient

from backend.main import app


client = TestClient(app)


def test_health_endpoint():
    response = client.get('/health')
    assert response.status_code == 200
    assert response.json()['status'] == 'ok'


def test_funds_sankey(monkeypatch):
    def fake_execute_query(sql, params=()):
        assert 'GROUP BY TransType' in sql
        assert params == (365,)
        return [
            {'TransType': 'ADOPTION_DEBIT', 'TotalAmount': 1200.0},
            {'TransType': 'DONATION_INCOME', 'TotalAmount': 3000.0},
        ]

    monkeypatch.setattr('backend.main.execute_query', fake_execute_query)
    response = client.get('/api/funds-sankey')
    assert response.status_code == 200
    assert response.json()[0]['name'] == 'ADOPTION_DEBIT'


def test_device_heatmap(monkeypatch):
    def fake_execute_query(sql, params=()):
        assert 'DATEPART(HOUR, EventTime)' in sql
        assert params == (30,)
        return [
            {'DeviceID': 1, 'Hour': 8, 'EventCount': 9},
            {'DeviceID': 1, 'Hour': 9, 'EventCount': 12},
        ]

    monkeypatch.setattr('backend.main.execute_query', fake_execute_query)
    response = client.get('/api/device-heatmap')
    assert response.status_code == 200
    payload = response.json()
    assert payload[0]['hour'] == 8
    assert payload[1]['count'] == 12


def test_top_adopters(monkeypatch):
    def fake_execute_query(sql, params=()):
        assert 'INNER JOIN dbo.CloudAdoption' in sql
        assert params == (2,)
        return [
            {'UserID': 10, 'UserName': 'alice', 'AnimalCount': 3, 'TotalAmount': 450.0},
        ]

    monkeypatch.setattr('backend.main.execute_query', fake_execute_query)
    response = client.get('/api/top-adopters')
    assert response.status_code == 200
    payload = response.json()
    assert payload[0]['userName'] == 'alice'
    assert payload[0]['animalCount'] == 3
