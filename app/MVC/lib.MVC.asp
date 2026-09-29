<%
Response.ExpiresAbsolute = "2000-01-01" 
Response.AddHeader "pragma", "no-cache" 
Response.AddHeader "cache-control", "private, no-cache, must-revalidate"


'=======================================================================================================================
' MVC Dispatcher
'=======================================================================================================================
Class MVC_Dispatcher_Class
    Private m_controller_name
    Private m_action_name
    Private m_default_action_name
    Private m_action_params
    Private m_controller_instance
    Private m_is_partial
    
    Private Sub Class_initialize
        m_default_action_name = "Index"
    End Sub
    
    Public Property Get ControllerName
        If m_controller_name = "" Then SetControllerActionNames
        ControllerName = m_controller_name
    End Property
    
    Public Property Get ActionName
        If m_action_name = "" Then SetControllerActionNames
        ActionName = m_action_name
    End Property
    
    Public Property Get IsPartial
        IsPartial = m_is_partial
    End Property
    
    '---------------------------------------------------------------------------------------------------------------------
    ' Instantiates the controller and executes the requested action on the controller.
    Public Sub Dispatch
        Err.Raise 5, "MVC", "Instantiate controllers explicitly and dispatch allowed actions with Select Case."
    End Sub

    '---------------------------------------------------------------------------------------------------------------------
    ' Ensures an action request comes in via HTTP POST only. Raises error if not.
    Public Sub RequirePost
        If UCase(Request.ServerVariables("REQUEST_METHOD")) <> "POST" Then Err.Raise 1, "MVC_Helper_Class:RequirePost", "Action only responds to POST requests."
    End Sub
    
    '---------------------------------------------------------------------------------------------------------------------
    Public Sub RedirectTo(controller_name, action_name)
        RedirectToExt controller_name, action_name, empty
    End Sub
    
    ' Redirects the browser to the specified action on the specified controller with the specified querystring parameters.
    ' params is a KVArray of querystring parameters.
    Public Sub RedirectToExt(controller_name, action_name, params)
        Response.Redirect Routes.UrlTo(controller_name, action_name, params)
        Response.End
    End Sub
    
    ' Shortcut for RedirectToActionExt that does not require passing a parameters argument.
    Public Sub RedirectToAction(ByVal action_name)
        RedirectToActionExt action_name, empty
    End Sub
    
    ' Redirects the browser to the specified action in the current controller, passing the included parameters. 
    ' params is a KVArray of querystring parameters.
    Public Sub RedirectToActionExt(ByVal action_name, ByVal params)
        RedirectToExt ControllerName, action_name, params
    End Sub
    
    ' Redirects to the specified action using a form POST.
    Public Sub RedirectToActionPOST(action_name)
        RedirectToActionExtPOST action_name, empty
    End Sub
    
    ' Redirects to the specified action name on the current controller using a form post
    Public Sub RedirectToActionExtPOST(action_name, params)
        echo "<form id='mvc_redirect_to_action_post' action='" & Routes.UrlTo(ControllerName, action_name, empty) & "' method='POST'>"
            echo "<input type='hidden' name='mvc_redirect_to_action_post_flag' value='1'>"
            if Not IsEmpty(params) then
                dim i, key, val
                for i = 0 to ubound(params) step 2
                    KeyVal params, i, key, val
                    echo "<input type='hidden' name='" & key & "' value='" & val & "'>"
                next
            end if
        echo "</form>"
        echo "<script type='text/javascript'>"
            echo "$('#mvc_redirect_to_action_post').submit();"
        echo "</script>"
    End Sub
     
    
    '---------------------------------------------------------------------------------------------------------------------
    ' PRIVATE 
    '---------------------------------------------------------------------------------------------------------------------
    Private Sub SetControllerActionNames
        dim full_path : full_path = request.servervariables("path_info")
        dim parts : parts = split(full_path, Routes.ControllersUrl, -1, 1)
        if ubound(parts) >= 1 then
            dim part_path_split : part_path_split = split(parts(1), "/")
            m_controller_name = part_path_split(0)
        else
            m_controller_name = "Home"
        end if
        Dim reqAction : reqAction = CStr(request.QueryString("_A"))
        If InStr(reqAction, ",") > 0 Then reqAction = Trim(Split(reqAction, ",")(0))
        If reqAction <> "" Then
            m_action_name = reqAction
        Else
            Dim rawQs : rawQs = CStr(Request.ServerVariables("QUERY_STRING"))
            If InStr(rawQs, "_A=") > 0 Then
                Dim qsParts, qp, kv
                qsParts = Split(rawQs, "&")
                For Each qp In qsParts
                    kv = Split(qp, "=")
                    If UBound(kv) >= 1 Then
                        If LCase(kv(0)) = "_a" Then
                            m_action_name = kv(1)
                            Exit Sub
                        End If
                    End If
                Next
            End If
            m_action_name = m_default_action_name
        End If
    End Sub
    
    ' This is deprecated to avoid creating a Dictionary object with every request.
    ' Hasn't been used in forever anyway.
    'Private Sub SetActionParams
    '    dim key, val
    '    'set m_action_params = Server.CreateObject("scripting.dictionary")
    '    for each key in request.querystring
    '        val = request.querystring(key)
    '        'ignore service keys
    '        if instr(1, "_A", key, 1) = 0 then
    '            ActionParams.add key, CStr(val)
    '        end if
    '    next
    'End Sub
    
end Class



Dim MVC
Set MVC = New MVC_Dispatcher_Class
%>
