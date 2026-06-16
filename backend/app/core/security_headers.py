from starlette.datastructures import MutableHeaders
from starlette.types import ASGIApp, Message, Receive, Scope, Send


_BASE_SECURITY_HEADERS = {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "Referrer-Policy": "strict-origin-when-cross-origin",
    "X-XSS-Protection": "0",
    "Cross-Origin-Opener-Policy": "same-origin",
    "Cross-Origin-Resource-Policy": "cross-origin",
    "Permissions-Policy": (
        "accelerometer=(), autoplay=(), camera=(), display-capture=(), "
        "encrypted-media=(), fullscreen=(), geolocation=(), gyroscope=(), "
        "magnetometer=(), microphone=(), midi=(), payment=(), usb=()"
    ),
}

_HSTS_VALUE = "max-age=63072000; includeSubDomains; preload"

_API_CSP = (
    "default-src 'none'; "
    "base-uri 'none'; "
    "form-action 'none'; "
    "frame-ancestors 'none'"
)

_DOCS_CSP = (
    "default-src 'self'; "
    "script-src 'self' https://cdn.jsdelivr.net 'unsafe-inline'; "
    "style-src 'self' https://cdn.jsdelivr.net https://fonts.googleapis.com 'unsafe-inline'; "
    "img-src 'self' data: https://cdn.jsdelivr.net https://fastapi.tiangolo.com; "
    "font-src 'self' https://cdn.jsdelivr.net https://fonts.gstatic.com; "
    "worker-src 'self' blob:; "
    "connect-src 'self'; "
    "base-uri 'none'; "
    "frame-ancestors 'none'"
)

_DOCS_PREFIXES = ("/docs", "/redoc")


def _is_https(scope: Scope) -> bool:
    if scope.get("scheme") == "https":
        return True
    for name, value in scope.get("headers") or []:
        if name == b"x-forwarded-proto":
            return value.decode("latin-1").split(",")[0].strip() == "https"
    return False


class SecurityHeadersMiddleware:
    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        path = scope.get("path", "")
        is_docs = path.startswith(_DOCS_PREFIXES)
        https = _is_https(scope)

        async def send_with_headers(message: Message) -> None:
            if message["type"] == "http.response.start":
                headers = MutableHeaders(raw=message.setdefault("headers", []))
                for key, value in _BASE_SECURITY_HEADERS.items():
                    headers[key] = value
                headers["Content-Security-Policy"] = _DOCS_CSP if is_docs else _API_CSP
                if https:
                    headers["Strict-Transport-Security"] = _HSTS_VALUE
            await send(message)

        await self.app(scope, receive, send_with_headers)
