<%
If IsObject(tweetItem) Then
    If Not tweetItem Is Nothing Then
%>
<div class="x-tweet-card" 
     x-data="tweetCard({ id: <%= tweetItem.Id %>, isLiked: <%= Choice(tweetItem.IsLiked, "true", "false") %>, likesCount: <%= tweetItem.LikesCount %>, isRetweeted: <%= Choice(tweetItem.IsRetweeted, "true", "false") %>, retweetsCount: <%= tweetItem.RetweetsCount %>, isBookmarked: <%= Choice(tweetItem.IsBookmarked, "true", "false") %> })">
    
    <!-- Left Avatar -->
    <a href="<%= Routes.UrlTo("Users", "Profile", Array("handle", tweetItem.UserHandle)) %>">
        <img src="<%= H(tweetItem.UserAvatarUrl) %>" alt="<%= H(tweetItem.UserName) %>" class="x-tweet-avatar">
    </a>

    <!-- Right Body -->
    <div class="x-tweet-body">
        <!-- Repost Context if present -->
        <% If tweetItem.RepostUserHandle <> "" Then %>
            <div class="x-repost-banner">
                <i class="bi bi-repeat"></i>
                <span><%= H(tweetItem.RepostUserName) %> reposted</span>
            </div>
        <% End If %>

        <!-- Header Info -->
        <div class="d-flex align-items-center justify-content-between">
            <div class="x-tweet-header text-truncate">
                <a href="<%= Routes.UrlTo("Users", "Profile", Array("handle", tweetItem.UserHandle)) %>" class="x-tweet-author-name text-truncate">
                    <%= H(tweetItem.UserName) %>
                </a>
                <% If tweetItem.UserIsVerified Then %>
                    <i class="bi bi-patch-check-fill x-badge-verified"></i>
                <% End If %>
                <a href="<%= Routes.UrlTo("Users", "Profile", Array("handle", tweetItem.UserHandle)) %>" class="x-tweet-handle text-truncate">
                    @<%= H(tweetItem.UserHandle) %>
                </a>
                <span class="x-tweet-dot">·</span>
                <a class="x-tweet-time" href="<%= H(Routes.UrlTo("Tweets", "Show", Array("id", tweetItem.Id))) %>"><%= H(tweetItem.TimeAgoFormatted) %></a>
            </div>

            <!-- Tweet Options Dropdown -->
            <div class="dropdown">
                <button type="button" class="btn btn-link text-secondary p-0" data-bs-toggle="dropdown" aria-expanded="false" aria-label="Post options" style="text-decoration: none;">
                    <i class="bi bi-three-dots"></i>
                </button>
                <ul class="dropdown-menu dropdown-menu-dark dropdown-menu-end border-secondary shadow" style="background-color: #000; border-radius: 12px;">
                    <% If tweetItem.UserId = Auth.CurrentUserId Then %>
                        <li>
                            <form action="<%= Routes.UrlTo("Tweets", "DeletePost", Empty) %>" method="POST" onsubmit="return confirm('Delete this post?');">
                                <input type="hidden" name="csrf_token" value="<%= H(CsrfToken()) %>">
<input type="hidden" name="id" value="<%= tweetItem.Id %>">
                                <button type="submit" class="dropdown-item text-danger py-2">
                                    <i class="bi bi-trash3 me-2"></i> Delete post
                                </button>
                            </form>
                        </li>
                    <% End If %>
                    <li>
                        <button type="button" class="dropdown-item py-2" onclick="navigator.clipboard.writeText(location.origin + '<%= Routes.UrlTo("Tweets", "Show", Array("id", tweetItem.Id)) %>').then(() => alert('Link copied to clipboard!')).catch(() => alert('Could not copy the link.'));">
                            <i class="bi bi-link-45deg me-2"></i> Copy link to post
                        </button>
                    </li>
                </ul>
            </div>
        </div>

        <!-- Tweet Content -->
        <div class="x-tweet-content">
            <div class="x-tweet-text">
                <%= Auth.FormatTweetText(tweetItem.Content) %>
            </div>

            <!-- Attached Image if any -->
            <% If tweetItem.ImageUrl <> "" Then %>
                <div class="x-tweet-image-container">
                    <img src="<%= H(tweetItem.ImageUrl) %>" class="x-tweet-image" alt="Post image" loading="lazy">
                </div>
            <% End If %>
        </div>

        <p class="text-danger small" role="status" x-text="error"></p>
        <!-- Tweet Action Buttons Row -->
        <div class="x-tweet-actions">
            <!-- Reply Button -->
            <a href="<%= Routes.UrlTo("Tweets", "Show", Array("id", tweetItem.Id)) %>" class="x-action-btn reply" title="Reply">
                <i class="bi bi-chat"></i>
                <span class="smaller"><%= Choice(tweetItem.RepliesCount > 0, tweetItem.RepliesCount, "") %></span>
            </a>

            <!-- Retweet Button -->
            <button type="button" 
                    class="x-action-btn repost" 
                    :class="{ 'reposted': isRetweeted }" 
                    @click="toggleRetweet('<%= Routes.UrlTo("Tweets", "RetweetPost", Empty) %>')"
                    :disabled="isLoading" :aria-pressed="isRetweeted" aria-label="Repost" title="Repost">
                <i class="bi bi-repeat"></i>
                <span class="smaller" x-text="retweetsCount > 0 ? retweetsCount : ''"></span>
            </button>

            <!-- Like Button -->
            <button type="button" 
                    class="x-action-btn like" 
                    :class="{ 'liked': isLiked }" 
                    @click="toggleLike('<%= Routes.UrlTo("Tweets", "LikePost", Empty) %>')"
                    :disabled="isLoading" :aria-pressed="isLiked" aria-label="Like" title="Like">
                <i class="bi" :class="isLiked ? 'bi-heart-fill' : 'bi-heart'"></i>
                <span class="smaller" x-text="likesCount > 0 ? likesCount : ''"></span>
            </button>

            <!-- Views / Analytics -->
            <div class="x-action-btn" title="Views">
                <i class="bi bi-bar-chart"></i>
                <span class="smaller"><%= tweetItem.ViewsCount %></span>
            </div>

            <!-- Bookmark Button -->
            <button type="button" 
                    class="x-action-btn bookmark" 
                    :class="{ 'bookmarked': isBookmarked }" 
                    @click="toggleBookmark('<%= Routes.UrlTo("Tweets", "BookmarkPost", Empty) %>')"
                    :disabled="isLoading" :aria-pressed="isBookmarked" aria-label="Bookmark" title="Bookmark">
                <i class="bi" :class="isBookmarked ? 'bi-bookmark-fill' : 'bi-bookmark'"></i>
            </button>
        </div>
    </div>
</div>
<% 
    End If
End If 
%>
