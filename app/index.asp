<%
Dim qs : qs = Request.QueryString
If qs <> "" Then
    Response.Redirect "/home?" & qs
Else
    Response.Redirect "/home"
End If
%>
