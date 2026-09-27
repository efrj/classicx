<%
Dim currentUser : Set currentUser = Auth.CurrentUser
Dim currentCtrl : currentCtrl = MVC.ControllerName
Dim currentAct  : currentAct = MVC.ActionName
Dim unreadNotifs : unreadNotifs = NotificationRepository.GetUnreadCount(currentUser.Id)
%>

<aside class="col-auto col-md-3 col-xl-2 px-0 x-sidebar-left">
    <div class="d-flex flex-column align-items-start w-100">
        <!-- Logo -->
        <a aria-label="Home" href="<%= Routes.UrlTo("Home", "Index", Empty) %>" class="x-logo-btn" title="ClassicX Home">
            <svg viewBox="0 0 24 24" aria-hidden="true" width="30" height="30" fill="currentColor">
                <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"></path>
            </svg>
        </a>

        <!-- Navigation Links -->
        <nav class="nav flex-column w-100 mt-2">
            <a aria-label="Home" href="<%= Routes.UrlTo("Home", "Index", Empty) %>" class="x-nav-link <%= Choice(currentCtrl = "Home" And currentAct = "Index", "active", "") %>">
                <i class="bi <%= Choice(currentCtrl = "Home" And currentAct = "Index", "bi-house-door-fill", "bi-house-door") %>"></i>
                <span class="d-none d-xl-inline">Home</span>
            </a>

            <a aria-label="Explore" href="<%= Routes.UrlTo("Home", "Explore", Empty) %>" class="x-nav-link <%= Choice(currentCtrl = "Home" And currentAct = "Explore", "active", "") %>">
                <i class="bi <%= Choice(currentCtrl = "Home" And currentAct = "Explore", "bi-hash", "bi-hash") %>"></i>
                <span class="d-none d-xl-inline">Explore</span>
            </a>

            <a aria-label="Notifications" href="<%= Routes.UrlTo("Notifications", "Index", Empty) %>" class="x-nav-link position-relative <%= Choice(currentCtrl = "Notifications", "active", "") %>">
                <i class="bi <%= Choice(currentCtrl = "Notifications", "bi-bell-fill", "bi-bell") %>"></i>
                <span class="d-none d-xl-inline">Notifications</span>
                <% If unreadNotifs > 0 Then %>
                    <span class="position-absolute top-2 start-4 translate-middle p-1 bg-primary border border-dark rounded-circle" style="left: 32px; top: 14px;"></span>
                <% End If %>
            </a>

            <a aria-label="Bookmarks" href="<%= Routes.UrlTo("Tweets", "Bookmarks", Empty) %>" class="x-nav-link <%= Choice(currentCtrl = "Tweets" And currentAct = "Bookmarks", "active", "") %>">
                <i class="bi <%= Choice(currentCtrl = "Tweets" And currentAct = "Bookmarks", "bi-bookmark-fill", "bi-bookmark") %>"></i>
                <span class="d-none d-xl-inline">Bookmarks</span>
            </a>

            <a aria-label="Profile" href="<%= Routes.UrlTo("Users", "Profile", Array("handle", currentUser.Handle)) %>" class="x-nav-link <%= Choice(currentCtrl = "Users" And currentAct = "Profile" And Request("handle") = currentUser.Handle, "active", "") %>">
                <i class="bi <%= Choice(currentCtrl = "Users" And currentAct = "Profile", "bi-person-fill", "bi-person") %>"></i>
                <span class="d-none d-xl-inline">Profile</span>
            </a>
        </nav>

        <!-- Post Button -->
        <button type="button" class="x-btn-post-large" aria-label="Compose post" data-bs-toggle="modal" data-bs-target="#composeModal">
            <i class="bi bi-feather d-xl-none fs-4"></i>
            <span class="d-none d-xl-inline">Post</span>
        </button>
    </div>

    <!-- User Profile Badge & Switcher Dropdown -->
    <div class="dropdown dropup w-100">
        <div role="button" tabindex="0" aria-label="Switch demo account" class="x-user-badge" data-bs-toggle="dropdown" aria-expanded="false">
            <img src="<%= H(currentUser.AvatarUrl) %>" alt="<%= H(currentUser.Name) %>" class="rounded-circle" width="40" height="40" style="object-fit: cover;">
            <div class="d-none d-xl-flex flex-column text-truncate" style="line-height: 1.2; max-width: 140px;">
                <span class="fw-bold text-truncate text-white"><%= H(currentUser.Name) %></span>
                <span class="text-secondary small text-truncate">@<%= H(currentUser.Handle) %></span>
            </div>
            <i class="bi bi-three-dots ms-auto text-secondary d-none d-xl-inline"></i>
        </div>

        <ul class="dropdown-menu dropdown-menu-dark shadow border-secondary py-2" style="background-color: #000; min-width: 250px; border-radius: 16px;">
            <li class="px-3 py-2 border-bottom border-secondary">
                <div class="fw-bold text-white small">Switch Demo Account</div>
            </li>
            <%
                Dim allUsers : Set allUsers = UserRepository.GetAllUsers()
                Dim uIt : Set uIt = allUsers.GetIterator
                Do While uIt.HasNext
                    Dim usr : Set usr = uIt.GetNext
            %>
                <li>
                    <form method="POST" action="<%= Routes.UrlTo("Auth", "SwitchAccount", Empty) %>">
<input type="hidden" name="csrf_token" value="<%= H(CsrfToken()) %>">
<input type="hidden" name="user_id" value="<%= usr.Id %>">
<button type="submit" class="dropdown-item d-flex align-items-center gap-2 py-2 <%= Choice(usr.Id = currentUser.Id, "active bg-dark", "") %>" 
                       >
                        <img src="<%= H(usr.AvatarUrl) %>" width="32" height="32" class="rounded-circle" style="object-fit: cover;">
                        <div class="flex-grow-1 text-truncate">
                            <div class="small fw-bold"><%= H(usr.Name) %></div>
                            <div class="text-muted smaller">@<%= H(usr.Handle) %></div>
                        </div>
                        <% If usr.Id = currentUser.Id Then %>
                            <i class="bi bi-check-lg text-primary ms-auto"></i>
                        <% End If %>
                    </button></form>
                </li>
            <% Loop %>
            <li><hr class="dropdown-divider border-secondary"></li>
            <li>
                <%
                    Dim currentHandleDisplay : currentHandleDisplay = "user"
                    If IsObject(currentUser) Then
                        If Not currentUser Is Nothing Then
                            currentHandleDisplay = currentUser.Handle
                        End If
                    End If
                %>
                <form method="POST" action="<%= Routes.UrlTo("Auth", "Logout", Empty) %>">
<input type="hidden" name="csrf_token" value="<%= H(CsrfToken()) %>">
<button type="submit" class="dropdown-item py-2 text-danger fw-bold">
                    <i class="bi bi-box-arrow-right me-2"></i> Reset demo account
                </button></form>
            </li>
        </ul>
    </div>
</aside>
