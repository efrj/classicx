<!--#include file="../../include_all.asp"-->
<%
RequireWrite
Select Case LCase(MVC.ActionName)
    Case "switchaccount"
        Dim id, account : id = PositiveId(Request.Form("user_id"))
        Set account = UserRepository.FindById(id)
        If account Is Nothing Then Call HttpError("404 Not Found", "Demo account not found.")
        Auth.Login id
    Case "logout"
        Auth.Logout
    Case Else: Call HttpError("404 Not Found", "Action not found.")
End Select
Session.Contents.Remove("ClassicX_CSRF")
RedirectHome
%>
