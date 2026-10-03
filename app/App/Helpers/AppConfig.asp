<%
'=======================================================================================================================
' ClassicX runtime configuration.
' Reads the process environment injected by Docker Compose from infra/.env.
' Missing or blank variables keep the local Docker defaults.
' VBScript Environ() is empty in AxonASP; WScript.Shell PROCESS environment works.
'=======================================================================================================================
Class AppConfig_Class
    Private m_env

    Private Sub Class_Initialize()
        On Error Resume Next
        Dim shell
        Set shell = Server.CreateObject("WScript.Shell")
        If Err.Number = 0 Then Set m_env = shell.Environment("PROCESS")
        Err.Clear
        On Error Goto 0
    End Sub

    Private Function EnvOr(ByVal name, ByVal fallback)
        Dim raw
        raw = ""
        On Error Resume Next
        If IsObject(m_env) Then
            If Not m_env Is Nothing Then raw = m_env(name)
        End If
        If Err.Number <> 0 Then raw = ""
        Err.Clear
        On Error Goto 0
        If IsNull(raw) Or IsEmpty(raw) Then
            EnvOr = fallback
        ElseIf Trim(CStr(raw)) = "" Then
            EnvOr = fallback
        Else
            EnvOr = Trim(CStr(raw))
        End If
    End Function

    Private Function HasBreak(ByVal rawValue)
        HasBreak = (InStr(rawValue, ";") > 0 Or InStr(rawValue, vbCr) > 0 Or InStr(rawValue, vbLf) > 0)
    End Function

    ' ODBC splits the connection string on ';'. A value with that character falls back.
    ' Characters that would split a key are wrapped in ODBC braces.
    Private Function OdbcValue(ByVal rawValue, ByVal fallback)
        Dim s
        s = Trim(CStr(rawValue))
        If s = "" Or HasBreak(s) Then s = fallback
        If HasBreak(s) Then s = fallback
        If InStr(s, "=") > 0 Or InStr(s, " ") > 0 Or InStr(s, "{") > 0 Or InStr(s, "}") > 0 Then
            OdbcValue = "{" & Replace(s, "}", "}}") & "}"
        Else
            OdbcValue = s
        End If
    End Function

    Private Function IsSafeToken(ByVal name, ByVal maxLen)
        Dim i, ch
        name = CStr(name)
        If Len(name) < 1 Or Len(name) > maxLen Then
            IsSafeToken = False
            Exit Function
        End If
        If InStr(name, "..") > 0 Then
            IsSafeToken = False
            Exit Function
        End If
        For i = 1 To Len(name)
            ch = Mid(name, i, 1)
            If Not ( _
                (ch >= "a" And ch <= "z") Or _
                (ch >= "A" And ch <= "Z") Or _
                (ch >= "0" And ch <= "9") Or _
                ch = "." Or ch = "_" Or ch = "-" _
            ) Then
                IsSafeToken = False
                Exit Function
            End If
        Next
        IsSafeToken = True
    End Function

    Private Function ValidHttpUrl(ByVal rawValue)
        Dim s, head
        s = Trim(CStr(rawValue))
        Do While Len(s) > 0 And Right(s, 1) = "/"
            s = Left(s, Len(s) - 1)
        Loop
        If Len(s) < 8 Or Len(s) > 180 Then
            ValidHttpUrl = ""
            Exit Function
        End If
        If InStr(s, " ") > 0 Or InStr(s, vbCr) > 0 Or InStr(s, vbLf) > 0 Or InStr(s, "\") > 0 Or InStr(s, ";") > 0 Then
            ValidHttpUrl = ""
            Exit Function
        End If
        head = LCase(Left(s, 8))
        If head <> "https://" And LCase(Left(s, 7)) <> "http://" Then
            ValidHttpUrl = ""
            Exit Function
        End If
        ValidHttpUrl = s
    End Function

    Public Property Get DbHost
        DbHost = OdbcValue(EnvOr("CLASSICX_DB_HOST", "db"), "db")
    End Property

    Public Property Get DbPort
        Dim s, i, ch, ok
        s = EnvOr("CLASSICX_DB_PORT", "3306")
        ok = (Len(s) > 0 And Len(s) <= 5)
        If ok Then
            For i = 1 To Len(s)
                ch = Mid(s, i, 1)
                If ch < "0" Or ch > "9" Then ok = False
            Next
        End If
        If ok Then
            DbPort = s
        Else
            DbPort = "3306"
        End If
    End Property

    Public Property Get DbName
        DbName = OdbcValue(EnvOr("CLASSICX_DB_NAME", "bd_classicx"), "bd_classicx")
    End Property

    Public Property Get DbUser
        DbUser = OdbcValue(EnvOr("CLASSICX_DB_USER", "classicx"), "classicx")
    End Property

    Private Property Get DbPassword
        DbPassword = OdbcValue(EnvOr("CLASSICX_DB_PASSWORD", "classicx"), "classicx")
    End Property

    Public Property Get ConnectionString
        ConnectionString = "DRIVER={MySQL ODBC 3.51 Driver};OPTION=3;" & _
            "DATABASE=" & DbName & ";" & _
            "PWD=" & DbPassword & ";" & _
            "SERVER=" & DbHost & ";" & _
            "UID=" & DbUser & ";" & _
            "PORT=" & DbPort
    End Property

    Public Property Get RustfsInternalUrl
        Dim configured
        configured = ValidHttpUrl(EnvOr("CLASSICX_RUSTFS_INTERNAL_URL", "http://rustfs:9000"))
        If configured = "" Then configured = "http://rustfs:9000"
        RustfsInternalUrl = configured
    End Property

    Public Property Get RustfsPublicUrl
        Dim configured
        configured = ValidHttpUrl(EnvOr("CLASSICX_RUSTFS_PUBLIC_URL", "http://localhost:9000"))
        If configured = "" Then configured = "http://localhost:9000"
        RustfsPublicUrl = configured
    End Property

    Public Property Get RustfsBucket
        Dim configured
        configured = EnvOr("CLASSICX_RUSTFS_BUCKET", "uploads")
        If Not IsSafeToken(configured, 63) Then configured = "uploads"
        RustfsBucket = configured
    End Property

    Public Function IsSafeObjectName(ByVal name)
        IsSafeObjectName = IsSafeToken(name, 180)
    End Function

    Public Function PublicObjectUrl(ByVal fileName)
        PublicObjectUrl = RustfsPublicUrl & "/" & RustfsBucket & "/" & fileName
    End Function
End Class

Dim AppConfig : Set AppConfig = New AppConfig_Class
%>
