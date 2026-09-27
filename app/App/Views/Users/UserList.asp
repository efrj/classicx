<!-- Sticky Header -->
<header class="x-header-sticky p-3 d-flex align-items-center gap-3">
    <a href="<%= Routes.UrlTo("Users", "Profile", Array("handle", Model.ProfileUser.Handle)) %>" class="btn btn-icon text-white rounded-circle p-1" title="Back to profile">
        <i class="bi bi-arrow-left fs-5"></i>
    </a>
    <div>
        <h1 class="h5 fw-bold mb-0 text-white"><%= H(Model.ProfileUser.Name) %></h1>
        <div class="text-secondary smaller">@<%= H(Model.ProfileUser.Handle) %></div>
    </div>
</header>

<!-- Tabs: Followers / Following -->
<nav class="x-header-tabs" aria-label="Followers and following tabs">
    <a class="x-header-tab <%= Choice(Model.ListType = "followers", "active", "") %>" href="<%= Routes.UrlTo("Users", "Followers", Array("handle", Model.ProfileUser.Handle)) %>">
        Followers
    </a>
    <a class="x-header-tab <%= Choice(Model.ListType = "following", "active", "") %>" href="<%= Routes.UrlTo("Users", "Following", Array("handle", Model.ProfileUser.Handle)) %>">
        Following
    </a>
</nav>

<!-- User List Container -->
<div class="user-list">
<%
Dim uListIt : Set uListIt = Model.Users.GetIterator
If Not uListIt.HasNext Then
%>
    <div class="p-5 text-center text-secondary">
        <p class="mb-1 fw-bold fs-5 text-white">
            <%= Choice(Model.ListType = "followers", "Looking for followers?", "Be in the know") %>
        </p>
        <p class="small text-secondary">
            <%= Choice(Model.ListType = "followers", "When someone follows @" & Model.ProfileUser.Handle & ", they'll show up here.", "Following people helps you see their posts in your Home timeline.") %>
        </p>
    </div>
<%
Else
    Do While uListIt.HasNext
        Dim listUser : Set listUser = uListIt.GetNext
%>
    <div class="p-3 border-bottom border-secondary border-opacity-25 d-flex gap-3 align-items-start">
        <a href="<%= Routes.UrlTo("Users", "Profile", Array("handle", listUser.Handle)) %>">
            <img src="<%= H(listUser.AvatarUrl) %>" alt="" class="rounded-circle" width="48" height="48" style="object-fit: cover;">
        </a>
        <div class="flex-grow-1 min-w-0">
            <div class="d-flex justify-content-between align-items-start gap-2">
                <div>
                    <a href="<%= Routes.UrlTo("Users", "Profile", Array("handle", listUser.Handle)) %>" class="fw-bold text-white text-decoration-none hover-underline d-inline-block text-truncate">
                        <%= H(listUser.Name) %>
                        <% If listUser.IsVerified Then %>
                            <i class="bi bi-patch-check-fill x-badge-verified ms-1"></i>
                        <% End If %>
                    </a>
                    <div class="text-secondary small">@<%= H(listUser.Handle) %></div>
                </div>
                <% If listUser.Id <> Auth.CurrentUserId Then %>
                <div x-data="followBtn(<%= Choice(listUser.IsFollowedByCurrent, "true", "false") %>, <%= listUser.Id %>, '<%= Routes.UrlTo("Users", "FollowPost", Empty) %>', '<%= Routes.UrlTo("Users", "UnfollowPost", Empty) %>')">
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
                <% End If %>
            </div>
            <% If Len(listUser.Bio) > 0 Then %>
                <p class="text-white small mt-1 mb-0" style="word-break: break-word;"><%= H(listUser.Bio) %></p>
            <% End If %>
        </div>
    </div>
<%
    Loop
End If
%>
</div>
