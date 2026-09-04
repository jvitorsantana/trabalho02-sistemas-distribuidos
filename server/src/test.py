import json
import socket
import sys
from pathlib import Path

from protocol import read_frame, send_frame

HOST = '127.0.0.1'
PORT = 25565

def main():
  if len(sys.argv) < 2:
    sys.exit('src/test.py <imagem.jpg|jpeg> [host] [porta]')


  image = Path(sys.argv[1])
  host = sys.argv[2] if len(sys.argv) > 2 else HOST
  port = int(sys.argv[3]) if len(sys.argv) > 3 else PORT

  if not image.is_file():
    sys.exit(f'arquivo não encontrado')

  payload = image.read_bytes()
  print(f'enviando fota({len(payload)} bytes) para {host}:{port}')

  with socket.create_connection((host, port), timeout=30) as s:
    send_frame(s, payload)
    response = json.loads(read_frame(s).decode('utf-8'))

  print(json.dumps(response, indent=2, ensure_ascii=False))


if __name__ == '__main__':
  main()