import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.7';

const { url, anonKey } = window.SUPABASE_CONFIG;
const sb = createClient(url, anonKey);

const $ = (id) => document.getElementById(id);
const yesNo = (v) => (v ? 'yes' : 'no');
const short = (id) => String(id).slice(0, 8);
const when = { label: 'Date', value: (r) => new Date(r.created_at).toLocaleDateString() };
const col = (label, key) => ({ label, value: (r) => r[key] });

// ---------- Language (English / Nepali). Labels and buttons only; data stays as stored. ----------
const NE = {
  'Admin': 'एडमिन', 'Sign in': 'लगइन', 'Sign out': 'लगआउट', 'Email': 'इमेल', 'Password': 'पासवर्ड',
  'Staff accounts only. Farmers and buyers use the mobile app.': 'कर्मचारी खाता मात्र। किसान र खरिदकर्ताले मोबाइल एप प्रयोग गर्छन्।',
  'This account is not an admin.': 'यो खाता एडमिनको होइन।',
  'Search': 'खोज्नुहोस्', 'Add new': 'नयाँ थप्नुहोस्', 'Review': 'हेर्नुहोस्', 'Edit': 'सम्पादन', 'Delete': 'मेट्नुहोस्',
  'Cancel': 'रद्द गर्नुहोस्', 'Back': 'पछाडि', 'Save changes': 'परिवर्तन सुरक्षित गर्नुहोस्', 'Add': 'थप्नुहोस्',
  'Loading...': 'लोड हुँदैछ…', 'Nothing here yet.': 'यहाँ अहिलेसम्म केही छैन।', 'No matches.': 'कुनै नतिजा भेटिएन।',
  'Delete this item? This cannot be undone.': 'यो हटाउने हो? यो फर्काउन मिल्दैन।',
  'Tutorials': 'ट्युटोरियल', 'Crops': 'बाली', 'Shop products': 'पसलका सामान', 'Market prices': 'बजार भाउ',
  'Listings': 'बिक्री सूची', 'Shop enquiries': 'पसल सोधपुछ', 'Users': 'प्रयोगकर्ता', 'Farm profiles': 'खेत प्रोफाइल',
  'Hide': 'लुकाउनुहोस्', 'Unhide': 'देखाउनुहोस्', 'Mark contacted': 'सम्पर्क गरियो', 'Close': 'बन्द गर्नुहोस्',
};
let lang = 'en';
try { lang = localStorage.getItem('fm_lang') || 'en'; } catch { /* private mode */ }
const t = (s) => (lang === 'ne' && NE[s]) || s;


// ---------- Resources: what each tab shows and what an admin can do ----------

async function peopleMap() {
  const { data } = await sb.from('profiles').select('id, full_name, phone');
  return new Map((data ?? []).map((p) => [p.id, p.full_name || p.phone || short(p.id)]));
}

async function productsMap() {
  const { data } = await sb.from('catalog_products').select('id, name');
  return new Map((data ?? []).map((p) => [p.id, p.name]));
}

const CATEGORIES = ['general', 'vegetable_farming', 'rice', 'maize', 'soil_testing',
  'compost_fertilizer', 'irrigation', 'pest_disease', 'harvesting_selling'];

// Links the mobile app opens. Only https:// links are accepted.
const URL_FIELDS = ['external_url', 'thumbnail_url', 'image_url'];

const RESOURCES = {
  tutorials: {
    label: 'Tutorials', table: 'learning_content', order: 'created_at',
    columns: [col('Title', 'title'), col('Type', 'content_type'),
      col('Category', 'category'), col('Language', 'language')],
    fields: [
      { name: 'content_type', label: 'Type', type: 'select', required: true,
        options: ['course', 'video', 'ebook', 'success_story'], default: 'video' },
      { name: 'title', label: 'Title', required: true },
      { name: 'summary', label: 'Short description', type: 'textarea', required: true },
      { name: 'body', label: 'Details', type: 'textarea', emptyAs: '' },
      { name: 'external_url', label: 'Video or link URL' },
      { name: 'category', label: 'Category', type: 'select', required: true,
        options: CATEGORIES, default: 'general' },
      { name: 'language', label: 'Language', type: 'select', required: true,
        options: ['ne', 'hi', 'en'], default: 'ne' },
      { name: 'thumbnail_url', label: 'Thumbnail URL' },
    ],
  },

  crops: {
    label: 'Crops', table: 'crops', order: 'created_at',
    columns: [col('Name', 'name'), col('Name (Nepali)', 'name_ne'),
      { label: 'Seasons', value: (r) => (r.seasons ?? []).join(', ') },
      col('Days', 'duration_days'),
      { label: 'Verified', value: (r) => yesNo(r.is_verified) },
      { label: 'Active', value: (r) => yesNo(r.is_active) }],
    fields: [
      { name: 'crop_type', label: 'Crop key (lowercase, e.g. rice)', required: true },
      { name: 'name', label: 'Name', required: true },
      { name: 'name_ne', label: 'Name (Nepali)' },
      { name: 'seasons', label: 'Seasons (comma separated: monsoon, winter, spring)', type: 'list' },
      { name: 'duration_days', label: 'Approximate duration (days)', type: 'number', required: true },
      { name: 'water_need', label: 'Water need', type: 'select', required: true,
        options: ['low', 'medium', 'high'], default: 'medium' },
      { name: 'suitable_soils', label: 'Suitable soils (comma separated: sandy, loamy, clay, silty, peaty, chalky)', type: 'list' },
      { name: 'growing_steps', label: 'Growing steps (JSON, same format as existing rows)', type: 'json' },
      { name: 'notes', label: 'Notes', type: 'textarea' },
      { name: 'is_verified', label: 'Verified', type: 'checkbox', default: false },
      { name: 'is_active', label: 'Visible in the app', type: 'checkbox', default: true },
    ],
  },

  products: {
    label: 'Shop products', table: 'catalog_products', order: 'created_at',
    columns: [col('Name', 'name'), col('Category', 'category'),
      { label: 'Price', value: (r) => (r.indicative_price == null ? '' : `${r.currency} ${r.indicative_price}`) },
      col('Availability', 'availability'),
      { label: 'Demo', value: (r) => yesNo(r.is_demo) },
      { label: 'Active', value: (r) => yesNo(r.is_active) }],
    fields: [
      { name: 'category', label: 'Category', type: 'select', required: true,
        options: ['seed', 'fertilizer', 'tool', 'irrigation'], default: 'seed' },
      { name: 'name', label: 'Name', required: true },
      { name: 'name_ne', label: 'Name (Nepali)' },
      { name: 'description', label: 'Description', type: 'textarea' },
      { name: 'image_url', label: 'Image URL' },
      { name: 'indicative_price', label: 'Indicative price', type: 'number' },
      { name: 'currency', label: 'Currency', required: true, default: 'NPR' },
      { name: 'unit', label: 'Unit (kg, bag...)' },
      { name: 'seller_name', label: 'Seller name' },
      { name: 'seller_phone', label: 'Seller phone' },
      { name: 'seller_address', label: 'Seller address' },
      { name: 'availability', label: 'Availability', type: 'select', required: true,
        options: ['in_stock', 'limited', 'out_of_stock'], default: 'in_stock' },
      { name: 'is_demo', label: 'Sample (DEMO) product', type: 'checkbox', default: false },
      { name: 'is_active', label: 'Visible in the app', type: 'checkbox', default: true },
    ],
  },

  prices: {
    label: 'Market prices', table: 'crop_price_history', order: 'recorded_date',
    columns: [col('Crop', 'crop_name'), col('Market', 'market_name'),
      { label: 'Price (min / avg / max)', value: (r) => `${r.min_price} / ${r.avg_price} / ${r.max_price} ${r.unit}` },
      col('Source', 'source'), col('Date', 'recorded_date'),
      { label: 'Demo', value: (r) => yesNo(r.is_demo) }],
    fields: [
      { name: 'crop_name', label: 'Crop', required: true },
      { name: 'market_name', label: 'Market', required: true },
      { name: 'source', label: 'Source', type: 'select', required: true,
        options: ['kalimati', 'marketplace'], default: 'kalimati' },
      { name: 'recorded_date', label: 'Price date', type: 'date', required: true,
        default: () => new Date().toISOString().slice(0, 10) },
      { name: 'min_price', label: 'Minimum price', type: 'number', required: true },
      { name: 'avg_price', label: 'Average price', type: 'number', required: true },
      { name: 'max_price', label: 'Maximum price', type: 'number', required: true },
      { name: 'unit', label: 'Unit', required: true, default: 'per kg' },
      { name: 'is_demo', label: 'Sample (DEMO) price', type: 'checkbox', default: true },
    ],
  },

  listings: {
    label: 'Listings', table: 'marketplace_listings', order: 'created_at', canDelete: true,
    lookups: async () => ({ people: await peopleMap() }),
    columns: [col('Title', 'title'),
      { label: 'Seller', value: (r, ctx) => ctx.people.get(r.seller_id) ?? short(r.seller_id) },
      { label: 'Price', value: (r) => `${r.currency} ${r.price} / ${r.unit}` },
      col('District', 'district'), col('Status', 'status'),
      { label: 'Hidden', value: (r) => yesNo(r.is_hidden) }, when],
    actions: [{
      label: (r) => (r.is_hidden ? 'Unhide' : 'Hide'),
      run: (r) => sb.from('marketplace_listings').update({ is_hidden: !r.is_hidden }).eq('id', r.id),
    }],
  },

  enquiries: {
    label: 'Shop enquiries', table: 'catalog_enquiries', order: 'created_at',
    lookups: async () => ({ people: await peopleMap(), products: await productsMap() }),
    columns: [
      { label: 'Product', value: (r, ctx) => ctx.products.get(r.product_id) ?? short(r.product_id) },
      { label: 'From', value: (r, ctx) => ctx.people.get(r.user_id) ?? short(r.user_id) },
      col('Message', 'message'), col('Phone', 'contact_phone'), col('Status', 'status'), when],
    actions: ['contacted', 'closed'].map((status) => ({
      label: status === 'contacted' ? 'Mark contacted' : 'Close',
      show: (r) => r.status !== status && !(status === 'contacted' && r.status === 'closed'),
      run: (r) => sb.from('catalog_enquiries').update({ status }).eq('id', r.id),
    })),
  },

  farms: {
    label: 'Farm profiles', table: 'farm_profiles', order: 'created_at',
    lookups: async () => ({ people: await peopleMap() }),
    summary: (r) => `Size ${r.land_size_hectares} ha · Planted ${r.plantation_date}`,
    columns: [col('Name', 'name'), col('Crop', 'crop_type'), col('Size (ha)', 'land_size_hectares'),
      col('Planted', 'plantation_date'), col('Soil type', 'soil_type'),
      col('Irrigation system', 'irrigation_system'), col('Location', 'location_label'),
      { label: 'Owner', value: (r, c) => c.people.get(r.user_id) ?? short(r.user_id) }],
    fields: [
      { name: 'name', label: 'Name', required: true },
      { name: 'crop_type', label: 'Crop', type: 'select', required: true,
        options: ['rice', 'maize', 'wheat', 'potato', 'tomato', 'cauliflower', 'onion', 'millet', 'lentil'] },
      { name: 'land_size_hectares', label: 'Size (ha)', type: 'number', required: true },
      { name: 'plantation_date', label: 'Planted', type: 'date', required: true },
      { name: 'soil_type', label: 'Soil type', type: 'select', required: true,
        options: ['sandy', 'loamy', 'clay', 'silty', 'peaty', 'chalky'] },
      { name: 'irrigation_system', label: 'Irrigation system', type: 'select', required: true,
        options: ['rainfed', 'drip', 'sprinkler', 'flood', 'canal'] },
      { name: 'location_label', label: 'Location' },
    ],
  },

  users: {
    label: 'Users', table: 'profiles', order: 'created_at',
    columns: [col('Name', 'full_name'), col('Phone', 'phone'), col('Country', 'country'),
      col('Role', 'role'), col('Language', 'preferred_language'), when],
  },
};

// ---------- State ----------

let current = 'tutorials';
let rows = [];
let ctx = {};
let editingId = null;
let shownUserId = null;
let shown = [];

const resource = () => RESOURCES[current];
const escapeHtml = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({
  '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
}[c]));

function setStatus(text, isError = false) {
  const el = $('status');
  el.textContent = text;
  el.className = isError ? 'error' : 'sub';
}

function applyLang() {
  document.documentElement.lang = lang === 'ne' ? 'ne' : 'en';
  document.querySelectorAll('[data-i]').forEach((el) => { el.textContent = t(el.dataset.i); });
  document.querySelectorAll('[data-ph]').forEach((el) => { el.placeholder = t(el.dataset.ph); });
  document.querySelectorAll('[data-lang]').forEach((b) => b.classList.toggle('on', b.dataset.lang === lang));
  if (shownUserId) { buildTabs(); $('view-title').textContent = t(resource().label); renderList(); }
}

document.querySelector('.lang').addEventListener('click', (e) => {
  const b = e.target.closest('[data-lang]');
  if (!b) return;
  lang = b.dataset.lang;
  try { localStorage.setItem('fm_lang', lang); } catch { /* ignore */ }
  applyLang();
});

// ---------- Auth ----------

$('signin-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  $('auth-message').textContent = '';
  const form = new FormData(e.currentTarget);
  const { error } = await sb.auth.signInWithPassword({
    email: form.get('email'),
    password: form.get('password'),
  });
  if (error) $('auth-message').textContent = error.message;
});

$('signout-btn').addEventListener('click', () => sb.auth.signOut());

sb.auth.onAuthStateChange((_evt, session) => {
  // Deferred: calling Supabase inside this callback can deadlock the client.
  setTimeout(() => showSession(session), 0);
});

// UX only. The database policies are what actually keep non-admins out.
async function isAdmin(userId) {
  const { data, error } = await sb.from('profiles').select('role').eq('id', userId).single();
  return !error && data.role === 'admin';
}

async function showSession(session) {
  if (!session) {
    shownUserId = null;
    $('auth-panel').hidden = false;
    $('dashboard').hidden = true;
    $('signout-btn').hidden = true;
    $('who').textContent = '';
    return;
  }
  if (session.user.id === shownUserId) return;
  if (!(await isAdmin(session.user.id))) {
    $('auth-message').textContent = t('This account is not an admin.');
    await sb.auth.signOut();
    return;
  }
  shownUserId = session.user.id;
  $('auth-panel').hidden = true;
  $('dashboard').hidden = false;
  $('signout-btn').hidden = false;
  $('who').textContent = session.user.email ?? session.user.id;
  buildTabs();
  await load();
}

// ---------- Tabs and cards ----------

function buildTabs() {
  $('tabs').innerHTML = Object.entries(RESOURCES)
    .map(([key, r]) => `<button data-tab="${key}" class="${key === current ? 'active' : ''}">${escapeHtml(t(r.label))}</button>`)
    .join('');
}

$('tabs').addEventListener('click', (e) => {
  const btn = e.target.closest('button[data-tab]');
  if (!btn) return;
  current = btn.dataset.tab;
  $('search').value = '';
  buildTabs();
  load();
});

async function load() {
  const r = resource();
  $('view-title').textContent = t(r.label);
  $('add-btn').hidden = !r.fields;
  setStatus(t('Loading...'));
  $('list').innerHTML = '';

  const { data, error } = await sb.from(r.table).select('*')
    .order(r.order, { ascending: false }).limit(200);
  if (error) return setStatus(error.message, true);
  rows = data;
  ctx = r.lookups ? await r.lookups() : {};
  setStatus('');
  renderList();
}

const cell = (c, row) => String(c.value(row, ctx) ?? '');

function renderList() {
  const r = resource();
  const q = $('search').value.trim().toLowerCase();
  shown = rows.map((row, i) => ({ row, i })).filter(({ row }) =>
    !q || r.columns.some((c) => cell(c, row).toLowerCase().includes(q)));

  if (!shown.length) {
    $('list').innerHTML = `<p class="empty">${escapeHtml(t(rows.length ? 'No matches.' : 'Nothing here yet.'))}</p>`;
    return;
  }
  $('list').innerHTML = shown.map(({ row, i }) => {
    const [title, tag, ...others] = r.columns;
    const meta = r.summary ? escapeHtml(r.summary(row))
      : others.slice(0, 3).map((c) => `${escapeHtml(c.label)} <b>${escapeHtml(cell(c, row))}</b>`).join(' · ');
    const extra = (r.actions ?? []).map((a, n) => (a.show?.(row) ?? true)
      && `<button class="pill ghost small" data-kind="action" data-row="${i}" data-action="${n}">${escapeHtml(
        t(typeof a.label === 'function' ? a.label(row) : a.label))}</button>`).filter(Boolean).join('');
    return `<article class="item">
      <div class="head"><span class="name">${escapeHtml(cell(title, row))}</span><span class="tag">${escapeHtml(cell(tag, row))}</span></div>
      <p class="meta">${meta}</p>
      <div class="acts">
        <button class="pill solid small" data-kind="review" data-row="${i}">${t('Review')}</button>
        ${r.fields ? `<button class="pill ghost small" data-kind="edit" data-row="${i}">${t('Edit')}</button>` : ''}
        ${extra}
        ${(r.fields || r.canDelete) ? `<button class="pill danger small" data-kind="delete" data-row="${i}">${t('Delete')}</button>` : ''}
      </div></article>`;
  }).join('');
}

$('search').addEventListener('input', renderList);

$('list').addEventListener('click', async (e) => {
  const btn = e.target.closest('button[data-kind]');
  if (!btn) return;
  const row = rows[Number(btn.dataset.row)];
  const kind = btn.dataset.kind;
  if (kind === 'review') return openReview(row);
  if (kind === 'edit') return openEditor(row);
  if (kind === 'delete') return askDelete(row);
  return mutate(resource().actions[Number(btn.dataset.action)].run(row));
});

async function mutate(request) {
  const { error } = await request;
  if (error) return setStatus(error.message, true);
  await load();
}

// ---------- Review and delete ----------

function openReview(row) {
  const r = resource();
  $('review-title').textContent = `${t('Review')}: ${cell(r.columns[0], row)}`;
  $('review-body').innerHTML = r.columns.slice(1).map((c) =>
    `<div><dt>${escapeHtml(c.label)}</dt><dd>${escapeHtml(cell(c, row))}</dd></div>`).join('');
  $('review-actions').innerHTML = [
    r.fields && `<button class="pill solid" data-go="edit">${t('Edit')}</button>`,
    (r.fields || r.canDelete) && `<button class="pill danger" data-go="delete">${t('Delete')}</button>`,
  ].filter(Boolean).join('');
  $('review-actions').onclick = (e) => {
    const go = e.target.dataset.go;
    if (!go) return;
    $('review').close();
    if (go === 'edit') openEditor(row); else askDelete(row);
  };
  $('review').showModal();
}
$('review-close').addEventListener('click', () => $('review').close());

function askDelete(row) {
  $('confirm-msg').textContent = t('Delete this item? This cannot be undone.');
  $('confirm-yes').onclick = async () => {
    $('confirm').close();
    await mutate(sb.from(resource().table).delete().eq('id', row.id));
  };
  $('confirm').showModal();
}
$('confirm-no').addEventListener('click', () => $('confirm').close());

// ---------- Add / edit form ----------


function display(f, value) {
  if (f.type === 'list') return Array.isArray(value) ? value.join(', ') : '';
  if (f.type === 'json') return JSON.stringify(value ?? [], null, 2);
  return value;
}

function parseJson(label, text) {
  try {
    return JSON.parse(text);
  } catch {
    throw new Error(`${label} is not valid JSON`);
  }
}

function fieldHtml(f, row) {
  const initial = row ? row[f.name] : (typeof f.default === 'function' ? f.default() : f.default);
  const attrs = `name="${f.name}" ${f.required ? 'required' : ''}`;
  const value = escapeHtml(display(f, initial));
  let input;
  if (f.type === 'select') {
    input = `<select ${attrs}>${f.options.map((o) =>
      `<option value="${o}" ${o === initial ? 'selected' : ''}>${o}</option>`).join('')}</select>`;
  } else if (f.type === 'textarea' || f.type === 'json') {
    input = `<textarea ${attrs} rows="3">${value}</textarea>`;
  } else if (f.type === 'checkbox') {
    return `<label class="check"><input type="checkbox" ${attrs} ${initial ? 'checked' : ''} /> ${escapeHtml(f.label)}</label>`;
  } else {
    input = `<input type="${f.type === 'list' ? 'text' : f.type ?? 'text'}" ${f.type === 'number' ? 'step="any"' : ''} ${attrs} value="${value}" />`;
  }
  return `<label>${escapeHtml(f.label)}${input}</label>`;
}

function openEditor(row = null) {
  editingId = row?.id ?? null;
  $('editor-title').textContent = `${t(row ? 'Edit' : 'Add')}: ${t(resource().label)}`;
  $('editor-fields').innerHTML = resource().fields.map((f) => fieldHtml(f, row)).join('');
  $('editor-error').textContent = '';
  $('editor').showModal();
}

function readForm(form) {
  const values = {};
  for (const f of resource().fields) {
    const input = form.elements[f.name];
    if (f.type === 'checkbox') {
      values[f.name] = input.checked;
      continue;
    }
    const text = input.value.trim();
    if (URL_FIELDS.includes(f.name) && text && !/^https:\/\//i.test(text)) {
      throw new Error(`${f.label} must start with https://`);
    }
    if (f.type === 'list') values[f.name] = text.split(',').map((x) => x.trim()).filter(Boolean);
    else if (f.type === 'json') values[f.name] = text === '' ? [] : parseJson(f.label, text);
    else if (text === '') values[f.name] = f.emptyAs ?? null;
    else values[f.name] = f.type === 'number' ? Number(text) : text;
  }
  return values;
}

$('add-btn').addEventListener('click', () => openEditor());
$('cancel-btn').addEventListener('click', () => $('editor').close());

$('editor-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  let values;
  try {
    values = readForm(e.currentTarget);
  } catch (err) {
    $('editor-error').textContent = err.message;
    return;
  }
  const table = sb.from(resource().table);
  const { error } = editingId
    ? await table.update(values).eq('id', editingId)
    : await table.insert(values);
  if (error) {
    $('editor-error').textContent = error.message;
    return;
  }
  $('editor').close();
  await load();
});

applyLang();
