<!-- Explore Header -->
<header class="x-header-sticky px-3 py-2">
    <form action="<%= Routes.UrlTo("Home", "Explore", Empty) %>" method="GET">
        <input type="hidden" name="_A" value="Explore">
        <% If Model.SearchType <> "" And Model.SearchType <> "top" Then %>
            <input type="hidden" name="type" value="<%= H(Model.SearchType) %>">
        <% End If %>
        <div class="x-search-box mb-0">
            <i class="bi bi-search"></i>
            <input type="text" name="q" aria-label="Search ClassicX" class="x-search-input" placeholder="Search ClassicX" value="<%= H(Model.Query) %>" autocomplete="off">
        </div>
    </form>
</header>

<% If Model.Query <> "" Then %>
    <div class="p-3 border-bottom border-secondary border-opacity-25">
        <h6 class="text-secondary small mb-1">Search results for</h6>
        <h4 class="fw-bold text-white mb-0">"<%= H(Model.Query) %>"</h4>
    </div>

    <!-- Search Tabs (Top, Latest, People) -->
    <nav class="x-header-tabs" aria-label="Search filter tabs">
        <a class="x-header-tab <%= Choice(Model.SearchType = "top", "active", "") %>" href="<%= Routes.UrlTo("Home", "Explore", Array("q", Model.Query, "type", "top")) %>">
            Top
        </a>
        <a class="x-header-tab <%= Choice(Model.SearchType = "latest", "active", "") %>" href="<%= Routes.UrlTo("Home", "Explore", Array("q", Model.Query, "type", "latest")) %>">
            Latest
        </a>
        <a class="x-header-tab <%= Choice(Model.SearchType = "people", "active", "") %>" href="<%= Routes.UrlTo("Home", "Explore", Array("q", Model.Query, "type", "people")) %>">
            People
        </a>
    </nav>
<% Else %>
    <!-- Trending banner -->
    <div class="p-4 border-bottom border-secondary border-opacity-25" style="background: linear-gradient(180deg, rgba(29,155,240,0.15) 0%, rgba(0,0,0,0) 100%);">
        <div class="badge bg-primary mb-2">Technology · Trending</div>
        <h3 class="fw-bold text-white">ClassicX: Rebuilding the Web with ASP & MariaDB</h3>
        <p class="text-secondary mb-0">Discover trending topics, discussions, and posts across the community.</p>
    </div>
<% End If %>

<!-- Search Content -->
<% If Model.SearchType = "people" Then %>
    <div class="x-users-stream">
        <%
            Dim pUserIt : Set pUserIt = Model.Users.GetIterator
            If Not pUserIt.HasNext Then
        %>
            <div class="text-center py-5 px-4">
                <i class="bi bi-people text-secondary" style="font-size: 2.5rem;"></i>
                <h5 class="fw-bold mt-3 text-white">No people found</h5>
                <p class="text-secondary small">Try searching for another username, handle, or bio keyword.</p>
            </div>
        <%
            Else
                Do While pUserIt.HasNext
                    Dim pUser : Set pUser = pUserIt.GetNext
        %>
            <div class="p-3 border-bottom border-secondary border-opacity-25 d-flex gap-3 align-items-start">
                <a href="<%= Routes.UrlTo("Users", "Profile", Array("handle", pUser.Handle)) %>">
                    <img src="<%= H(pUser.AvatarUrl) %>" alt="" class="rounded-circle" width="48" height="48" style="object-fit: cover;">
                </a>
                <div class="flex-grow-1 min-w-0">
                    <div class="d-flex justify-content-between align-items-start gap-2">
                        <div>
                            <a href="<%= Routes.UrlTo("Users", "Profile", Array("handle", pUser.Handle)) %>" class="fw-bold text-white text-decoration-none hover-underline d-inline-block text-truncate">
                                <%= H(pUser.Name) %>
                                <% If pUser.IsVerified Then %>
                                    <i class="bi bi-patch-check-fill x-badge-verified ms-1"></i>
                                <% End If %>
                            </a>
                            <div class="text-secondary small">@<%= H(pUser.Handle) %></div>
                        </div>
                        <% If pUser.Id <> Auth.CurrentUserId Then %>
                        <div x-data="followBtn(<%= Choice(pUser.IsFollowedByCurrent, "true", "false") %>, <%= pUser.Id %>, '<%= Routes.UrlTo("Users", "FollowPost", Empty) %>', '<%= Routes.UrlTo("Users", "UnfollowPost", Empty) %>')">
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
                    <% If Len(pUser.Bio) > 0 Then %>
                        <p class="text-white small mt-1 mb-0" style="word-break: break-word;"><%= H(pUser.Bio) %></p>
                    <% End If %>
                </div>
            </div>
        <%
                Loop
            End If
        %>
    </div>
<% Else %>
    <!-- Tweets Stream -->
    <div class="x-tweets-stream">
        <%
            Dim expIt : Set expIt = Model.Tweets.GetIterator
            If Not expIt.HasNext Then
        %>
            <div class="text-center py-5 px-4">
                <i class="bi bi-search text-secondary" style="font-size: 2.5rem;"></i>
                <h5 class="fw-bold mt-3 text-white">No results found</h5>
                <p class="text-secondary small">Try searching for people, topics, or keywords like "#ClassicASP" or "MariaDB".</p>
            </div>
        <%
            Else
                Do While expIt.HasNext
                    Set tweetItem = expIt.GetNext
        %>
                    <!--#include file="../Shared/_TweetCard.asp"-->
        <%
                Loop
            End If
        %>
    </div>
<% End If %>
