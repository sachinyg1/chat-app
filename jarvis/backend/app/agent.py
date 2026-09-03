"""
Jarvis's brain: a LangGraph ReAct-style agent running on an NVIDIA NIM model
(free tier, OpenAI-compatible endpoint), with tool-calling support.
"""
import os
from langchain_openai import ChatOpenAI
from langgraph.prebuilt import create_react_agent
from langchain_core.messages import HumanMessage, AIMessage, SystemMessage

from app.tools import TOOLS

NVIDIA_API_KEY = os.environ.get("NVIDIA_API_KEY", "")
NVIDIA_BASE_URL = "https://integrate.api.nvidia.com/v1"
MODEL_NAME = os.environ.get("NVIDIA_MODEL", "meta/llama-3.3-70b-instruct")

SYSTEM_PROMPT = (
    "You are Jarvis, a helpful, direct AI assistant. You can search the web "
    "and do calculations when needed -- use those tools whenever a question "
    "depends on current information or precise arithmetic. Keep answers "
    "clear and to the point, and use markdown formatting where it helps "
    "readability (lists, code blocks, bold for key terms)."
)

llm = ChatOpenAI(
    model=MODEL_NAME,
    api_key=NVIDIA_API_KEY,
    base_url=NVIDIA_BASE_URL,
    temperature=0.6,
    streaming=True,
)

agent = create_react_agent(llm, TOOLS)


def _to_lc_messages(history: list[dict]):
    """Convert stored {role, content} dicts into LangChain message objects."""
    messages = [SystemMessage(content=SYSTEM_PROMPT)]
    for m in history:
        if m["role"] == "user":
            messages.append(HumanMessage(content=m["content"]))
        else:
            messages.append(AIMessage(content=m["content"]))
    return messages


async def stream_agent_reply(history: list[dict]):
    """
    Streams (event_type, text) tuples as the agent works:
      ("tool", "web_search")   -- announces a tool call starting
      ("token", "some text")   -- a chunk of the final answer
    """
    lc_messages = _to_lc_messages(history)
    announced_tools = set()

    async for event in agent.astream_events(
        {"messages": lc_messages}, version="v2"
    ):
        kind = event["event"]

        if kind == "on_tool_start":
            tool_name = event["name"]
            if tool_name not in announced_tools:
                announced_tools.add(tool_name)
                yield ("tool", tool_name)

        elif kind == "on_chat_model_stream":
            chunk = event["data"]["chunk"]
            if chunk.content:
                yield ("token", chunk.content)
