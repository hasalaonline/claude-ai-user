const user = JSON.parse(localStorage.getItem('tasklet-user') || 'null');
if (!user) location.href = '/';
document.getElementById('greeting').textContent = `Signed in as ${user.name}`;

const list = document.getElementById('projects');
const empty = document.getElementById('empty');
const form = document.getElementById('project-form');

document.getElementById('new-project').addEventListener('click', () => {
  form.hidden = false;
  form.elements.name.focus();
});

function render(projects) {
  list.innerHTML = '';
  empty.hidden = projects.length > 0;
  for (const project of projects) {
    const item = document.createElement('li');
    item.className = 'project';
    item.innerHTML = `<span class="name"></span><button class="delete">Delete</button>`;
    item.querySelector('.name').textContent = project.name;
    item.querySelector('.delete').addEventListener('click', async () => {
      const res = await fetch(`/api/projects/${project.name}`, { method: 'DELETE' });
      if (!res.ok) throw new Error(`Delete failed with status ${res.status}`);
      item.remove();
    });
    list.append(item);
  }
}

async function load() {
  const res = await fetch('/api/projects');
  render(await res.json());
}

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  await fetch('/api/projects', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name: form.elements.name.value }),
  });
  form.reset();
  form.hidden = true;
  load();
});

load();
