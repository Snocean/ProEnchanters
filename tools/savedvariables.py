"""Minimal reader for WoW SavedVariables files.

SavedVariables are Lua files made of top-level assignments (`Name = { ... }`)
written by the client with a small, regular subset of Lua: nested tables with
`["key"] =` / `[number] =` keys or positional entries, strings, numbers,
booleans and nil. This parses that subset into Python dicts (tables whose keys
are exactly 1..n become lists), so dev scripts can read captures such as
PEProbe's without needing a Lua interpreter.
"""

import re
import sys

_TOKEN = re.compile(
    r"""\s*(?:
        (?P<comment>--[^\n]*)
      | (?P<string>"(?:\\.|[^"\\])*")
      | (?P<number>-?(?:0x[0-9a-fA-F]+|\d+\.?\d*(?:[eE][-+]?\d+)?|\.\d+(?:[eE][-+]?\d+)?))
      | (?P<name>[A-Za-z_][A-Za-z0-9_]*)
      | (?P<punct>[{}\[\]=,;])
    )""",
    re.VERBOSE,
)

_ESCAPES = {"n": "\n", "t": "\t", "r": "\r", "\\": "\\", '"': '"', "'": "'", "a": "\a", "b": "\b", "f": "\f", "v": "\v"}


def _unescape(body):
    out, i = [], 0
    while i < len(body):
        ch = body[i]
        if ch != "\\":
            out.append(ch)
            i += 1
            continue
        nxt = body[i + 1]
        if nxt.isdigit():
            digits = re.match(r"\d{1,3}", body[i + 1:]).group(0)
            out.append(chr(int(digits)))
            i += 1 + len(digits)
        elif nxt == "\n":
            out.append("\n")
            i += 2
        else:
            out.append(_ESCAPES.get(nxt, nxt))
            i += 2
    # The client writes UTF-8 bytes; \ddd escapes are single bytes of it.
    return "".join(out).encode("latin-1", errors="surrogateescape").decode("utf-8", errors="replace")


def _tokens(text):
    pos = 0
    while pos < len(text):
        match = _TOKEN.match(text, pos)
        if not match or match.end() == pos:
            if text[pos:].strip() == "":
                return
            raise ValueError(f"Unexpected input at offset {pos}: {text[pos:pos + 40]!r}")
        pos = match.end()
        kind = match.lastgroup
        if kind != "comment":
            yield kind, match.group(kind)


class _Parser:
    def __init__(self, text):
        self.tokens = list(_tokens(text))
        self.i = 0

    def peek(self):
        return self.tokens[self.i] if self.i < len(self.tokens) else (None, None)

    def take(self, value=None):
        token = self.tokens[self.i]
        if value is not None and token[1] != value:
            raise ValueError(f"Expected {value!r}, got {token[1]!r}")
        self.i += 1
        return token

    def value(self):
        kind, text = self.take()
        if kind == "string":
            return _unescape(text[1:-1])
        if kind == "number":
            return int(text, 0) if re.fullmatch(r"-?(0x[0-9a-fA-F]+|\d+)", text) else float(text)
        if kind == "name":
            return {"true": True, "false": False, "nil": None}[text]
        if text == "{":
            return self.table()
        raise ValueError(f"Unexpected token {text!r}")

    def table(self):
        result, position = {}, 1
        while self.peek()[1] != "}":
            if self.peek()[1] == "[":
                self.take("[")
                key = self.value()
                self.take("]")
                self.take("=")
                result[key] = self.value()
            else:
                result[position] = self.value()
                position += 1
            if self.peek()[1] in (",", ";"):
                self.take()
        self.take("}")
        if result and list(result.keys()) == list(range(1, len(result) + 1)):
            return [result[k] for k in range(1, len(result) + 1)]
        return result

    def assignments(self):
        variables = {}
        while self.peek()[0] is not None:
            _, name = self.take()
            self.take("=")
            variables[name] = self.value()
        return variables


def load(path):
    """Return {variable_name: value} for every top-level assignment in the file."""
    with open(path, encoding="latin-1") as handle:
        return _Parser(handle.read()).assignments()


if __name__ == "__main__":
    import json

    json.dump(load(sys.argv[1]), sys.stdout, indent=1, ensure_ascii=False, default=str)
