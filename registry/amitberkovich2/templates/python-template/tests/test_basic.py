from app.services.example_service import calculate_sum

def test_sum():
    assert calculate_sum(2, 3) == 5