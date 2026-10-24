"""Resolve notebook links against the source tree when building the site."""

from html import escape, unescape
import posixpath
import re
from urllib.parse import urlsplit, urlunsplit

from mkdocs.utils import get_relative_url


def on_page_content(html, page, config, files):
    # The notebook renderer skips MkDocs' normal Markdown link conversion.
    if not page.file.src_uri.endswith(".ipynb"):
        return html

    def resolve(match):
        url = urlsplit(unescape(match[1]))
        if url.scheme or url.netloc or not url.path or url.path.startswith("/"):
            return match[0]
        source = posixpath.normpath(
            posixpath.join(posixpath.dirname(page.file.src_uri), url.path)
        )
        target = files.get_file_from_path(source)
        if target is None:
            return match[0]
        href = urlunsplit((
            "", "", get_relative_url(target.url, page.url), url.query, url.fragment
        ))
        return f'href="{escape(href, quote=True)}"'

    return re.sub(r'href="([^"]+)"', resolve, html)
