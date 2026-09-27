<%
'=======================================================================================================================
' ClassicX Auth & Utility Helper
'=======================================================================================================================

Class AuthHelper_Class
    Private m_current_user

    Public Property Get CurrentUserId
        If IsEmpty(Session("ClassicX_UserId")) Or Session("ClassicX_UserId") = "" Then
            ' Default to user 1 (classicx) for seamless exploring/demo experience
            Session("ClassicX_UserId") = 1
        End If
        CurrentUserId = CLng(Session("ClassicX_UserId"))
    End Property

    Public Property Let CurrentUserId(val)
        Session("ClassicX_UserId") = val
        Set m_current_user = Nothing
    End Property

    Public Property Get IsLoggedIn
        IsLoggedIn = (Not IsEmpty(Session("ClassicX_UserId"))) And (Session("ClassicX_UserId") <> "")
    End Property

    Public Function CurrentUser
        Dim need_fetch : need_fetch = False
        If Not IsObject(m_current_user) Then
            need_fetch = True
        ElseIf m_current_user Is Nothing Then
            need_fetch = True
        End If
        If need_fetch Then
            Set m_current_user = UserRepository.FindById(CurrentUserId)
        End If
        Set CurrentUser = m_current_user
    End Function

    Public Sub Login(user_id)
        Session("ClassicX_UserId") = user_id
        Set m_current_user = Nothing
    End Sub

    Public Sub Logout
        Session.Contents.Remove("ClassicX_UserId")
        Set m_current_user = Nothing
    End Sub

    ' Format datetime to Twitter-like friendly time (e.g. 5m, 2h, Sep 26)
    Public Function FormatTimeAgo(raw_val)
        Dim dt_val : dt_val = SafeStr(raw_val)
        If dt_val = "" Then
            FormatTimeAgo = ""
            Exit Function
        End If

        On Error Resume Next
        Dim postDate, nowSec, diffSec
        postDate = CDate(dt_val)
        If Err.Number <> 0 Then
            FormatTimeAgo = dt_val
            Err.Clear
            Exit Function
        End If


        On Error GoTo 0
        diffSec = DateDiff("s", postDate, Now())
        If diffSec < 0 Then diffSec = 0

        If diffSec < 60 Then
            FormatTimeAgo = diffSec & "s"
        ElseIf diffSec < 3600 Then
            FormatTimeAgo = Int(diffSec / 60) & "m"
        ElseIf diffSec < 86400 Then
            FormatTimeAgo = Int(diffSec / 3600) & "h"
        ElseIf diffSec < 604800 Then
            FormatTimeAgo = Int(diffSec / 86400) & "d"
        Else
            FormatTimeAgo = MonthName(Month(postDate), True) & " " & Day(postDate)
        End If
    End Function

    ' Transform plain text into Twitter-like links for @mentions and #hashtags
    Public Function FormatTweetText(raw_text)
        Dim raw, rx, matches, hit, offset, out, token, url, position
        raw = SafeStr(raw_text)
        Set rx = New RegExp
        rx.Global = True
        rx.Pattern = "[@#][a-zA-Z0-9_]+"
        Set matches = rx.Execute(raw)
        offset = 1
        out = ""
        For Each hit In matches
            position = InStr(offset, raw, hit.Value, 0)
            out = out & H(Mid(raw, offset, position - offset))
            token = Mid(hit.Value, 2)
            If Left(hit.Value, 1) = "@" Then
                url = Routes.UrlTo("Users", "Profile", Array("handle", token))
            Else
                url = Routes.UrlTo("Home", "Explore", Array("q", hit.Value))
            End If
            out = out & "<a href=""" & H(url) & """>" & H(hit.Value) & "</a>"
            offset = position + Len(hit.Value)
        Next
        out = out & H(Mid(raw, offset))
        out = Replace(out, vbCrLf, vbLf)
        out = Replace(out, vbCr, vbLf)
        FormatTweetText = Replace(out, vbLf, "<br>")
    End Function

End Class

Dim Auth
Set Auth = New AuthHelper_Class
%>
