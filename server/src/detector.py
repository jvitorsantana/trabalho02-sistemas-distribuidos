import time
from datetime import datetime
from pathlib import Path

import cv2
import numpy as np
from ultralytics import YOLO

MODEL_PATH = 'models/yolo11n.pt'
IMGSIZE = 640
CONFIDENCE = 0.5
CAPTURES_DIR = Path(__file__).resolve().parent.parent / 'assets'

class Detector:
  def __init__(self) -> None:
    CAPTURES_DIR.mkdir(exist_ok=True)
    self.model = YOLO(MODEL_PATH)

  def detect(self, jpg_bytes):
    started = time.perf_counter()

    frame = cv2.imdecode(np.frombuffer(jpg_bytes, np.uint8), cv2.IMREAD_COLOR)
    if frame is None:
      raise ValueError('O payload recebido não é um JPEG/JPG válido')

    result = self.model.predict(
      frame,
      imgsz = IMGSIZE,
      conf = CONFIDENCE,
      verbose = False
    )[0]

    name = datetime.now().strftime('%d%m%Y_%H%M%S')[:-3] + '.jpg'
    cv2.imwrite(str(CAPTURES_DIR / name), result.plot())

    counts = {}
    for box in result.boxes:
      label = result.names[int(box.cls)]
      counts[label] = counts.get(label, 0) + 1

    summary = [
      f'{label} detected' if n == 1 else f'{label} detected ({n})'
      for label, n in sorted(counts.items(), key=lambda kv: -kv[1])
    ]

    return {
      'summary': summary,
      'message': summary[0] if summary else 'Nada detectado',
      'image': name,
      'elapsed_ms': int((time.perf_counter() - started) * 1000)
    }