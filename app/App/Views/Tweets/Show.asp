<header class="x-header-sticky p-3"><h1 class="h5 fw-bold mb-0">Post</h1></header>
<% Set tweetItem = Model.Tweet %>
<!--#include file="../Shared/_TweetCard.asp"-->
<form class="p-3 border-bottom" action="<%= Routes.UrlTo("Tweets", "CreatePost", Empty) %>" method="POST">
    <input type="hidden" name="csrf_token" value="<%= H(CsrfToken()) %>">
    <input type="hidden" name="parent_id" value="<%= Model.Tweet.Id %>">
    <label class="form-label" for="reply-content">Post your reply</label>
    <textarea class="form-control mb-2" id="reply-content" name="content" maxlength="280" required rows="3"></textarea>
    <button class="btn btn-primary rounded-pill" type="submit">Reply</button>
</form>
<%
Dim replyIt : Set replyIt = Model.Replies.GetIterator
Do While replyIt.HasNext
    Set tweetItem = replyIt.GetNext
%>
<!--#include file="../Shared/_TweetCard.asp"-->
<% Loop %>
