import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const DATA_FILE = path.resolve(__dirname, 'pending_wallpapers.json');

function loadWallpapers() {
  try {
    if (fs.existsSync(DATA_FILE)) {
      const content = fs.readFileSync(DATA_FILE, 'utf-8');
      return JSON.parse(content);
    }
  } catch (_) {}
  return [];
}

function saveWallpapers(data) {
  try {
    fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2), 'utf-8');
  } catch (_) {}
}

let pendingList = loadWallpapers();

export default defineConfig({
  plugins: [
    react(),
    {
      name: 'dev-wallpaper-api',
      configureServer(server) {
        server.middlewares.use((req, res, next) => {
          // Allow CORS from mobile devices and local dev clients
          res.setHeader('Access-Control-Allow-Origin', '*');
          res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
          res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

          if (req.method === 'OPTIONS') {
            res.statusCode = 204;
            res.end();
            return;
          }

          // GET /api/wallpapers/pending
          if (req.url === '/api/wallpapers/pending' && req.method === 'GET') {
            res.setHeader('Content-Type', 'application/json');
            res.end(JSON.stringify(pendingList));
            return;
          }

          // POST /api/wallpapers/submit
          if (req.url === '/api/wallpapers/submit' && req.method === 'POST') {
            let body = '';
            req.on('data', chunk => { body += chunk; });
            req.on('end', () => {
              try {
                const item = JSON.parse(body);
                if (!item.id) {
                  item.id = 'sub_' + Date.now();
                }
                item.status = 'PENDING';
                item.uploaded_at = item.uploaded_at || new Date().toISOString();
                
                // Deduplicate if already present
                pendingList = pendingList.filter(w => w.id !== item.id);
                pendingList.unshift(item);
                saveWallpapers(pendingList);

                console.log(`[Admin Portal Bridge] Received mobile upload: "${item.title}" by ${item.uploader_name}`);
                res.setHeader('Content-Type', 'application/json');
                res.end(JSON.stringify({ success: true, item }));
              } catch (err) {
                res.statusCode = 400;
                res.end(JSON.stringify({ error: err.message }));
              }
            });
            return;
          }

          // POST /api/wallpapers/:id/approve or reject
          if (req.url?.startsWith('/api/wallpapers/') && req.method === 'POST') {
            const parts = req.url.split('?')[0].split('/');
            const id = parts[3];
            const action = parts[4];

            if (action === 'approve') {
              pendingList = pendingList.filter(w => w.id !== id);
              saveWallpapers(pendingList);
              console.log(`[Admin Portal Bridge] Approved wallpaper: ${id}`);
              res.setHeader('Content-Type', 'application/json');
              res.end(JSON.stringify({ success: true, id, status: 'APPROVED' }));
              return;
            } else if (action === 'reject') {
              pendingList = pendingList.filter(w => w.id !== id);
              saveWallpapers(pendingList);
              console.log(`[Admin Portal Bridge] Rejected wallpaper: ${id}`);
              res.setHeader('Content-Type', 'application/json');
              res.end(JSON.stringify({ success: true, id, status: 'REJECTED' }));
              return;
            }
          }

          next();
        });
      }
    }
  ],
  server: {
    port: 3000,
    open: false,
    host: true,
  },
});
