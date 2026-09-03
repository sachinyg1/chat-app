"""
MongoDB access layer for Jarvis.
Stores conversations as documents:
{
  "_id": "conv_<uuid>",
  "user_id": "default",
  "title": "First few words of the chat",
  "messages": [{"role": "user"|"assistant", "content": "..."}],
  "created_at": ISODate,
  "updated_at": ISODate
}
"""
import os
from datetime import datetime, timezone
from typing import List, Dict, Optional
from motor.motor_asyncio import AsyncIOMotorClient

MONGO_URI = os.environ.get("MONGO_URI", "mongodb://localhost:27017")
DB_NAME = os.environ.get("MONGO_DB_NAME", "jarvis")

client = AsyncIOMotorClient(MONGO_URI)
db = client[DB_NAME]
conversations = db["conversations"]


async def create_conversation(conv_id: str, user_id: str = "default") -> None:
    now = datetime.now(timezone.utc)
    await conversations.insert_one(
        {
            "_id": conv_id,
            "user_id": user_id,
            "title": "New chat",
            "messages": [],
            "created_at": now,
            "updated_at": now,
        }
    )


async def get_conversation(conv_id: str) -> Optional[dict]:
    return await conversations.find_one({"_id": conv_id})


async def list_conversations(user_id: str = "default", limit: int = 50) -> List[dict]:
    cursor = (
        conversations.find({"user_id": user_id}, {"messages": 0})
        .sort("updated_at", -1)
        .limit(limit)
    )
    return [doc async for doc in cursor]


async def append_message(conv_id: str, role: str, content: str) -> None:
    now = datetime.now(timezone.utc)
    await conversations.update_one(
        {"_id": conv_id},
        {
            "$push": {"messages": {"role": role, "content": content}},
            "$set": {"updated_at": now},
        },
    )


async def set_title_if_new(conv_id: str, first_user_message: str) -> None:
    title = first_user_message.strip()[:60]
    await conversations.update_one(
        {"_id": conv_id, "title": "New chat"},
        {"$set": {"title": title}},
    )


async def delete_conversation(conv_id: str) -> None:
    await conversations.delete_one({"_id": conv_id})
