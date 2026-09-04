import socket
import struct

HEADER = '!I'
HEADER_SIZE = 4
MAX_PAYLOAD_SIZE = 32 * 1024 * 1024  # 32MB

def recv_exactly(sock: socket.socket, size: int):
  chunks = []
  reaming = size
  while reaming > 0:
    chunk = sock.recv(min(reaming, 64 * 1024))
    if not chunk:
      raise ConnectionError(
        f'Conexão encerrada pelo cliente! Ainda restavam {reaming} de {size} bytes.'
      )

    chunks.append(chunk)
    reaming -= len(chunk)

  return b''.join(chunks)


def read_frame(sock: socket.socket):
  (size,) = struct.unpack(HEADER, recv_exactly(sock, HEADER_SIZE))
  if not 0 < size <= MAX_PAYLOAD_SIZE:
    raise ValueError('Tamanho recebido inválido.')
  return recv_exactly(sock, size)


def send_frame(sock: socket.socket, payload):
  sock.sendall(struct.pack(HEADER, len(payload)) + payload)
