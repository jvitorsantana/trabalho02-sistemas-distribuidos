import cv2
import time
import torch
import numpy as np
from ultralytics import YOLO
from datetime import datetime

from config import Config


def describe(label: str, count: int = 1) -> str:
    return f"{label} detected" if count <= 1 else f"{label} detected ({count})"


class Detector:
    def __init__(self, config: Config) -> None:
        self.config = config
        self.device = self._resolve_device(config.device)

        print(f"[modelo] carregando '{config.model_path}' em {self.device}...")
        self.model = YOLO(config.model_path)
        self._warmup()
        print(f"[modelo] pronto.")

    @staticmethod
    def _resolve_device(device: str) -> str:
        if device != "auto":
            return device
        return "cuda:0" if torch.cuda.is_available() else "cpu"

    def _warmup(self) -> None:
        blank = np.zeros((self.config.imgsz, self.config.imgsz, 3), dtype=np.uint8)
        self.model.predict(blank, device=self.device, verbose=False)

    def detect(self, jpeg_bytes: bytes) -> dict:
        started = time.perf_counter()

        buffer = np.frombuffer(jpeg_bytes, dtype=np.uint8)
        frame = cv2.imdecode(buffer, cv2.IMREAD_COLOR)
        if frame is None:
            raise ValueError("O payload recebido não é um JPEG válido.")

        h, w = frame.shape[:2]
        stem = datetime.now().strftime("%Y%m%d_%H%M%S_%f")[:-3]
        result = self.model.predict(
            frame,
            imgsz=self.config.imgsz,
            conf=self.config.conf_threshold,
            device=self.device,
            verbose=False,
        )[0]

        grouped: dict[str, dict] = {}
        for box in result.boxes:
            label = result.names[int(box.cls.item())]
            confidence = float(box.conf.item())
            entry = grouped.setdefault(label, {"count": 0, "confidence": 0.0})
            entry["count"] += 1
            entry["confidence"] = max(entry["confidence"], confidence)

        objects = [
            {
                "label": label,
                "count": data["count"],
                "confidence": round(data["confidence"], 4),
            }
            for label, data in sorted(
                grouped.items(),
                key=lambda kv: (-kv[1]["count"], -kv[1]["confidence"]),
            )
        ]

        elapsed_ms = int((time.perf_counter() - started) * 1000)
        summary = [describe(o["label"], o["count"]) for o in objects]

        return {
            "ok": True,
            "objects": objects,
            "summary": summary,
            "message": summary[0] if summary else "Nada Detectado",
            "image": f"{stem}.jpg",
            "width": w,
            "height": h,
            "elapsed_ms": elapsed_ms,
            "device": self.device,
        }
