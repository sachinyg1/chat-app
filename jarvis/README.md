# Jarvis — Your AI Assistant

An AI agent app (like ChatGPT) with web search + calculator tools, built to
run entirely on free tiers:

- **LLM**: NVIDIA NIM free API (Llama 3.3 70B, tool-calling)
- **Agent framework**: LangGraph (ReAct agent)
- **Web search tool**: Tavily (free tier)
- **Backend**: FastAPI, streams responses over SSE
- **Frontend**: Next.js + Tailwind, ChatGPT-style streaming chat UI
- **Database**: MongoDB Atlas free (M0) cluster — stores conversations

```
jarvis/
  backend/     FastAPI + LangGraph agent
  frontend/    Next.js chat UI
```

## 1. Get your free API keys

1. **NVIDIA NIM** — https://build.nvidia.com → sign in → generate an API key
2. **Tavily** (web search) — https://tavily.com → sign up → copy API key
3. **MongoDB Atlas** — https://www.mongodb.com/cloud/atlas/register →
   create a free M0 cluster → "Connect" → "Drivers" → copy the connection
   string (replace `<password>` with your DB user's password)

## 2. Run locally

**Backend:**
```bash
cd backend
cp .env.example .env      # fill in your keys
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

**Frontend** (new terminal):
```bash
cd frontend
cp .env.example .env.local
npm install
npm run dev
```

Open http://localhost:3000 — Jarvis should be running.

## 3. Deploy for free

| Piece | Where | Free tier |
|---|---|---|
| Frontend | [Vercel](https://vercel.com) | Always free for personal projects |
| Backend | [Azure Container Apps](https://azure.microsoft.com/products/container-apps) (Consumption plan) or [Render](https://render.com) | ~180,000 vCPU-seconds/month free (Azure) / free web service (Render) |
| Database | MongoDB Atlas M0 | Always free, 512MB |

**Frontend on Vercel:**
1. Push this repo to GitHub (see below)
2. Import the repo in Vercel, set root directory to `frontend`
3. Add env var `NEXT_PUBLIC_API_URL` = your deployed backend URL

**Backend on Azure Container Apps (Consumption/free tier):**
```bash
az login
az group create --name rg-jarvis --location eastus

az acr create --resource-group rg-jarvis --name acrjarvis --sku Basic
az acr build --registry acrjarvis --image jarvis-backend:latest ./backend

az containerapp env create --name jarvis-env --resource-group rg-jarvis --location eastus

az containerapp create \
  --name jarvis-backend \
  --resource-group rg-jarvis \
  --environment jarvis-env \
  --image acrjarvis.azurecr.io/jarvis-backend:latest \
  --target-port 8000 \
  --ingress external \
  --min-replicas 0 \
  --max-replicas 2 \
  --env-vars NVIDIA_API_KEY=secretref:nvidia-key TAVILY_API_KEY=secretref:tavily-key MONGO_URI=secretref:mongo-uri \
  --secrets nvidia-key=<your_key> tavily-key=<your_key> mongo-uri=<your_connection_string>
```
`--min-replicas 0` means it scales to zero (and costs nothing) when idle.

## 4. Push to your own GitHub repo

Do this from your own machine (not in a chat) so your token never gets
pasted anywhere:

```bash
cd jarvis
git init
git add .
git commit -m "Initial commit: Jarvis AI agent app"
git branch -M main
git remote add origin https://github.com/<your-username>/jarvis.git
git push -u origin main
```

When it asks for a password, use a GitHub Personal Access Token (Settings →
Developer settings → Personal access tokens → generate one with the `repo`
scope). Revoke it once you're done if you won't reuse it.

## Notes

- The NVIDIA and Tavily free tiers are rate-limited — fine for personal use
  and demos, not for heavy production traffic.
- `.env` files are gitignored — never commit real API keys.
- To add more tools (file Q&A, etc.), add a function in
  `backend/app/tools.py` and register it in the `TOOLS` list.
