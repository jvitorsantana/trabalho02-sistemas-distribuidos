import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent


def _env_str(key: str, default: str) -> str:
    return os.getenv(key, default)


def _env_int(key: str, default: int) -> int:
    try:
        return int(os.getenv(key, default))
    except ValueError:
        return default


def _env_float(key: str, default: float) -> float:
    try:
        return float(os.getenv(key, default))
    except ValueError:
        return default


class Config:
    host: str = _env_str("SERVER_HOST", "0.0.0.0")
    port: int = _env_int("SERVER_PORT", 25565)
    backlog: int = 5
    client_timeout: float = _env_float("CLIENT_TIMEOUT", 120.0)

    model_path: str = _env_str("MODEL_PATH", "models/yolo11x.pt")
    conf_threshold: float = _env_float("CONF_THRESHOLD", 0.35)
    imgsz: int = _env_int("IMGSZ", 1280)
    device: str = _env_str("DEVICE", "auto")
