<!-- Sticky Home Header with Tabs -->
<header class="x-header-sticky">
    <div class="px-3 pt-3 pb-2 d-flex justify-content-between align-items-center">
        <h5 class="fw-bold mb-0 text-white">Home</h5>
        <span class="badge bg-dark border border-secondary text-secondary small py-1 px-2">VBScript 𝕏</span>
    </div>
    <div class="x-header-tabs">
        <a href="<%= Routes.UrlTo("Home", "Index", Array("tab", "for_you")) %>" 
           class="x-header-tab <%= Choice(Model.FeedType <> "following", "active", "") %>">
            For you
        </a>
        <a href="<%= Routes.UrlTo("Home", "Index", Array("tab", "following")) %>" 
           class="x-header-tab <%= Choice(Model.FeedType = "following", "active", "") %>">
            Following
        </a>
    </div>
</header>

<!-- Compose Tweet Box -->
<!--#include file="../Shared/_ComposeBox.asp"-->

<!-- Tweets Stream -->
<div class="x-tweets-stream">
    <%
        Dim feedIt : Set feedIt = Model.Tweets.GetIterator
        If Not feedIt.HasNext Then
    %>
        <div class="text-center py-5 px-4">
            <i class="bi bi-chat-square-dots text-secondary" style="font-size: 3rem;"></i>
            <h5 class="fw-bold mt-3 text-white">Welcome to your timeline!</h5>
            <p class="text-secondary small">
                <% If Model.FeedType = "following" Then %>
                    You are not following anyone yet or they haven't posted. Check the "For you" tab or follow users on the right!
                <% Else %>
                    No posts found. Be the first to post something above!
                <% End If %>
            </p>
        </div>
    <%
        Else
            Do While feedIt.HasNext
                Set tweetItem = feedIt.GetNext
    %>
                <!--#include file="../Shared/_TweetCard.asp"-->
    <%
            Loop
        End If
    %>
</div>
