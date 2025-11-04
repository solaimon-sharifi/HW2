import time
import requests


BASE = "http://localhost:8000"


def wait_for_api(timeout=60):
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            r = requests.get(f"{BASE}/health", timeout=2)
            if r.status_code == 200:
                return True
        except Exception:
            pass
        time.sleep(1)
    raise RuntimeError("API did not become ready in time")


def test_full_workflow():
    wait_for_api()

    # list users
    r = requests.get(f"{BASE}/users/")
    assert r.status_code == 200
    users = r.json()

    # create a user 'carol' (if it already exists the API will return 400; handle by finding)
    carol_id = None
    for u in users:
        if u.get("username") == "carol":
            carol_id = u.get("id")
            break

    if carol_id is None:
        r = requests.post(f"{BASE}/users/", json={"username": "carol", "email": "carol@example.com"})
        assert r.status_code in (200, 201)
        created = r.json()
        carol_id = created.get("id")

    assert carol_id is not None

    # create a calculation for carol
    calc_payload = {"operation": "add", "operand_a": 2, "operand_b": 3, "result": 5, "user_id": carol_id}
    r = requests.post(f"{BASE}/calculations/", json=calc_payload)
    assert r.status_code in (200, 201)
    calc = r.json()
    calc_id = calc.get("id")
    assert calc_id is not None

    # list calculations and ensure it's present
    r = requests.get(f"{BASE}/calculations/")
    assert r.status_code == 200
    calcs = r.json()
    assert any(c.get("id") == calc_id for c in calcs)

    # update calculation result
    r = requests.patch(f"{BASE}/calculations/{calc_id}", json={"result": 6})
    assert r.status_code == 200
    updated = r.json()
    assert updated.get("result") == 6

    # delete calculation
    r = requests.delete(f"{BASE}/calculations/{calc_id}")
    assert r.status_code == 200

    # verify deleted
    r = requests.get(f"{BASE}/calculations/")
    assert r.status_code == 200
    calcs_after = r.json()
    assert not any(c.get("id") == calc_id for c in calcs_after)

    # update user
    r = requests.patch(f"{BASE}/users/{carol_id}", json={"email": "carol@newdomain.com"})
    assert r.status_code == 200
    u = r.json()
    assert u.get("email") == "carol@newdomain.com"

    # delete user
    r = requests.delete(f"{BASE}/users/{carol_id}")
    assert r.status_code == 200

    # verify user deleted
    r = requests.get(f"{BASE}/users/")
    assert r.status_code == 200
    users_after = r.json()
    assert not any(u.get("id") == carol_id for u in users_after)
