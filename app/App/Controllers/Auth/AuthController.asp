<!--#include file="../../include_all.asp"-->
<%
Class AuthController
    Public Sub Login
    End Sub

    Public Sub LoginPost
        Call RequireWrite()
        Dim loginVal, passVal, user
        loginVal = Trim(Request.Form("login"))
        passVal = Request.Form("password")
        If Len(loginVal) = 0 Or Len(passVal) = 0 Then
            Flash.AddError "Please enter your username/email and password."
            Response.Redirect Routes.UrlTo("Auth", "Login", Empty)
            Response.End
        End If
        Set user = UserRepository.Authenticate(loginVal, passVal)
        If user Is Nothing Then
            Flash.AddError "Invalid username/email or password."
            Response.Redirect Routes.UrlTo("Auth", "Login", Empty)
            Response.End
        End If
        Auth.Login user.Id
        Flash.Success = "Welcome back, " & user.Name & "!"
        Call RedirectHome()
    End Sub

    Public Sub Register
    End Sub

    Public Sub RegisterPost
        Call RequireWrite()
        Dim nameVal, handleVal, emailVal, passVal, existingUser
        nameVal = Trim(Request.Form("name"))
        handleVal = Trim(Request.Form("handle"))
        emailVal = Trim(Request.Form("email"))
        passVal = Request.Form("password")

        If Left(handleVal, 1) = "@" Then handleVal = Mid(handleVal, 2)

        If Len(nameVal) < 1 Or Len(nameVal) > 50 Then
            Flash.AddError "Name must be between 1 and 50 characters."
        End If

        Dim rxHandle : Set rxHandle = New RegExp
        rxHandle.Pattern = "^[a-zA-Z0-9_]{3,20}$"
        If Not rxHandle.Test(handleVal) Then
            Flash.AddError "Handle must be 3 to 20 characters (letters, numbers, underscores only)."
        End If

        Dim rxEmail : Set rxEmail = New RegExp
        rxEmail.Pattern = "^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$"
        If Not rxEmail.Test(emailVal) Or Len(emailVal) > 100 Then
            Flash.AddError "Please provide a valid email address."
        End If

        If Len(passVal) < 6 Or Len(passVal) > 100 Then
            Flash.AddError "Password must be at least 6 characters."
        End If

        If Not Flash.HasErrors Then
            Set existingUser = UserRepository.FindByHandle(handleVal)
            If Not existingUser Is Nothing Then
                Flash.AddError "That handle is already taken."
            End If
            Set existingUser = UserRepository.FindByEmail(emailVal)
            If Not existingUser Is Nothing Then
                Flash.AddError "An account with that email already exists."
            End If
        End If

        If Flash.HasErrors Then
            Response.Redirect Routes.UrlTo("Auth", "Register", Empty)
            Response.End
        End If

        Dim newUser : Set newUser = UserRepository.Register(handleVal, handleVal, emailVal, passVal, nameVal)
        Auth.Login newUser.Id
        Flash.Success = "Your account has been created! Welcome to ClassicX."
        Call RedirectHome()
    End Sub

    Public Sub Forgot
    End Sub

    Public Sub ForgotPost
        Call RequireWrite()
        Dim loginVal, passVal, user
        loginVal = Trim(Request.Form("login"))
        passVal = Request.Form("password")

        If Left(loginVal, 1) = "@" Then loginVal = Mid(loginVal, 2)

        If Len(loginVal) = 0 Then
            Flash.AddError "Please enter your handle or email."
        End If
        If Len(passVal) < 6 Or Len(passVal) > 100 Then
            Flash.AddError "New password must be at least 6 characters."
        End If

        If Flash.HasErrors Then
            Response.Redirect Routes.UrlTo("Auth", "Forgot", Empty)
            Response.End
        End If

        Set user = UserRepository.FindByHandle(loginVal)
        If user Is Nothing Then Set user = UserRepository.FindByEmail(loginVal)

        If user Is Nothing Then
            Flash.AddError "No account found with that handle or email."
            Response.Redirect Routes.UrlTo("Auth", "Forgot", Empty)
            Response.End
        End If

        UserRepository.ResetPassword user.Id, passVal
        Flash.Success = "Password updated successfully. You can now sign in."
        Response.Redirect Routes.UrlTo("Auth", "Login", Empty)
        Response.End
    End Sub

    Public Sub SwitchAccount
        Call RequireWrite()
        Dim id, account : id = PositiveId(Request.Form("user_id"))
        Set account = UserRepository.FindById(id)
        If account Is Nothing Then Call HttpError("404 Not Found", "Demo account not found.")
        Auth.Login id
        Session("ClassicX_CSRF") = ""
        Call RedirectHome()
    End Sub

    Public Sub Logout
        Call RequireWrite()
        Auth.Logout
        Session("ClassicX_CSRF") = ""
        Call RedirectHome()
    End Sub
End Class

Dim Controller : Set Controller = New AuthController
Select Case LCase(MVC.ActionName)
    Case "login": Controller.Login
    Case "loginpost": Controller.LoginPost
    Case "register": Controller.Register
    Case "registerpost": Controller.RegisterPost
    Case "forgot": Controller.Forgot
    Case "forgotpost": Controller.ForgotPost
    Case "switchaccount": Controller.SwitchAccount
    Case "logout": Controller.Logout
    Case Else: Call HttpError("404 Not Found", "Action not found.")
End Select

If UCase(Request.ServerVariables("REQUEST_METHOD")) = "POST" Then Response.End
%>
<!--#include file="../../Views/Shared/layout.header.asp"-->
<% Select Case LCase(MVC.ActionName) %>
<% Case "login" %>
    <!--#include file="../../Views/Auth/Login.asp"-->
<% Case "register" %>
    <!--#include file="../../Views/Auth/Register.asp"-->
<% Case "forgot" %>
    <!--#include file="../../Views/Auth/Forgot.asp"-->
<% End Select %>
<!--#include file="../../Views/Shared/layout.footer.asp"-->
