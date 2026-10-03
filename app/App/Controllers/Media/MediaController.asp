<% Response.Buffer = True %>
<!--#include file="../../Helpers/AppConfig.asp"-->
<%
' Relative /uploads/file requests land here. The browser is sent to RustFS.
' The public base comes from CLASSICX_RUSTFS_PUBLIC_URL. The file name is
' restricted so this redirect cannot be pointed at another site.
Response.Clear
Dim fileName
fileName = CStr(Request.QueryString("file"))
If InStr(fileName, ",") > 0 Then fileName = Trim(Split(fileName, ",")(0))

If Not AppConfig.IsSafeObjectName(fileName) Then
    Response.Status = "404 Not Found"
    Response.ContentType = "text/plain"
    Response.Write "Not found."
    Response.End
End If

Response.Redirect AppConfig.PublicObjectUrl(fileName)
%>
