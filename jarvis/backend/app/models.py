from pydantic import BaseModel
from typing import Optional


class ChatRequest(BaseModel):
    conversation_id: Optional[str] = None
    message: str


class NewConversationResponse(BaseModel):
    conversation_id: str
