import json
import socket
import threading

from detector import Detector
from protocol import read_frame, send_frame

class Server:
  def __init__(self, host, port, detector: Detector):
    self.host = host
    self.port = port
    self.detector = detector
    self._lock = threading.Lock()


  def start(self):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server:
      server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
      server.bind((self.host, self.port))
      server.listen(5)

      server.settimeout(1.0)

      print(f'[rede] escutando em {self.host}:{self.port}')
      print('\n[!] Aguardando imagem...\n')

      try:
        while True:
          try:
            conn, addr = server.accept()
          except socket.timeout:
            continue
          threading.Thread(target=self._handle, args=(conn, addr), daemon=True).start()
      except KeyboardInterrupt:
        print('\n[rede] encerrando servidor.')

  def _handle(self, conn: socket.socket, addr: tuple):
    client = f'{addr[0]}:{addr[1]}'
    print(f'Cliente[{client}] conectado!')

    with conn:
      try:
        while True:
          try:
            jpg = read_frame(conn)
          except ConnectionError:
            break
          print(f'Cliente[{client}] enviou {len(jpg)} bytes')

          try:
            with self._lock:
              response = self.detector.detect(jpg)
            print(f'Cliente[{client}] -> {response['message']}')

          except Exception as e:
            response = {'summary': [], 'message': 'Erro ao processar a fota'}
            print(f'Erro no cliente[{client}]: {e}')

          send_frame(conn, json.dumps(response, ensure_ascii=False).encode('utf-8'))
      except (ValueError, OSError) as e:
        print(f'Erro técnico ({client}): {e}')


    print(f'Cliente[{client}] desconectado')