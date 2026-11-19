const chat = document.getElementById('chat-box');
const chatLauncher = document.getElementById('chat-open');
let chatHistoryLoaded = false;

function openChat() {
  chat.classList.add('open'); document.body.classList.add('chat-open'); chat.setAttribute('aria-hidden', 'false'); chatLauncher.setAttribute('aria-expanded', 'true');
  loadChatHistory();
}
function closeChat() { chat.classList.remove('open'); document.body.classList.remove('chat-open'); chat.setAttribute('aria-hidden', 'true'); chatLauncher.setAttribute('aria-expanded', 'false'); }
chatLauncher.addEventListener('click', openChat);
document.querySelector('.footer-chat-open').addEventListener('click', openChat);
document.getElementById('chat-close').addEventListener('click', closeChat);

/* The browser keeps a random token; the server only stores its SHA-256 hash. */
function chatToken() {
  try {
    let token = localStorage.getItem('integrain-chat-token');
    if (!/^[A-Za-z0-9_-]{32,128}$/.test(token || '')) {
      token = Array.from(crypto.getRandomValues(new Uint8Array(24)), b => b.toString(16).padStart(2, '0')).join('');
      localStorage.setItem('integrain-chat-token', token);
    }
    return token;
  } catch { return window.__chatTokenFallback ||= Array.from(crypto.getRandomValues(new Uint8Array(24)), b => b.toString(16).padStart(2, '0')).join(''); }
}

function addChatBubble(text, kind = 'bot') {
  const messages = document.getElementById('chat-messages'), bubble = document.createElement('div');
  bubble.className = `chat-bubble ${kind}`; bubble.textContent = text; messages.append(bubble);
  messages.scrollTop = messages.scrollHeight;
  return bubble;
}

async function loadChatHistory() {
  if (chatHistoryLoaded) return;
  chatHistoryLoaded = true;
  try {
    const { messages } = await api('chat/history', { method: 'POST', body: { token: chatToken() } });
    messages.forEach(m => addChatBubble(m.message_text, m.sender === 'Visitor' ? 'user' : 'bot'));
  } catch { chatHistoryLoaded = false; /* try again next time the chat opens */ }
}

/* ---------- Job application (collected in the chat, saved with sp_submit_application) ---------- */
let applicationStep = -1; let openJobs = [];
const applicationAnswers = {};
const applicationSteps = [
  { key: 'first_name', ask: 'What is your first name?', check: v => v.length >= 1 && v.length <= 60 || 'Please enter your first name (up to 60 characters).' },
  { key: 'last_name', ask: 'And your last name?', check: v => v.length >= 1 && v.length <= 60 || 'Please enter your last name (up to 60 characters).' },
  { key: 'contact_no', ask: 'What phone number can we reach you at?', check: v => /^[0-9+\-\s()]{7,20}$/.test(v) || 'Please enter a valid phone number (digits, +, -, spaces).' },
  { key: 'email', ask: 'What is your email address?', check: v => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v) && v.length <= 100 || 'That email address does not look right. Please try again.' },
  { key: 'opening_id', ask: () => `Which position are you applying for? Reply with the number:\n${openJobs.map((j, i) => `${i + 1}. ${j.description}`).join('\n')}`, check: v => { const n = parseInt(v, 10); const byName = openJobs.find(j => j.description.toLowerCase() === v.toLowerCase()); return byName ? byName.opening_id : (n >= 1 && n <= openJobs.length ? openJobs[n - 1].opening_id : 'Please reply with one of the position numbers.'); } },
  { key: 'message', ask: 'Any message or experience you would like to share? (Type "None" if not applicable)', check: v => v.length <= 2000 || 'Please keep it under 2000 characters.' }
];

async function startJobApplication() {
  openChat();
  addChatBubble('I want to apply for a job.', 'user');
  try { openJobs = await api('jobs'); } catch { openJobs = []; }
  if (!openJobs.length) { addChatBubble('We have no open positions right now. Please check back soon!'); return; }
  applicationStep = 0; Object.keys(applicationAnswers).forEach(k => delete applicationAnswers[k]);
  addChatBubble(`Great! I can take your application here. ${applicationSteps[0].ask}`);
  document.getElementById('chat-input').focus();
}

async function handleApplicationAnswer(text) {
  const step = applicationSteps[applicationStep];
  const result = step.check(text);
  if (typeof result === 'string') { addChatBubble(result); return; }
  applicationAnswers[step.key] = step.key === 'opening_id' ? result : (step.key === 'message' && /^none$/i.test(text) ? '' : text);
  applicationStep++;
  if (applicationStep < applicationSteps.length) {
    const ask = applicationSteps[applicationStep].ask;
    addChatBubble(typeof ask === 'function' ? ask() : ask);
    return;
  }
  const pending = addChatBubble('Submitting your application…');
  try {
    await api('applications', { method: 'POST', body: applicationAnswers });
    pending.textContent = `Thank you, ${applicationAnswers.first_name}! Your application was received. We will contact you at ${applicationAnswers.email} or ${applicationAnswers.contact_no}.`;
  } catch (error) {
    pending.textContent = `We could not submit your application: ${error.message}`;
  }
  applicationStep = -1;
}

async function sendChat(text) {
  const q = text.toLowerCase();
  if (applicationStep < 0 && /\b(apply|application)\b/.test(q)) { startJobApplication(); return; }
  addChatBubble(text, 'user');
  if (applicationStep >= 0) { await handleApplicationAnswer(text); return; }
  const typing = addChatBubble('…');
  try {
    const { reply } = await api('chat/messages', { method: 'POST', body: { token: chatToken(), text } });
    typing.textContent = reply;
  } catch (error) {
    typing.textContent = error.status === 429 ? error.message : 'Sorry, I could not reach the store right now. Please try again in a moment.';
  }
  document.getElementById('chat-messages').scrollTop = 1e6;
}

document.getElementById('chat-form').addEventListener('submit', e => {
  e.preventDefault();
  const input = document.getElementById('chat-input');
  if (input.value.trim()) { sendChat(input.value.trim()); input.value = ''; }
});
