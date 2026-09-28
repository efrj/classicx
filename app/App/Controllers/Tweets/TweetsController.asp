<!--#include file="../../include_all.asp"-->
<%
Class TweetsController
    Public Model
    Public Sub Bookmarks
        Set Model = New BookmarksViewModel_Class
        Set Model.Tweets = TweetRepository.GetBookmarks(Auth.CurrentUserId)
    End Sub
    Public Sub Show
        Set Model = New TweetDetailViewModel_Class
        Dim idRaw : idRaw = Request.QueryString("id")
        If InStr(idRaw, ",") > 0 Then idRaw = Trim(Split(idRaw, ",")(0))
        Dim id : id = PositiveId(idRaw)
        Set Model.Tweet = TweetRepository.FindById(id, Auth.CurrentUserId)
        If Model.Tweet Is Nothing Then Call HttpError("404 Not Found", "Post not found.")
        Set Model.Replies = TweetRepository.GetReplies(id, Auth.CurrentUserId)
    End Sub
    Public Sub CreatePost
        Call RequireWrite()
        Dim body, media, parent, target, created
        body = Trim(Request.Form("content"))
        media = Trim(Request.Form("image_url"))
        If Len(body) = 0 Or Len(body) > 280 Then Call HttpError("400 Bad Request", "Posts must contain 1 to 280 characters.")
        If Len(media) > 255 Then Call HttpError("400 Bad Request", "Image URL is too long.")
        If media <> "" Then
            If LCase(Left(media, 8)) <> "https://" And LCase(Left(media, 7)) <> "http://" Then Call HttpError("400 Bad Request", "Use an HTTP or HTTPS image URL.")
        End If
        parent = 0
        If Request.Form("parent_id") <> "" Then parent = PositiveId(Request.Form("parent_id"))
        Call BeginWrite()
        If parent > 0 Then
            Set target = DAL.Query("SELECT id FROM tweets WHERE id = ? FOR UPDATE", Array(parent))
            If target.EOF Then
                target.Close
                DAL.RollbackTransaction
                Call HttpError("404 Not Found", "Parent post not found.")
            End If
            target.Close
        End If
        Set created = TweetRepository.CreateTweet(Auth.CurrentUserId, body, media, parent, 0)
        DAL.CommitTransaction
        Dim url : url = Routes.UrlTo("Tweets", "Show", Array("id", created.Id))
        DAL.Close
        Response.Redirect url
        Response.End
    End Sub
    Public Sub DeletePost
        Call RequireWrite()
        Dim id, target, parent : id = PositiveId(Request.Form("id"))
        Call BeginWrite()
        Set target = DAL.Query("SELECT user_id, parent_id FROM tweets WHERE id = ? FOR UPDATE", Array(id))
        If target.EOF Then
            target.Close
            DAL.RollbackTransaction
            Call HttpError("404 Not Found", "Post not found.")
        End If
        If CLng(target("user_id")) <> Auth.CurrentUserId Then
            target.Close
            DAL.RollbackTransaction
            Call HttpError("403 Forbidden", "You can only delete your own posts.")
        End If
        parent = SafeLng(target("parent_id"))
        target.Close
        TweetRepository.DeleteTweet id, Auth.CurrentUserId
        If parent > 0 Then DAL.Exec "UPDATE tweets SET replies_count = GREATEST(0, replies_count - 1) WHERE id = ?", Array(parent)
        ' Keep other users' replies accessible as standalone posts.
        DAL.Exec "UPDATE tweets SET parent_id = NULL WHERE parent_id = ?", Array(id)
        DAL.CommitTransaction
        Call RedirectHome()
    End Sub
    Public Sub Toggle(action)
        Call RequireWrite()
        Dim id, target, state : id = PositiveId(Request.Form("tweet_id"))
        Call BeginWrite()
        Set target = DAL.Query("SELECT id FROM tweets WHERE id = ? FOR UPDATE", Array(id))
        If target.EOF Then
            target.Close
            DAL.RollbackTransaction
            Call HttpError("404 Not Found", "Post not found.")
        End If
        target.Close
        Select Case action
            Case "likepost": state = TweetRepository.ToggleLike(Auth.CurrentUserId, id)
            Case "retweetpost": state = TweetRepository.ToggleRetweet(Auth.CurrentUserId, id)
            Case "bookmarkpost": state = TweetRepository.ToggleBookmark(Auth.CurrentUserId, id)
        End Select
        DAL.CommitTransaction
        Call JsonState(state)
    End Sub
End Class
Dim Controller : Set Controller = New TweetsController
Select Case LCase(MVC.ActionName)
    Case "bookmarks": Controller.Bookmarks
    Case "show": Controller.Show
    Case "createpost": Controller.CreatePost
    Case "deletepost": Controller.DeletePost
    Case "likepost", "retweetpost", "bookmarkpost": Controller.Toggle LCase(MVC.ActionName)
    Case Else: Call HttpError("404 Not Found", "Action not found.")
End Select
If UCase(Request.ServerVariables("REQUEST_METHOD")) = "POST" Then Response.End
Dim Model : Set Model = Controller.Model
%>
<!--#include file="../../Views/Shared/layout.header.asp"-->
<% If LCase(MVC.ActionName) = "bookmarks" Then %>
<header class="x-header-sticky p-3"><h1 class="h5 fw-bold mb-0">Bookmarks</h1></header>
<!--#include file="../../Views/Shared/_Feed.asp"-->
<% Else %>
<!--#include file="../../Views/Tweets/Show.asp"-->
<% End If %>
<!--#include file="../../Views/Shared/layout.footer.asp"-->
