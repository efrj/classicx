<!--#include file="../../include_all.asp"-->

<%
Class HomeController
    Public Model

    Public Sub Index
        Set Model = New HomeViewModel_Class
        
        Dim tab : tab = Request("tab")
        If tab = "" Then tab = "for_you"
        Model.FeedType = tab

        Set Model.CurrentUser = Auth.CurrentUser
        Set Model.Tweets = TweetRepository.GetFeed(Auth.CurrentUserId, tab, 30)
    End Sub

    Public Sub Explore
        Set Model = New ExploreViewModel_Class
        
        Dim q : q = Trim(Request("q"))
        Model.Query = q

        If q = "" Then
            Set Model.Tweets = TweetRepository.GetFeed(Auth.CurrentUserId, "for_you", 20)
        Else
            Set Model.Tweets = TweetRepository.Search(q, Auth.CurrentUserId)
        End If
    End Sub
End Class

Dim Controller : Set Controller = New HomeController
Select Case LCase(MVC.ActionName)
    Case "index": Controller.Index
    Case "explore": Controller.Explore
    Case Else
        Response.Status = "404 Not Found"
        Response.Write "Action not found"
End Select
If LCase(MVC.ActionName) = "index" Or LCase(MVC.ActionName) = "explore" Then
Dim Model : Set Model = Controller.Model
%>

<!--#include file="../../Views/Shared/layout.header.asp"-->

<% If LCase(MVC.ActionName) = "index" Then %>
    <!--#include file="../../Views/Home/Index.asp"-->
<% ElseIf LCase(MVC.ActionName) = "explore" Then %>
    <!--#include file="../../Views/Home/Explore.asp"-->
<% End If %>

<!--#include file="../../Views/Shared/layout.footer.asp"-->

<% End If %>
<% DAL.Close %>
