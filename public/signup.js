const form = document.getElementById('signup');
const error = document.getElementById('error');

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  error.textContent = '';
  const data = Object.fromEntries(new FormData(form));
  const res = await fetch('/api/signup', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  const body = await res.json();
  if (!res.ok) {
    error.textContent = body.error;
    return;
  }
  localStorage.setItem('tasklet-user', JSON.stringify(body));
  // Give the user a moment to read any message, then go to their projects.
  setTimeout(() => {
    if (!error.textContent) location.href = '/projects.html';
  }, 600);
});
