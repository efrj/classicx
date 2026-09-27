<!--#include file="../../include_all.asp"-->
<%
Class NotificationsController
    Public Model
    Public Sub Index
        Set Model = New NotificationsViewModel_Class
        Set Model.Notifications = NotificationRepository.GetNotifications(Auth.CurrentUserId)
    End Sub
End Class
Dim Controller : Set Controller = New NotificationsController
Select Case LCase(MVC.ActionName)
    Case "index": Controller.Index
    Case "readpost"
        Call RequireWrite()
        NotificationRepository.MarkAllAsRead Auth.CurrentUserId
        DAL.Close
        Response.Redirect Routes.UrlTo("Notifications", "Index", Empty)
        Response.End
    Case Else: Call HttpError("404 Not Found", "Action not found.")
End Select
Dim Model : Set Model = Controller.Model
%>
<!--#include file="../../Views/Shared/layout.header.asp"-->
<header class="x-header-sticky p-3"><h1 class="h5 fw-bold mb-0">Notifications</h1></header>
<form class="p-3" method="POST" action="<%= Routes.UrlTo("Notifications", "ReadPost", Empty) %>">
<input type="hidden" name="csrf_token" value="<%= H(CsrfToken()) %>">
<button type="submit" class="btn btn-outline-light rounded-pill">Mark all as read</button>
</form>
<%
Dim notices : Set notices = Model.Notifications.GetIterator
If Not notices.HasNext Then
%><p class="p-4 text-secondary">No notifications yet.</p><%
End If
Do While notices.HasNext
    Dim notice : Set notice = notices.GetNext
%>
<article class="p-3 border-bottom">
    <a href="<%= H(Routes.UrlTo("Users", "Profile", Array("handle", notice.ActorHandle))) %>"><%= H(notice.ActorName) %></a>
    <span><%= H(notice.NotifType) %></span>
    <% If Not notice.IsRead Then %><span class="badge bg-primary">New</span><% End If %>
    <span class="text-secondary small"><%= H(notice.TimeAgoFormatted) %></span>
    <% If notice.TweetId > 0 Then %>
    <p class="mb-0"><a href="<%= H(Routes.UrlTo("Tweets", "Show", Array("id", notice.TweetId))) %>"><%= H(notice.TweetContent) %></a></p>
    <% End If %>
</article>
<% Loop %>
<!--#include file="../../Views/Shared/layout.footer.asp"-->
