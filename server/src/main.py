import socket

from detector import Detector
from server import Server

HOST = '0.0.0.0'
PORT = 25565

def local_ip():
  with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
    try:
      s.connect(('1.1.1.1', 80))
      return s.getsockname()[0]
    except:
      return '127.0.0.1'

def main():
  print(f'IP: {local_ip()} | PORTA: {PORT}')
  Server(HOST, PORT, Detector()).start()


if __name__ == '__main__':
  main()
