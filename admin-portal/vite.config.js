import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const PENDING_FILE = path.resolve(__dirname, 'pending_wallpapers.json');
const APPROVED_FILE = path.resolve(__dirname, 'approved_wallpapers.json');
const REJECTED_FILE = path.resolve(__dirname, 'rejected_wallpapers.json');

function loadList(filePath) {
  try {
    if (fs.existsSync(filePath)) {
      const content = fs.readFileSync(filePath, 'utf-8');
      return JSON.parse(content);
    }
  } catch (_) {}
  return [];
}

function saveList(filePath, data) {
  try {
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf-8');
  } catch (_) {}
}

let pendingList = loadList(PENDING_FILE);
let approvedList = loadList(APPROVED_FILE);
let rejectedList = loadList(REJECTED_FILE);

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

          // GET /api/wallpapers/approved (served live to user feeds)
          if (req.url === '/api/wallpapers/approved' && req.method === 'GET') {
            res.setHeader('Content-Type', 'application/json');
            res.end(JSON.stringify(approvedList));
            return;
          }

          // GET /api/wallpapers/rejected
          if (req.url === '/api/wallpapers/rejected' && req.method === 'GET') {
            res.setHeader('Content-Type', 'application/json');
            res.end(JSON.stringify(rejectedList));
            return;
          }

          // GET /api/wallpapers/status or /all (returns all creator submissions with current status & rejection reason)
          if ((req.url === '/api/wallpapers/status' || req.url === '/api/wallpapers/all') && req.method === 'GET') {
            const allItems = [...pendingList, ...approvedList, ...rejectedList];
            res.setHeader('Content-Type', 'application/json');
            res.end(JSON.stringify(allItems));
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
                
                // Remove from rejected / approved if resubmitted
                rejectedList = rejectedList.filter(w => w.id !== item.id);
                approvedList = approvedList.filter(w => w.id !== item.id);
                saveList(REJECTED_FILE, rejectedList);
                saveList(APPROVED_FILE, approvedList);

                // Deduplicate if already present in pending
                pendingList = pendingList.filter(w => w.id !== item.id);
                pendingList.unshift(item);
                saveList(PENDING_FILE, pendingList);

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

            let body = '';
            req.on('data', chunk => { body += chunk; });
            req.on('end', () => {
              try {
                let parsedBody = {};
                if (body) {
                  try { parsedBody = JSON.parse(body); } catch (_) {}
                }

                if (action === 'approve') {
                  const existing = pendingList.find(w => w.id === id) ||
                                   rejectedList.find(w => w.id === id) ||
                                   { id, title: 'Approved Wallpaper' };
                  
                  const approvedItem = {
                    ...existing,
                    status: 'APPROVED',
                    approved_at: new Date().toISOString(),
                  };
                  delete approvedItem.rejection_reason;

                  pendingList = pendingList.filter(w => w.id !== id);
                  rejectedList = rejectedList.filter(w => w.id !== id);
                  approvedList = approvedList.filter(w => w.id !== id);
                  approvedList.unshift(approvedItem);

                  saveList(PENDING_FILE, pendingList);
                  saveList(REJECTED_FILE, rejectedList);
                  saveList(APPROVED_FILE, approvedList);

                  console.log(`[Admin Portal Bridge] Wallpaper APPROVED and now LIVE on user side: ${id} ("${approvedItem.title}")`);
                  res.setHeader('Content-Type', 'application/json');
                  res.end(JSON.stringify({ success: true, id, status: 'APPROVED', item: approvedItem }));
                  return;
                } else if (action === 'reject') {
                  const reason = parsedBody.reason || parsedBody.rejection_reason || 'Does not meet community neon guidelines.';
                  const existing = pendingList.find(w => w.id === id) ||
                                   approvedList.find(w => w.id === id) ||
                                   { id, title: 'Rejected Wallpaper' };

                  const rejectedItem = {
                    ...existing,
                    status: 'REJECTED',
                    rejection_reason: reason,
                    rejected_at: new Date().toISOString(),
                  };

                  pendingList = pendingList.filter(w => w.id !== id);
                  approvedList = approvedList.filter(w => w.id !== id);
                  rejectedList = rejectedList.filter(w => w.id !== id);
                  rejectedList.unshift(rejectedItem);

                  saveList(PENDING_FILE, pendingList);
                  saveList(APPROVED_FILE, approvedList);
                  saveList(REJECTED_FILE, rejectedList);

                  console.log(`[Admin Portal Bridge] Wallpaper REJECTED: ${id} ("${rejectedItem.title}"), Reason: "${reason}"`);
                  res.setHeader('Content-Type', 'application/json');
                  res.end(JSON.stringify({ success: true, id, status: 'REJECTED', rejection_reason: reason, item: rejectedItem }));
                  return;
                }
              } catch (err) {
                res.statusCode = 500;
                res.end(JSON.stringify({ error: err.message }));
                return;
              }

              next();
            });
            return;
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

