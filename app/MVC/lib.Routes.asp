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
    
    Public Function UrlTo(ByVal controller_name, ByVal action_name, ByVal params_array)
        dim qs : qs = ""
        if IsArray(params_array) then
            dim idx, k, v
            for idx = lbound(params_array) to ubound(params_array) step 2
                k = params_array(idx)
                v = ""
                if idx + 1 <= ubound(params_array) then
                    v = Server.URLEncode(CStr(params_array(idx + 1)))
                end if
                qs = qs & k & "=" & v
                if not (idx >= ubound(params_array) - 1) then qs = qs & "&"
            next
        end if
        if len(qs) > 0 then qs = "&" & qs
        UrlTo = m_controllers_url & controller_name & "/" & controller_name & "Controller.asp?_A=" & action_name & qs
    End Function
end class


Dim Routes
Set Routes = New Route_Helper_Class
%>
