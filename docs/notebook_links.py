"""Resolve notebook links against the source tree when building the site."""

from html import escape, unescape
from html.parser import HTMLParser
import posixpath
import re
from urllib.parse import urlsplit, urlunsplit

from mkdocs.utils import get_relative_url


def collapse_code(html):
    """Put tagged notebook cells in a closed HTML details element."""
    offsets = [0]
    for line in html.splitlines(keepends=True):
        offsets.append(offsets[-1] + len(line))
    insertions = []

    class Cells(HTMLParser):
        depth = 0
        folded = None

        def position(self):
            line, column = self.getpos()
            return offsets[line - 1] + column

        def handle_starttag(self, tag, attrs):
            if tag != "div":
                return
            self.depth += 1
            classes = dict(attrs).get("class", "").split()
            if (self.folded is None and "jp-CodeCell" in classes
                    and "celltag_collapse-input" in classes):
                self.folded = self.depth
                insertions.append((self.position(),
                                   "<details><summary>Notebook functions</summary>"))

        def handle_endtag(self, tag):
            if tag != "div":
                return
            if self.depth == self.folded:
                insertions.append((self.position() + len("</div>"), "</details>"))
                self.folded = None
            self.depth -= 1

    Cells().feed(html)
    for position, markup in reversed(insertions):
        html = html[:position] + markup + html[position:]
    return html


def on_page_content(html, page, config, files):
    # The notebook renderer skips MkDocs' normal Markdown link conversion.
    if not page.file.src_uri.endswith(".ipynb"):
        return html

    def resolve(match):
        url = urlsplit(unescape(match[2]))
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
        return f'{match[1]}="{escape(href, quote=True)}"'

    html = re.sub(r'\b(href|src)="([^"]+)"', resolve, html)
    return collapse_code(html)
