<header class="x-header-sticky p-3"><h1 class="h5 fw-bold mb-0"><%= H(Model.ProfileUser.Name) %></h1></header>
<section class="p-3">
    <img src="<%= H(Model.ProfileUser.AvatarUrl) %>" alt="" class="rounded-circle mb-3" width="80" height="80">
    <h2 class="h4 fw-bold"><%= H(Model.ProfileUser.Name) %></h2>
    <p class="text-secondary">@<%= H(Model.ProfileUser.Handle) %></p>
    <p><%= H(Model.ProfileUser.Bio) %></p>
    <p class="text-secondary"><%= H(Model.ProfileUser.Location) %></p>
    <p><strong><%= Model.ProfileUser.FollowingCount %></strong> following · <strong><%= Model.ProfileUser.FollowersCount %></strong> followers</p>
    <% If Model.ProfileUser.Id <> Auth.CurrentUserId Then %>
    <div x-data="followBtn(<%= Choice(Model.ProfileUser.IsFollowedByCurrent, "true", "false") %>, <%= Model.ProfileUser.Id %>, '<%= Routes.UrlTo("Users", "FollowPost", Empty) %>', '<%= Routes.UrlTo("Users", "UnfollowPost", Empty) %>')">
        <button class="btn btn-outline-light rounded-pill" type="button" @click="toggle()" :disabled="isLoading" x-text="buttonText">Follow</button>
        <p class="text-danger small" role="status" x-text="error"></p>
    </div>
    <% End If %>
</section>
<nav class="x-header-tabs" aria-label="Profile posts">
<% Dim profileTab : For Each profileTab In Array("posts", "replies", "likes") %>
<a class="x-header-tab <%= Choice(Model.ActiveTab = profileTab, "active", "") %>" href="<%= H(Routes.UrlTo("Users", "Profile", Array("handle", Model.ProfileUser.Handle, "tab", profileTab))) %>"><%= H(profileTab) %></a>
<% Next %>
</nav>
<!--#include file="../Shared/_Feed.asp"-->
