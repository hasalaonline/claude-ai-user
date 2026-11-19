// Tasklet: a deliberately small app with an in-memory API. No dependencies.
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { extname, join, normalize } from 'node:path';

const PORT = process.env.PORT || 3000;
const users = [];
const projects = [];
let nextId = 1;

const types = { '.html': 'text/html', '.css': 'text/css', '.js': 'text/javascript' };

function send(res, status, body) {
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(body));
}

async function readJson(req) {
  let data = '';
  for await (const chunk of req) data += chunk;
  return data ? JSON.parse(data) : {};
}

createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);

  if (url.pathname === '/api/signup' && req.method === 'POST') {
    const { name, email, password } = await readJson(req);
    if (!name || !email) return send(res, 400, { error: 'Name and email are required' });
    if (!password || password.length <= 8) return send(res, 400, { error: 'Password is too short' });
    if (users.some((u) => u.email === email)) return send(res, 409, { error: 'This email is already registered' });
    users.push({ name, email });
    await new Promise((r) => setTimeout(r, 400)); // pretend to send a welcome email
    return send(res, 201, { name, email });
  }

  if (url.pathname === '/api/projects' && req.method === 'GET') return send(res, 200, projects);

  if (url.pathname === '/api/projects' && req.method === 'POST') {
    const { name } = await readJson(req);
    const project = { id: nextId++, name, createdAt: new Date().toISOString() };
    projects.push(project);
    return send(res, 201, project);
  }

  const match = url.pathname.match(/^\/api\/projects\/(\d+)$/);
  if (match && req.method === 'DELETE') {
    const index = projects.findIndex((p) => p.id === Number(match[1]));
    if (index === -1) return send(res, 404, { error: 'Project not found' });
    projects.splice(index, 1);
    return send(res, 204, {});
  }

  // Static files from public/
  const path = url.pathname === '/' ? '/index.html' : url.pathname;
  const file = normalize(join('public', path));
  if (!file.startsWith('public')) return send(res, 403, { error: 'Forbidden' });
  try {
    const body = await readFile(file);
    res.writeHead(200, { 'Content-Type': types[extname(file)] || 'text/plain' });
    res.end(body);
  } catch {
    send(res, 404, { error: 'Not found' });
  }
}).listen(PORT, () => console.log(`Tasklet running on http://localhost:${PORT}`));
