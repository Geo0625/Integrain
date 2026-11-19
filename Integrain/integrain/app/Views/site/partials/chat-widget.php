<div class="chat-launcher" id="chat-launcher">
    <button class="chat-launcher-button" id="chat-open" type="button" aria-label="Open store chat"
      aria-controls="chat-box" aria-expanded="false">
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path d="M20 11.5a7.5 7.5 0 0 1-7.5 7.5H7l-3.5 2 1.1-4A7.5 7.5 0 1 1 20 11.5Z" />
        <path d="M8 11.5h.01M12 11.5h.01M16 11.5h.01" />
      </svg>
    </button>
  </div>
  <aside class="chat-box" id="chat-box" aria-label="Store assistant" aria-hidden="true">
    <div class="chat-head">
      <div><span>&#10022;</span><b>Store Assistant<small>Here to help you</small></b></div><button id="chat-close"
        aria-label="Close chat">&#215;</button>
    </div>
    <div class="chat-messages" id="chat-messages">
      <div class="chat-bubble bot">Hi there! Ask me about our rice, prices, store hours, or applying to join our
        team.</div><button class="quick-question">What are your store hours?</button><button class="quick-question">Do
        you have rice for cooking?</button><button class="quick-question apply-question" data-apply-start>Apply for a
        job</button>
    </div>
    <form id="chat-form"><input id="chat-input" placeholder="Type your message..." aria-label="Message"><button
        aria-label="Send message">&#10148;</button></form>
  </aside>
  
