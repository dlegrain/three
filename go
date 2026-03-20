#!/usr/bin/env bash

PORT=5120

# Kill whatever is already on port 5120
lsof -ti tcp:$PORT | xargs kill -9 2>/dev/null

# Open browser after a short delay (let Vite start first)
(sleep 2 && open "http://localhost:$PORT") &

# Start Vite on port 5120
npm run dev -- --port $PORT
