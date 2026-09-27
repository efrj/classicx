<%
Dim currentUserIdForSidebar : currentUserIdForSidebar = Auth.CurrentUserId
Dim trendsList : Set trendsList = TrendRepository.GetTrends(5)
Dim whoToFollowList : Set whoToFollowList = UserRepository.GetWhoToFollow(currentUserIdForSidebar, 3)
%>

<aside class="col-lg-4 col-xl-3 d-none d-lg-block x-sidebar-right">
    <!-- Search Box -->
    <form action="<%= Routes.UrlTo("Home", "Explore", Empty) %>" method="GET">
<input type="hidden" name="_A" value="Explore">
        <div class="x-search-box">
            <i class="bi bi-search"></i>
            <input type="text" name="q" aria-label="Search posts" class="x-search-input" placeholder="Search" value="<%= H(Request("q")) %>" autocomplete="off">
        </div>
    </form>

    <!-- Subscribe to Premium Card -->
    <div class="x-right-card">
        <h5 class="x-right-card-title">Subscribe to Premium</h5>
        <p class="text-secondary small mb-3">Subscribe to unlock new features and if eligible, receive a share of ads revenue.</p>
        <button type="button" class="btn btn-primary rounded-pill fw-bold btn-sm px-3" data-bs-toggle="modal" data-bs-target="#premiumModal">Subscribe</button>
    </div>

    <!-- What's happening / Trends -->
    <div class="x-right-card">
        <h5 class="x-right-card-title">What's happening</h5>
        <%
            Dim trIt : Set trIt = trendsList.GetIterator
            Do While trIt.HasNext
                Dim tr : Set tr = trIt.GetNext
        %>
            <a href="<%= Routes.UrlTo("Home", "Explore", Array("q", tr.Topic)) %>" class="x-trend-item">
                <div>
                    <div class="x-trend-category"><%= H(tr.Category) %></div>
                    <div class="x-trend-topic"><%= H(tr.Topic) %></div>
                    <div class="x-trend-count"><%= H(tr.PostCount) %></div>
                </div>
                <i class="bi bi-three-dots text-secondary"></i>
            </a>
        <% Loop %>
    </div>

    <!-- Who to follow -->
    <div class="x-right-card">
        <h5 class="x-right-card-title">Who to follow</h5>
        <%
            Dim wfIt : Set wfIt = whoToFollowList.GetIterator
            If Not wfIt.HasNext Then
        %>
            <p class="text-secondary small mb-0">No suggestions right now.</p>
        <%
            Else
                Do While wfIt.HasNext
                    Dim wfUser : Set wfUser = wfIt.GetNext
        %>
            <div class="x-follow-item">
                <a href="<%= Routes.UrlTo("Users", "Profile", Array("handle", wfUser.Handle)) %>" class="x-follow-user">
                    <img src="<%= H(wfUser.AvatarUrl) %>" alt="<%= H(wfUser.Name) %>" class="x-follow-avatar">
                    <div class="x-follow-info">
                        <div class="fw-bold text-white small text-truncate">
                            <%= H(wfUser.Name) %>
                            <% If wfUser.IsVerified Then %>
                                <i class="bi bi-patch-check-fill x-badge-verified ms-1"></i>
                            <% End If %>
                        </div>
                        <div class="text-secondary smaller text-truncate">@<%= H(wfUser.Handle) %></div>
                    </div>
                </a>
                <div x-data="followBtn(<%= Choice(wfUser.IsFollowedByCurrent, "true", "false") %>, <%= wfUser.Id %>, '<%= Routes.UrlTo("Users", "FollowPost", Empty) %>', '<%= Routes.UrlTo("Users", "UnfollowPost", Empty) %>')">
                    <button type="button" 
                            :class="isFollowing ? 'x-btn-following' : 'x-btn-follow'"
                            @mouseenter="isHovered = true" 
                            @mouseleave="isHovered = false"
                            @click="toggle()" :disabled="isLoading" 
                            x-text="buttonText">
                        Follow
                    </button>
                    <p class="text-danger small" role="status" x-text="error"></p>
                </div>
            </div>
        <%
                Loop
            End If
        %>
    </div>

    <!-- Footer Links -->
    <div class="px-3 text-secondary smaller" style="line-height: 1.6; font-size: 0.78rem;">
        <span class="me-2">Terms of Service</span>
        <span class="me-2">Privacy Policy</span>
        <span class="me-2">Cookie Policy</span>
        <span class="me-2">Accessibility</span>
        <div class="mt-2 text-muted">ClassicX © 2026 • ASP 3.0 VBScript + Sane MVC + MariaDB</div>
    </div>
</aside>

<!-- Premium Feature Modal -->
<div class="modal fade" id="premiumModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content x-modal-dark p-3">
            <div class="modal-header border-0 pb-0">
                <h5 class="modal-title fw-bold text-white">ClassicX Verified Premium</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body text-center py-4">
                <i class="bi bi-patch-check-fill text-primary" style="font-size: 3rem;"></i>
                <h4 class="fw-bold text-white mt-3">Active Server Pages Power</h4>
                <p class="text-secondary">Get the blue checkmark, prioritize your tweets in threads, write up to 4,000 characters, and run blazing fast queries on MariaDB 10 with AXONASP.</p>
                <div class="d-grid gap-2 mt-4">
                    <button class="btn btn-primary rounded-pill fw-bold py-2" data-bs-dismiss="modal">Enjoy Free Demo Mode</button>
                </div>
            </div>
        </div>
    </div>
</div>
