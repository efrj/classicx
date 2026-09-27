<div class="card bg-black border border-secondary shadow-lg rounded-4 p-4 p-md-5" style="max-width: 460px; width: 100%;">
    <div class="text-center mb-4">
        <svg viewBox="0 0 24 24" aria-hidden="true" width="40" height="40" fill="currentColor" class="text-white mb-3">
            <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"></path>
        </svg>
        <h1 class="h3 fw-bold text-white">Create your account</h1>
        <p class="text-secondary small">Join ClassicX today and join the conversation</p>
    </div>

    <form method="POST" action="<%= Routes.UrlTo("Auth", "RegisterPost", Empty) %>">
        <input type="hidden" name="csrf_token" value="<%= H(CsrfToken()) %>">

        <div class="form-floating mb-3">
            <input type="text" class="form-control bg-black text-white border-secondary" id="nameInput" name="name" placeholder="Full Name" maxlength="50" required autofocus>
            <label for="nameInput" class="text-secondary">Name</label>
        </div>

        <div class="form-floating mb-3">
            <input type="text" class="form-control bg-black text-white border-secondary" id="handleInput" name="handle" placeholder="username" maxlength="20" required pattern="^[a-zA-Z0-9_]{3,20}$" title="3-20 characters: letters, numbers, underscores only">
            <label for="handleInput" class="text-secondary">Handle (e.g. john_doe)</label>
        </div>

        <div class="form-floating mb-3">
            <input type="email" class="form-control bg-black text-white border-secondary" id="emailInput" name="email" placeholder="name@example.com" maxlength="100" required>
            <label for="emailInput" class="text-secondary">Email</label>
        </div>

        <div class="form-floating mb-4">
            <input type="password" class="form-control bg-black text-white border-secondary" id="passwordInput" name="password" placeholder="Password" minlength="6" maxlength="100" required>
            <label for="passwordInput" class="text-secondary">Password (min. 6 characters)</label>
        </div>

        <button type="submit" class="btn btn-light rounded-pill w-100 fw-bold py-2 mb-3">Create account</button>
    </form>

    <div class="text-center mt-3">
        <div class="text-secondary small">
            Already have an account? 
            <a href="<%= Routes.UrlTo("Auth", "Login", Empty) %>" class="text-primary fw-bold text-decoration-none">Sign in</a>
        </div>
        <div class="text-secondary smaller mt-2">
            <a href="<%= Routes.UrlTo("Home", "Index", Empty) %>" class="text-muted text-decoration-none">← Back to Timeline</a>
        </div>
    </div>
</div>
