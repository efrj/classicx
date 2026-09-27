<!--#include file="../../include_all.asp"-->
<%
Class UsersController
    Public Model
    Public Sub Profile
        Set Model = New ProfileViewModel_Class
        Set Model.ProfileUser = UserRepository.FindByHandle(CStr(Request.QueryString("handle")))
        If Model.ProfileUser Is Nothing Then Call HttpError("404 Not Found", "User not found.")
        Model.ActiveTab = LCase(Request.QueryString("tab"))
        If Model.ActiveTab <> "replies" And Model.ActiveTab <> "likes" Then Model.ActiveTab = "posts"
        Set Model.Tweets = TweetRepository.GetUserTweets(Model.ProfileUser.Id, Auth.CurrentUserId, Model.ActiveTab)
    End Sub
    Public Sub Follow(state)
        Call RequireWrite()
        Dim id, target : id = PositiveId(Request.Form("user_id"))
        If id = Auth.CurrentUserId Then Call HttpError("400 Bad Request", "You cannot follow yourself.")
        Set target = UserRepository.FindById(id)
        If target Is Nothing Then Call HttpError("404 Not Found", "User not found.")
        Call BeginWrite()
        If state Then
            UserRepository.Follow Auth.CurrentUserId, id
        Else
            UserRepository.Unfollow Auth.CurrentUserId, id
        End If
        DAL.CommitTransaction
        Call JsonState(state)
    End Sub
End Class
Dim Controller : Set Controller = New UsersController
Select Case LCase(MVC.ActionName)
    Case "profile": Controller.Profile
    Case "followpost": Controller.Follow True
    Case "unfollowpost": Controller.Follow False
    Case Else: Call HttpError("404 Not Found", "Action not found.")
End Select
If UCase(Request.ServerVariables("REQUEST_METHOD")) = "POST" Then Response.End
Dim Model : Set Model = Controller.Model
%>
<!--#include file="../../Views/Shared/layout.header.asp"-->
<!--#include file="../../Views/Users/Profile.asp"-->
<!--#include file="../../Views/Shared/layout.footer.asp"-->
