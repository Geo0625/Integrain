<section class="page" id="login-page" data-view="login">
  <div class="login-wrap">
    <div class="login-intro"><span class="brand-mark" aria-hidden="true"><svg viewBox="0 0 64 64" focusable="false">
          <path
            d="M31 53V16m0 13c-8 0-13-5-14-12 8 0 13 4 14 12Zm0 8c8 0 13-5 14-12-8 0-13 4-14 12Zm0-20c-6-1-9-5-9-11 6 1 9 5 9 11Zm0-5c6-2 9-6 8-12-6 2-9 6-8 12ZM21 54h22" />
        </svg></span><span class="eyebrow">Integrain Portal</span>
      <h1>Welcome back</h1>
      <p>Sign in to your account. Integrain will open the dashboard assigned to your account.</p>
      <div class="login-help">Use the username and password given to you by the store administrator.</div>
    </div>
    <form class="login-form" id="login-form"><span class="eyebrow">Secure sign in</span>
      <h2>Sign in to your account</h2>
      <p>Your account determines which dashboard you can access.</p><label>Username<input type="text"
          id="login-username" required maxlength="50" placeholder="Enter your username" autocomplete="username" autocapitalize="none" spellcheck="false"></label><label>Password
        <div class="password-field"><input type="password" id="login-password" required
            placeholder="Enter your password" autocomplete="current-password"><button type="button"
            id="toggle-password" aria-label="Show password">Show</button></div>
      </label><button class="button full" type="submit">Sign in <span>&#8594;</span></button>
      <p class="login-error" id="login-error" role="alert"></p><button class="back-home" type="button"
        data-page="home">&#8592; Back to home</button>
    </form>
  </div>
</section>
