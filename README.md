# Trabalho 02 — Detector de objetos (cliente–servidor)

Aplicativo Flutter captura uma foto, envia o JPEG por TCP até um servidor Python e recebe o resultado da detecção de objetos. A comunicação usa um protocolo simples: **4 bytes de tamanho (big-endian) + payload**.

```
app_detector/     # cliente Flutter (câmera + socket)
server/           # servidor Python (socket + YOLO)
  src/            # main.py, server.py, protocol.py, detector.py
models/           # pesos YOLO (yolo11n.pt)
```

---

## Como rodar o servidor (Python)

Requisitos: **Python 3.12+** e [uv](https://docs.astral.sh/uv/).

1. Coloque o arquivo de pesos em `models/yolo11n.pt` (na raiz do repositório **ou** em `server/models/`, conforme o diretório de onde o processo for iniciado; o caminho usado no código é `models/yolo11n.pt`).
2. Instale as dependências e suba o servidor a partir da pasta `server/`:

```bash
cd server
uv sync
uv run python src/main.py
```

O servidor escuta em `0.0.0.0:25565` e imprime o IP local da máquina. Imagens anotadas são gravadas em `server/assets/`.

Teste opcional (sem o app), com uma foto em disco:

```bash
uv run python src/test.py caminho/da/imagem.jpg
```

---

## Como rodar o app (Flutter)

Requisitos: [Flutter SDK](https://docs.flutter.dev/get-started/install) e um emulador/dispositivo Android (a câmera é necessária).

```bash
cd app_detector
flutter pub get
flutter run
```

No emulador Android, o host padrão `10.0.2.2` aponta para o computador que está rodando o servidor. Em um celular físico, use o IP da máquina na mesma rede Wi-Fi (o valor impresso pelo `main.py`).

---

## Como configurar o IP e a porta

| Onde | Padrão | Como alterar |
|------|--------|----------------|
| Servidor | host `0.0.0.0`, porta `25565` | Constantes `HOST` e `PORT` em `server/src/main.py` |
| App | host `10.0.2.2`, porta `25565` | Ícone de engrenagem (ou **Alterar**) na tela inicial; valores iniciais em `app_detector/lib/screens/home_screen.dart` |

Servidor e app precisam usar a **mesma porta**. O host no app deve ser alcançável a partir do dispositivo (emulador: `10.0.2.2`; dispositivo físico: IP LAN do PC).

---

## Capturas de tela

**App**

- [coloque o link da foto aqui]

**Imagem capturada**

- [coloque o link da foto aqui]

**Resultado da detecção**

- [coloque o link da foto aqui]



## Modelo / biblioteca de detecção

- Biblioteca: **[Ultralytics](https://docs.ultralytics.com/)** (`ultralytics`), com **OpenCV** (`cv2`) para decodificar o JPEG e salvar a imagem anotada.
- Modelo: **YOLO11 nano** — arquivo `models/yolo11n.pt` (`YOLO('models/yolo11n.pt')`).
- Parâmetros usados: `imgsz=640`, confiança mínima `0.5`.
- Demais dependências do servidor: `torch` / `torchvision` (CPU, índice PyTorch no `pyproject.toml`).
