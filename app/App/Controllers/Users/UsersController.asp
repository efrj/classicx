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

    Public Sub Followers
        Set Model = New UserListViewModel_Class
        Set Model.ProfileUser = UserRepository.FindByHandle(CStr(Request.QueryString("handle")))
        If Model.ProfileUser Is Nothing Then Call HttpError("404 Not Found", "User not found.")
        Model.ListType = "followers"
        Set Model.Users = UserRepository.GetFollowers(Model.ProfileUser.Id, Auth.CurrentUserId)
    End Sub

    Public Sub Following
        Set Model = New UserListViewModel_Class
        Set Model.ProfileUser = UserRepository.FindByHandle(CStr(Request.QueryString("handle")))
        If Model.ProfileUser Is Nothing Then Call HttpError("404 Not Found", "User not found.")
        Model.ListType = "following"
        Set Model.Users = UserRepository.GetFollowing(Model.ProfileUser.Id, Auth.CurrentUserId)
    End Sub

    Public Sub UpdateProfilePost
        Call RequireWrite()
        Dim nameVal, bioVal, locVal, webVal, avatarVal, bannerVal
        nameVal = Trim(Request.Form("name"))
        bioVal = Trim(Request.Form("bio"))
        locVal = Trim(Request.Form("location"))
        webVal = Trim(Request.Form("website"))
        avatarVal = Trim(Request.Form("avatar_url"))
        bannerVal = Trim(Request.Form("banner_url"))

        If Len(nameVal) = 0 Then
            Flash.AddError "Name cannot be empty."
        ElseIf Len(nameVal) > 50 Then
            Flash.AddError "Name cannot exceed 50 characters."
        End If

        If Len(bioVal) > 160 Then
            Flash.AddError "Bio cannot exceed 160 characters."
        End If

        If Len(locVal) > 30 Then
            Flash.AddError "Location cannot exceed 30 characters."
        End If

        If Len(webVal) > 100 Then
            Flash.AddError "Website URL cannot exceed 100 characters."
        End If

        If Len(avatarVal) > 255 Then
            Flash.AddError "Avatar URL cannot exceed 255 characters."
        End If

        If Len(bannerVal) > 255 Then
            Flash.AddError "Banner URL cannot exceed 255 characters."
        End If

        Dim currentUser : Set currentUser = UserRepository.FindById(Auth.CurrentUserId)
        If currentUser Is Nothing Then Call HttpError("403 Forbidden", "Not authenticated.")

        If Flash.HasErrors Then
            Response.Redirect Routes.UrlTo("Users", "Profile", Array("handle", currentUser.Handle))
            Response.End
        End If

        UserRepository.UpdateProfile Auth.CurrentUserId, nameVal, bioVal, locVal, webVal, avatarVal, bannerVal
        Flash.Success = "Your profile has been updated."
        Response.Redirect Routes.UrlTo("Users", "Profile", Array("handle", currentUser.Handle))
        Response.End
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
    Case "followers": Controller.Followers
    Case "following": Controller.Following
    Case "updateprofilepost": Controller.UpdateProfilePost
    Case "followpost": Controller.Follow True
    Case "unfollowpost": Controller.Follow False
    Case Else: Call HttpError("404 Not Found", "Action not found.")
End Select

If UCase(Request.ServerVariables("REQUEST_METHOD")) = "POST" Then Response.End
Dim Model : Set Model = Controller.Model
%>
<!--#include file="../../Views/Shared/layout.header.asp"-->
<% Select Case LCase(MVC.ActionName) %>
<% Case "profile" %>
    <!--#include file="../../Views/Users/Profile.asp"-->
<% Case "followers", "following" %>
    <!--#include file="../../Views/Users/UserList.asp"-->
<% End Select %>
<!--#include file="../../Views/Shared/layout.footer.asp"-->
