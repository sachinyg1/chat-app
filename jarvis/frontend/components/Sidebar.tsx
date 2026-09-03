"use client";

type ConversationSummary = {
  id: string;
  title: string;
  updated_at: string;
};

export default function Sidebar({
  conversations,
  activeId,
  onSelect,
  onNewChat,
}: {
  conversations: ConversationSummary[];
  activeId: string | null;
  onSelect: (id: string) => void;
  onNewChat: () => void;
}) {
  return (
    <aside className="w-[260px] shrink-0 border-r border-border bg-surface flex flex-col h-full">
      <div className="px-4 py-5 flex items-center gap-2">
        <div className="w-7 h-7 rounded-md bg-accent flex items-center justify-center text-sm font-display font-bold">
          J
        </div>
        <span className="font-display font-bold text-lg tracking-tight">
          Jarvis
        </span>
      </div>

      <div className="px-3">
        <button
          onClick={onNewChat}
          className="w-full text-left px-3 py-2 rounded-lg bg-accentSoft text-accent text-sm font-medium hover:bg-accent hover:text-white transition-colors"
        >
          + New chat
        </button>
      </div>

      <nav className="flex-1 overflow-y-auto mt-4 px-2 space-y-1">
        {conversations.length === 0 && (
          <p className="px-3 py-2 text-xs text-textSecondary">
            No conversations yet
          </p>
        )}
        {conversations.map((c) => (
          <button
            key={c.id}
            onClick={() => onSelect(c.id)}
            className={`w-full text-left px-3 py-2 rounded-lg text-sm truncate transition-colors ${
              c.id === activeId
                ? "bg-surface2 text-textPrimary"
                : "text-textSecondary hover:bg-surface2 hover:text-textPrimary"
            }`}
            title={c.title}
          >
            {c.title}
          </button>
        ))}
      </nav>

      <div className="px-4 py-4 text-xs text-textSecondary border-t border-border">
        Your AI assistant
      </div>
    </aside>
  );
}
