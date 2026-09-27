<%
Dim streamIt : Set streamIt = Model.Tweets.GetIterator
If Not streamIt.HasNext Then
%><p class="text-secondary p-4">No posts yet.</p><%
End If
Do While streamIt.HasNext
    Dim tweetItem : Set tweetItem = streamIt.GetNext
%>
<!--#include file="_TweetCard.asp"-->
<% Loop %>
