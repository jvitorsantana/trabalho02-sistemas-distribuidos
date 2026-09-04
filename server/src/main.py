import argparse

from config import Config
from detector import Detector
from server import Server

def main():
    parser = argparse.ArgumentParser(description="Servidor de deteccao de objetos")
    parser.add_argument("--host")
    parser.add_argument("--port", type=int)
    parser.add_argument("--model", help="caminho do peso .pt")
    parser.add_argument("--conf", type=float, help="confianca minima (0-1)")
    parser.add_argument("--device", help="auto | cpu | 0")
    args = parser.parse_args()

    config = Config()
    if args.host:
        config.host = args.host
    if args.port:
        config.port = args.port
    if args.model:
        config.model_path = args.model
    if args.conf is not None:
        config.conf_threshold = args.conf
    if args.device:
        config.device = args.device

    print(f"• Porta            : {config.port}")
    print(f"• Confiança mínima : {config.conf_threshold}")

    detector = Detector(config)
    Server(config, detector).serve_forever()


if __name__ == "__main__":
    main()
