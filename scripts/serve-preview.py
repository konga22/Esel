"""로컬 Expo 웹 미리보기. 화면 주소로 새로고침해도 앱을 연다."""

from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlsplit

BUILD = Path(__file__).resolve().parents[1] / ".codex/temp/prototype/20260905-esel-gallery/src"


class PreviewHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(BUILD), **kwargs)

    def do_GET(self):
        route = unquote(urlsplit(self.path).path)
        if not Path(route).suffix and not Path(self.translate_path(self.path)).is_file():
            self.path = "/index.html"
        super().do_GET()


if __name__ == "__main__":
    if not (BUILD / "index.html").is_file():
        raise SystemExit("먼저 npm run build:web을 실행해주세요.")
    print("Esel 미리보기: http://localhost:4173", flush=True)
    ThreadingHTTPServer(("127.0.0.1", 4173), PreviewHandler).serve_forever()
