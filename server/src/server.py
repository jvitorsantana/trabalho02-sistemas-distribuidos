import json
import socket
import threading

from config import Config
from detector import Detector
from protocol import ProtocolError, read_frame, send_frame


class Server:
    def __init__(self, config: Config, detector: Detector) -> None:
        self.config = config
        self.detector = detector
        self._inference_lock = threading.Lock()

    def serve_forever(self) -> None:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server:
            server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            server.bind((self.config.host, self.config.port))
            server.listen(self.config.backlog)

            print(f"[rede] escutando em {self.config.host}:{self.config.port}")
            print("\n[!] Aguardando imagem...\n")

            while True:
                try:
                    conn, addr = server.accept()
                except KeyboardInterrupt:
                    print("\n[rede] encerrando servidor.")
                    break

                threading.Thread(
                    target=self._handle_client, args=(conn, addr), daemon=True
                ).start()

    def _handle_client(self, conn: socket.socket, addr: tuple) -> None:
        client = f"{addr[0]}:{addr[1]}"
        print(f"[conexao] {client} conectado")

        with conn:
            conn.settimeout(self.config.client_timeout)
            try:
                while True:
                    try:
                        jpeg = read_frame(conn)
                    except ConnectionError:
                        break

                    print(f"[conexao] {client} enviou {len(jpeg)} bytes")

                    try:
                        with self._inference_lock:
                            response = self.detector.detect(jpeg)
                        print(
                            f"[deteccao] {client} -> {response['summary'] or 'nada'}"
                            f" ({response['elapsed_ms']} ms)"
                        )
                    except Exception as exc:
                        response = {
                            "ok": False,
                            "objects": [],
                            "summary": [],
                            "message": "Erro ao processar a imagem",
                            "error": str(exc),
                        }
                        print(f"[erro] {client}: {exc}")

                    send_frame(
                        conn, json.dumps(response, ensure_ascii=False).encode("utf-8")
                    )

            except socket.timeout:
                print(f"[conexao] {client} ocioso, desconectado")
            except ProtocolError as exc:
                print(f"[erro] {client} protocolo invalido: {exc}")
            except OSError as exc:
                print(f"[erro] {client} falha de socket: {exc}")

        print(f"[conexao] {client} desconectado")
