import socket
import struct

HEADER_FORMAT = "!I"
HEADER_SIZE = struct.calcsize(HEADER_FORMAT)
MAX_PAYLOAD_SIZE = 32 * 1024 * 1024  # 32MB


class ProtocolError(Exception):
    pass


def recv_exactly(sock: socket.socket, size: int) -> bytes:
    chunks = []
    reaming = size
    while reaming > 0:
        chunk = sock.recv(min(reaming, 64 * 1024))
        if not chunk:
            raise ConnectionError(
                f"Conexão encerrada pelo cliente! Ainda restavam {reaming} de {size} bytes."
            )

        chunks.append(chunk)
        reaming -= len(chunk)

    return b"".join(chunks)


def read_frame(sock: socket.socket) -> bytes:
    header = recv_exactly(sock, HEADER_SIZE)
    (size,) = struct.unpack(HEADER_FORMAT, header)

    if size == 0:
        raise ProtocolError("Tamanho declarado é zero.")

    if size > MAX_PAYLOAD_SIZE:
        raise ProtocolError(
            f"Tamanho declarado ({size} bytes) excede o limite máximo permitido de {MAX_PAYLOAD_SIZE}"
        )

    return recv_exactly(sock, size)


def send_frame(sock: socket.socket, payload: bytes) -> None:
    sock.sendall(struct.pack(HEADER_FORMAT, len(payload)) + payload)
