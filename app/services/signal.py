from __future__ import annotations

from app.schemas.signal import TrafficLight

# 要件書 1.4 信号色閾値
_GREEN_THRESHOLD = 0.70
_YELLOW_THRESHOLD = 1.00


def get_signal(actual: float, limit: float) -> TrafficLight:
    """制限値に対する達成率から信号色を決定する。

    0 〜 70%未満 → GREEN
    70 〜 100%未満 → YELLOW
    100%以上 → RED
    """
    if limit <= 0:
        return TrafficLight.RED
    ratio = actual / limit
    if ratio < _GREEN_THRESHOLD:
        return TrafficLight.GREEN
    if ratio < _YELLOW_THRESHOLD:
        return TrafficLight.YELLOW
    return TrafficLight.RED


def get_daily_signals(
    phosphorus_mg: float,
    potassium_mg: float,
    sodium_g: float,
    water_ml: float,
    p_limit: int,
    k_limit: int,
    na_limit: float,
    water_limit: float = 1500.0,
) -> tuple[TrafficLight, TrafficLight, TrafficLight, TrafficLight]:
    """1日分のP/K/Na/水分それぞれの信号色を返す。"""
    return (
        get_signal(phosphorus_mg, p_limit),
        get_signal(potassium_mg, k_limit),
        get_signal(sodium_g, na_limit),
        get_signal(water_ml, water_limit),
    )
