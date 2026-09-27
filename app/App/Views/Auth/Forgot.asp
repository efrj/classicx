<div class="card bg-black border border-secondary shadow-lg rounded-4 p-4 p-md-5" style="max-width: 440px; width: 100%;">
    <div class="text-center mb-4">
        <svg viewBox="0 0 24 24" aria-hidden="true" width="40" height="40" fill="currentColor" class="text-white mb-3">
            <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"></path>
        </svg>
        <h1 class="h3 fw-bold text-white">Find your account</h1>
        <p class="text-secondary small">Enter your handle or email to reset your password</p>
    </div>

    <form method="POST" action="<%= Routes.UrlTo("Auth", "ForgotPost", Empty) %>">
        <input type="hidden" name="csrf_token" value="<%= H(CsrfToken()) %>">

        <div class="form-floating mb-3">
            <input type="text" class="form-control bg-black text-white border-secondary" id="loginInput" name="login" placeholder="handle or email" required autofocus>
            <label for="loginInput" class="text-secondary">Handle or email</label>
        </div>

        <div class="form-floating mb-4">
            <input type="password" class="form-control bg-black text-white border-secondary" id="passwordInput" name="password" placeholder="New password" required minlength="6">
            <label for="passwordInput" class="text-secondary">New password</label>
        </div>

        <button type="submit" class="btn btn-light rounded-pill w-100 fw-bold py-2 mb-3">Reset Password</button>
    </form>

    <div class="d-flex flex-column gap-2 text-center mt-3">
        <div class="text-secondary small">
            Remembered your password? 
            <a href="<%= Routes.UrlTo("Auth", "Login", Empty) %>" class="text-primary fw-bold text-decoration-none">Sign in</a>
        </div>
        <div class="text-secondary smaller mt-2">
            <a href="<%= Routes.UrlTo("Home", "Index", Empty) %>" class="text-muted text-decoration-none">← Back to Timeline</a>
        </div>
    </div>
</div>
