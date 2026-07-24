import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.7';

const { url, anonKey } = window.SUPABASE_CONFIG;
const sb = createClient(url, anonKey);

const authPanel = document.getElementById('auth-panel');
const dashboard = document.getElementById('dashboard');
const who = document.getElementById('who');
const tbody = document.querySelector('#farms-table tbody');

document.getElementById('signin-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  const form = new FormData(e.currentTarget);
  const { error } = await sb.auth.signInWithPassword({
    email: form.get('email'),
    password: form.get('password'),
  });
  if (error) alert(error.message);
});

document.getElementById('signout-btn').addEventListener('click', async () => {
  await sb.auth.signOut();
});

sb.auth.onAuthStateChange(async (_evt, session) => {
  if (!session) {
    authPanel.hidden = false;
    dashboard.hidden = true;
    who.textContent = '';
    tbody.innerHTML = '';
    return;
  }
  authPanel.hidden = true;
  dashboard.hidden = false;
  who.textContent = session.user.email ?? session.user.phone ?? session.user.id;
  await loadFarms();
});

async function loadFarms() {
  const { data, error } = await sb
    .from('farm_profiles')
    .select('name, crop_type, land_size_hectares, plantation_date')
    .order('created_at', { ascending: false });

  if (error) {
    tbody.innerHTML = `<tr><td colspan="4">Error: ${error.message}</td></tr>`;
    return;
  }
  tbody.innerHTML = data
    .map(
      (row) => `
        <tr>
          <td>${escapeHtml(row.name)}</td>
          <td>${escapeHtml(row.crop_type)}</td>
          <td>${row.land_size_hectares}</td>
          <td>${row.plantation_date}</td>
        </tr>`
    )
    .join('');
}

function escapeHtml(s) {
  return String(s).replace(/[&<>"']/g, (c) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  }[c]));
}
