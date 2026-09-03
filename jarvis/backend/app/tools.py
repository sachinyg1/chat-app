"""
Tools Jarvis's agent can call.
Add new tools here and register them in agent.py's TOOLS list.
"""
import os
import ast
import operator as op
from langchain_core.tools import tool
from tavily import TavilyClient

_tavily_key = os.environ.get("TAVILY_API_KEY", "")
_tavily_client = TavilyClient(api_key=_tavily_key) if _tavily_key else None


@tool
def web_search(query: str) -> str:
    """Search the live web for current information (news, facts, prices,
    anything that might have changed after the model's training cutoff).
    Use this whenever the user asks about something recent or time-sensitive."""
    if _tavily_client is None:
        return "Web search is not configured (missing TAVILY_API_KEY)."
    result = _tavily_client.search(query=query, max_results=5)
    lines = []
    for r in result.get("results", []):
        lines.append(f"- {r['title']}: {r['content'][:300]} (source: {r['url']})")
    return "\n".join(lines) if lines else "No results found."


# Safe arithmetic evaluator -- avoids using eval() on untrusted input.
_ALLOWED_OPS = {
    ast.Add: op.add,
    ast.Sub: op.sub,
    ast.Mult: op.mul,
    ast.Div: op.truediv,
    ast.Pow: op.pow,
    ast.USub: op.neg,
    ast.Mod: op.mod,
}


def _safe_eval(node):
    if isinstance(node, ast.Constant):
        return node.value
    if isinstance(node, ast.BinOp) and type(node.op) in _ALLOWED_OPS:
        return _ALLOWED_OPS[type(node.op)](_safe_eval(node.left), _safe_eval(node.right))
    if isinstance(node, ast.UnaryOp) and type(node.op) in _ALLOWED_OPS:
        return _ALLOWED_OPS[type(node.op)](_safe_eval(node.operand))
    raise ValueError("Unsupported expression")


@tool
def calculator(expression: str) -> str:
    """Evaluate a math expression, e.g. '(24 * 7) + 15 / 3'.
    Only basic arithmetic (+ - * / ** %) is supported."""
    try:
        tree = ast.parse(expression, mode="eval").body
        return str(_safe_eval(tree))
    except Exception as e:
        return f"Could not evaluate expression: {e}"


TOOLS = [web_search, calculator]
