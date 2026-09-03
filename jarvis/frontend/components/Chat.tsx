"use client";

import { useEffect, useRef, useState } from "react";
import ReactMarkdown from "react-markdown";
import Sidebar from "@/components/Sidebar";

const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

type Message = { role: "user" | "assistant"; content: string };
type ConversationSummary = { id: string; title: string; updated_at: string };

export default function Chat() {
  const [conversations, setConversations] = useState<ConversationSummary[]>([]);
  const [activeId, setActiveId] = useState<string | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState("");
  const [streaming, setStreaming] = useState(false);
  const [activeTool, setActiveTool] = useState<string | null>(null);
  const bottomRef = useRef<HTMLDivElement>(null);

  const refreshConversations = async () => {
    const res = await fetch(`${API_URL}/conversations`);
    if (res.ok) setConversations(await res.json());
  };

  useEffect(() => {
    refreshConversations();
  }, []);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, streaming]);

  const openConversation = async (id: string) => {
    const res = await fetch(`${API_URL}/conversations/${id}`);
    if (res.ok) {
      const data = await res.json();
      setActiveId(id);
      setMessages(data.messages);
    }
  };

  const newChat = () => {
    setActiveId(null);
    setMessages([]);
  };

  const sendMessage = async () => {
    const text = input.trim();
    if (!text || streaming) return;

    setInput("");
    setMessages((prev) => [...prev, { role: "user", content: text }]);
    setStreaming(true);
    setActiveTool(null);

    let assistantText = "";
    setMessages((prev) => [...prev, { role: "assistant", content: "" }]);

    const res = await fetch(`${API_URL}/chat`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ conversation_id: activeId, message: text }),
    });

    if (!res.body) {
      setStreaming(false);
      return;
    }

    const reader = res.body.getReader();
    const decoder = new TextDecoder();
    let buffer = "";

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      buffer += decoder.decode(value, { stream: true });

      const lines = buffer.split("\n\n");
      buffer = lines.pop() || "";

      for (const line of lines) {
        if (!line.startsWith("data: ")) continue;
        const payload = JSON.parse(line.slice(6));

        if (payload.type === "conversation_id") {
          setActiveId(payload.value);
        } else if (payload.type === "tool") {
          setActiveTool(payload.value);
        } else if (payload.type === "token") {
          setActiveTool(null);
          assistantText += payload.value;
          setMessages((prev) => {
            const updated = [...prev];
            updated[updated.length - 1] = {
              role: "assistant",
              content: assistantText,
            };
            return updated;
          });
        } else if (payload.type === "done") {
          setStreaming(false);
          setActiveTool(null);
          refreshConversations();
        }
      }
    }
    setStreaming(false);
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  return (
    <div className="flex h-screen">
      <Sidebar
        conversations={conversations}
        activeId={activeId}
        onSelect={openConversation}
        onNewChat={newChat}
      />

      <main className="flex-1 flex flex-col h-full">
        <div className="flex-1 overflow-y-auto">
          <div className="max-w-[700px] mx-auto px-4 py-8">
            {messages.length === 0 && (
              <div className="mt-24 text-center">
                <h1 className="font-display text-3xl font-bold text-textPrimary">
                  What can I help with?
                </h1>
                <p className="text-textSecondary mt-2 text-sm">
                  Ask anything -- I can search the web and run calculations
                  when it helps.
                </p>
              </div>
            )}

            {messages.map((m, i) => (
              <div
                key={i}
                className={`mb-6 flex ${
                  m.role === "user" ? "justify-end" : "justify-start"
                }`}
              >
                <div
                  className={`max-w-[85%] rounded-2xl px-4 py-3 text-[15px] leading-relaxed ${
                    m.role === "user"
                      ? "bg-accent text-white"
                      : "bg-surface text-textPrimary"
                  }`}
                >
                  {m.role === "assistant" ? (
                    <div className="prose-jarvis">
                      <ReactMarkdown>{m.content || "…"}</ReactMarkdown>
                    </div>
                  ) : (
                    m.content
                  )}
                </div>
              </div>
            ))}

            {activeTool && (
              <div className="mb-6 flex items-center gap-2 text-sm text-toolAccent">
                <span className="w-2 h-2 rounded-full bg-toolAccent animate-pulse" />
                {activeTool === "web_search"
                  ? "Searching the web…"
                  : activeTool === "calculator"
                  ? "Calculating…"
                  : `Using ${activeTool}…`}
              </div>
            )}

            <div ref={bottomRef} />
          </div>
        </div>

        <div className="border-t border-border px-4 py-4">
          <div className="max-w-[700px] mx-auto flex items-end gap-2 bg-surface rounded-2xl border border-border px-4 py-3">
            <textarea
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder="Message Jarvis…"
              rows={1}
              className="flex-1 bg-transparent resize-none outline-none text-[15px] placeholder:text-textSecondary max-h-40"
            />
            <button
              onClick={sendMessage}
              disabled={streaming || !input.trim()}
              className="shrink-0 w-9 h-9 rounded-lg bg-accent disabled:bg-surface2 disabled:text-textSecondary flex items-center justify-center transition-colors"
              aria-label="Send message"
            >
              ↑
            </button>
          </div>
        </div>
      </main>
    </div>
  );
}
