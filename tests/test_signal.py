from __future__ import annotations

import pytest

from app.services.signal import get_signal, get_daily_signals
from app.schemas.signal import TrafficLight


class TestGetSignal:
    def test_zero_is_green(self):
        assert get_signal(0.0, 2000.0) == TrafficLight.GREEN

    def test_below_70_percent_is_green(self):
        # 69.9% → GREEN
        assert get_signal(1397.9, 2000.0) == TrafficLight.GREEN

    def test_exactly_70_percent_is_yellow(self):
        # 70% → YELLOW
        assert get_signal(1400.0, 2000.0) == TrafficLight.YELLOW

    def test_between_70_and_100_is_yellow(self):
        # 85% → YELLOW
        assert get_signal(1700.0, 2000.0) == TrafficLight.YELLOW

    def test_99_9_percent_is_yellow(self):
        assert get_signal(1999.9, 2000.0) == TrafficLight.YELLOW

    def test_exactly_100_percent_is_red(self):
        assert get_signal(2000.0, 2000.0) == TrafficLight.RED

    def test_over_100_is_red(self):
        assert get_signal(2500.0, 2000.0) == TrafficLight.RED

    def test_zero_limit_returns_red(self):
        assert get_signal(100.0, 0.0) == TrafficLight.RED

    def test_sodium_boundary(self):
        # 塩分: 限度 6.0g, 4.19g → 69.8% → GREEN
        assert get_signal(4.19, 6.0) == TrafficLight.GREEN
        # 4.20g → 70% → YELLOW
        assert get_signal(4.20, 6.0) == TrafficLight.YELLOW
        # 6.0g → 100% → RED
        assert get_signal(6.0, 6.0) == TrafficLight.RED


class TestGetDailySignals:
    def test_all_green(self):
        p, k, na, w = get_daily_signals(500, 1000, 3.0, 1000.0, 800, 2000, 6.0, 1500.0)
        assert p == TrafficLight.GREEN
        assert k == TrafficLight.GREEN
        assert na == TrafficLight.GREEN
        assert w == TrafficLight.GREEN

    def test_mixed(self):
        # P: 640/800 = 80% → YELLOW, K: 2100/2000 = 105% → RED, Na: 3.0/6.0 = 50% → GREEN, Water: 1000/1500 = 66% → GREEN
        p, k, na, w = get_daily_signals(640, 2100, 3.0, 1000.0, 800, 2000, 6.0, 1500.0)
        assert p == TrafficLight.YELLOW
        assert k == TrafficLight.RED
        assert na == TrafficLight.GREEN
        assert w == TrafficLight.GREEN
