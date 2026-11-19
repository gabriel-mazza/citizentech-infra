import os
from http.server import BaseHTTPRequestHandler, HTTPServer

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            body = b"OK"
        else:
            body = (b"<h1>CitizenTech - Deslocai</h1>"
                    b"<p>Aplicacao web no ar, provisionada via Shell Script.</p>")
        self.send_response(200)
        self.end_headers()
        self.wfile.write(body)

port = int(os.environ.get("APP_PORT", "8080"))
HTTPServer(("0.0.0.0", port), Handler).serve_forever()
