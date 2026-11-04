"""Keep STAC links on the notebook's local Kubernetes proxy."""

import os
from urllib.parse import urlsplit

from stac_fastapi.pgstac.app import create_app as stac_app


def create_app():
    app = stac_app()
    origin = urlsplit(os.environ["LOCAL_API_ORIGIN"])

    @app.middleware("http")
    async def local_links(request, call_next):
        # The Kubernetes proxy replaces Host with the gateway address.
        request.scope["scheme"] = origin.scheme
        request.scope["headers"] = [
            (key, value) for key, value in request.scope["headers"]
            if key not in {b"host", b"forwarded"} and not key.startswith(b"x-forwarded-")
        ] + [(b"host", origin.netloc.encode("ascii"))]
        return await call_next(request)

    return app
