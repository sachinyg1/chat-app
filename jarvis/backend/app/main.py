import json
import uuid
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from contextlib import asynccontextmanager

from app import db
from app.agent import stream_agent_reply
from app.models import ChatRequest, NewConversationResponse


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield


app = FastAPI(title="Jarvis API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten this to your frontend's URL in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/conversations", response_model=NewConversationResponse)
async def new_conversation():
    conv_id = f"conv_{uuid.uuid4().hex[:12]}"
    await db.create_conversation(conv_id)
    return NewConversationResponse(conversation_id=conv_id)


@app.get("/conversations")
async def get_conversations():
    convs = await db.list_conversations()
    return [
        {"id": c["_id"], "title": c["title"], "updated_at": c["updated_at"].isoformat()}
        for c in convs
    ]


@app.get("/conversations/{conv_id}")
async def get_conversation(conv_id: str):
    conv = await db.get_conversation(conv_id)
    if not conv:
        raise HTTPException(status_code=404, detail="Conversation not found")
    return {"id": conv["_id"], "title": conv["title"], "messages": conv["messages"]}


@app.delete("/conversations/{conv_id}")
async def delete_conversation(conv_id: str):
    await db.delete_conversation(conv_id)
    return {"status": "deleted"}


@app.post("/chat")
async def chat(req: ChatRequest):
    conv_id = req.conversation_id
    if not conv_id:
        conv_id = f"conv_{uuid.uuid4().hex[:12]}"
        await db.create_conversation(conv_id)

    conv = await db.get_conversation(conv_id)
    if not conv:
        raise HTTPException(status_code=404, detail="Conversation not found")

    await db.append_message(conv_id, "user", req.message)
    await db.set_title_if_new(conv_id, req.message)

    history = conv["messages"] + [{"role": "user", "content": req.message}]

    async def event_stream():
        yield f"data: {json.dumps({'type': 'conversation_id', 'value': conv_id})}\n\n"
        full_reply = ""
        async for event_type, text in stream_agent_reply(history):
            if event_type == "tool":
                yield f"data: {json.dumps({'type': 'tool', 'value': text})}\n\n"
            else:
                full_reply += text
                yield f"data: {json.dumps({'type': 'token', 'value': text})}\n\n"
        await db.append_message(conv_id, "assistant", full_reply)
        yield f"data: {json.dumps({'type': 'done'})}\n\n"

    return StreamingResponse(event_stream(), media_type="text/event-stream")
