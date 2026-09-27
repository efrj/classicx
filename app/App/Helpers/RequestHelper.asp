<%
Sub HttpError(status, message)
    DAL.Close
    Response.Status = status
    Response.ContentType = "text/plain"
    Response.Write message
    Response.End
End Sub

Function PositiveId(value)
    Dim s, rx : s = CStr(value)
    Set rx = New RegExp
    rx.Pattern = "^[0-9]{1,9}$"
    If Not rx.Test(s) Then HttpError "400 Bad Request", "Invalid identifier."
    PositiveId = CLng(s)
    If PositiveId < 1 Then HttpError "400 Bad Request", "Invalid identifier."
End Function

Function CsrfToken()
    If Len(CStr(Session("ClassicX_CSRF"))) = 0 Then
        Dim rs : Set rs = DAL.Query("SELECT HEX(RANDOM_BYTES(32)) AS token", Empty)
        Session("ClassicX_CSRF") = CStr(rs("token"))
        rs.Close
    End If
    CsrfToken = CStr(Session("ClassicX_CSRF"))
End Function

Sub RequireWrite()
    If UCase(Request.ServerVariables("REQUEST_METHOD")) <> "POST" Then
        Response.AddHeader "Allow", "POST"
        HttpError "405 Method Not Allowed", "Use POST for this action."
    End If
    If Len(CStr(Session("ClassicX_CSRF"))) = 0 Then HttpError "403 Forbidden", "Reload the page and try again."
    If CStr(Request.Form("csrf_token")) <> CStr(Session("ClassicX_CSRF")) Then HttpError "403 Forbidden", "Reload the page and try again."
End Sub

Sub RedirectHome()
    DAL.Close
    Response.Redirect Routes.UrlTo("Home", "Index", Empty)
    Response.End
End Sub

Sub JsonState(state)
    DAL.Close
    Response.ContentType = "application/json"
    Response.Write "{""active"":" & LCase(CStr(state)) & "}"
    Response.End
End Sub

' Serialize writes for one actor, including counters and notifications.
Sub BeginWrite()
    DAL.BeginTransaction
    Dim lockRow : Set lockRow = DAL.Query("SELECT id FROM users WHERE id = ? FOR UPDATE", Array(Auth.CurrentUserId))
    lockRow.Close
End Sub
%>
