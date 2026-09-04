import argparse
import json
import socket
import struct
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("image", type=Path)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=25565)
    args = parser.parse_args()

    if not args.image.is_file():
        sys.exit(f"arquivo nao encontrado: {args.image}")

    payload = args.image.read_bytes()
    print(f"enviando {len(payload)} bytes para {args.host}:{args.port}...")

    with socket.create_connection((args.host, args.port), timeout=30) as sock:
        sock.sendall(struct.pack("!I", len(payload)) + payload)

        header = sock.recv(4)
        (size,) = struct.unpack("!I", header)

        chunks, remaining = [], size
        while remaining > 0:
            chunk = sock.recv(min(remaining, 65536))
            if not chunk:
                sys.exit("conexao fechada no meio da resposta")
            chunks.append(chunk)
            remaining -= len(chunk)

    response = json.loads(b"".join(chunks).decode("utf-8"))
    print(json.dumps(response, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
