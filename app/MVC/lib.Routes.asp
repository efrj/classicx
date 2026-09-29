<%
'=======================================================================================================================
' ROUTING HELPER
'=======================================================================================================================
Class Route_Helper_Class
    Private m_app_url
    Private m_content_url
    Private m_stylesheets_url
    Private m_controllers_url

    Public Property Get NoCacheToken
        NoCacheToken = Timer() * 100
    End Property

    Private Sub Class_Initialize
        m_app_url         = "/App/"
        m_content_url     = "/Content/"
        m_stylesheets_url = "/Content/css/"
        m_controllers_url = "/App/Controllers/"
    End Sub

    Public Sub Initialize(app_url)
        m_app_url         = app_url
        m_content_url     = "/Content/"
        m_stylesheets_url = m_content_url & "css/"
        m_controllers_url = m_app_url & "Controllers/"
    End Sub
    
    Public Property Get AppUrl
        AppUrl = m_app_url
    End Property
    
    Public Property Get ContentUrl
        ContentUrl = m_content_url
    End Property
    
    Public Property Get ControllersUrl
        ControllersUrl = m_controllers_url
    End Property
    
    Public Property Get StylesheetsUrl
        StylesheetsUrl = m_stylesheets_url
    End Property

    Private Function GetParam(params_array, ByVal key_name)
        GetParam = ""
        If IsArray(params_array) Then
            Dim i
            For i = LBound(params_array) To UBound(params_array) Step 2
                If LCase(params_array(i)) = LCase(key_name) Then
                    If i + 1 <= UBound(params_array) Then
                        GetParam = CStr(params_array(i + 1))
                    End If
                    Exit Function
                End If
            Next
        End If
    End Function

    Private Function BuildQueryString(params_array, exclude_keys_array)
        Dim qs : qs = ""
        If IsArray(params_array) Then
            Dim i, k, v, exclude, ex
            For i = LBound(params_array) To UBound(params_array) Step 2
                k = params_array(i)
                exclude = False
                If IsArray(exclude_keys_array) Then
                    For Each ex In exclude_keys_array
                        If LCase(k) = LCase(ex) Then
                            exclude = True
                            Exit For
                        End If
                    Next
                End If
                If Not exclude Then
                    v = ""
                    If i + 1 <= UBound(params_array) Then
                        v = Server.URLEncode("" & params_array(i + 1))
                    End If
                    If qs <> "" Then qs = qs & "&"
                    qs = qs & k & "=" & v
                End If
            Next
        End If
        If qs <> "" Then qs = "?" & qs
        BuildQueryString = qs
    End Function
    
    Public Function UrlTo(ByVal controller_name, ByVal action_name, params_array)
        Dim c : c = LCase(controller_name)
        Dim a : a = LCase(action_name)
        Dim handleVal, idVal, tabVal, qs

        Select Case c
            Case "home"
                Select Case a
                    Case "index"
                        qs = BuildQueryString(params_array, Empty)
                        UrlTo = "/home" & qs
                        Exit Function
                    Case "explore"
                        qs = BuildQueryString(params_array, Empty)
                        UrlTo = "/explore" & qs
                        Exit Function
                End Select

            Case "auth"
                Select Case a
                    Case "login":         UrlTo = "/login": Exit Function
                    Case "loginpost":     UrlTo = "/login/post": Exit Function
                    Case "register":      UrlTo = "/register": Exit Function
                    Case "registerpost":  UrlTo = "/register/post": Exit Function
                    Case "forgot":        UrlTo = "/forgot": Exit Function
                    Case "forgotpost":    UrlTo = "/forgot/post": Exit Function
                    Case "logout":        UrlTo = "/logout": Exit Function
                    Case "switchaccount": UrlTo = "/switch-account": Exit Function
                End Select

            Case "notifications"
                Select Case a
                    Case "index":    UrlTo = "/notifications": Exit Function
                    Case "readpost": UrlTo = "/notifications/read": Exit Function
                End Select

            Case "tweets"
                Select Case a
                    Case "bookmarks":    UrlTo = "/bookmarks": Exit Function
                    Case "createpost":   UrlTo = "/tweets/create": Exit Function
                    Case "deletepost":   UrlTo = "/tweets/delete": Exit Function
                    Case "likepost":     UrlTo = "/tweets/like": Exit Function
                    Case "retweetpost":  UrlTo = "/tweets/retweet": Exit Function
                    Case "bookmarkpost": UrlTo = "/tweets/bookmark": Exit Function
                    Case "show"
                        idVal = GetParam(params_array, "id")
                        If idVal <> "" Then
                            handleVal = GetParam(params_array, "handle")
                            If Left(handleVal, 1) = "@" Then handleVal = Mid(handleVal, 2)
                            qs = BuildQueryString(params_array, Array("id", "handle"))
                            If handleVal <> "" Then
                                UrlTo = "/" & handleVal & "/status/" & Server.URLEncode(idVal) & qs
                            Else
                                UrlTo = "/status/" & Server.URLEncode(idVal) & qs
                            End If
                            Exit Function
                        End If
                End Select

            Case "users"
                handleVal = GetParam(params_array, "handle")
                If Left(handleVal, 1) = "@" Then handleVal = Mid(handleVal, 2)
                Select Case a
                    Case "profile"
                        If handleVal <> "" Then
                            tabVal = GetParam(params_array, "tab")
                            If tabVal <> "" And LCase(tabVal) <> "posts" Then
                                qs = BuildQueryString(params_array, Array("handle"))
                                UrlTo = "/@" & handleVal & qs
                            Else
                                qs = BuildQueryString(params_array, Array("handle", "tab"))
                                UrlTo = "/@" & handleVal & qs
                            End If
                            Exit Function
                        End If
                    Case "followers"
                        If handleVal <> "" Then
                            qs = BuildQueryString(params_array, Array("handle"))
                            UrlTo = "/@" & handleVal & "/followers" & qs
                            Exit Function
                        End If
                    Case "following"
                        If handleVal <> "" Then
                            qs = BuildQueryString(params_array, Array("handle"))
                            UrlTo = "/@" & handleVal & "/following" & qs
                            Exit Function
                        End If
                    Case "followpost":        UrlTo = "/users/follow": Exit Function
                    Case "unfollowpost":      UrlTo = "/users/unfollow": Exit Function
                    Case "updateprofilepost": UrlTo = "/users/update-profile": Exit Function
                End Select
        End Select

        ' Fallback to standard URL
        Dim fallback_qs : fallback_qs = ""
        If IsArray(params_array) Then
            Dim idx, k, v
            For idx = LBound(params_array) To UBound(params_array) Step 2
                k = params_array(idx)
                v = ""
                If idx + 1 <= UBound(params_array) Then
                    v = Server.URLEncode(CStr(params_array(idx + 1)))
                End If
                fallback_qs = fallback_qs & k & "=" & v
                If Not (idx >= UBound(params_array) - 1) Then fallback_qs = fallback_qs & "&"
            Next
        End If
        If Len(fallback_qs) > 0 Then fallback_qs = "&" & fallback_qs
        UrlTo = m_controllers_url & controller_name & "/" & controller_name & "Controller.asp?_A=" & action_name & fallback_qs
    End Function
End Class

Dim Routes
Set Routes = New Route_Helper_Class
%>
