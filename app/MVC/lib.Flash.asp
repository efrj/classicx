<%
'=======================================================================================================================
' Flash Message Class
'=======================================================================================================================
Class Flash_Class
    Private m_errors_key
    Private m_success_key

    Private Sub Class_Initialize
        m_errors_key  = "mvc.flash.errors_array"
        m_success_key = "mvc.flash.success_message"
    End Sub
    
    'helper methods to avoid if..then statements in views
    Public Sub ShowErrorsIfPresent
        if HasErrors then ShowErrors
    End Sub
    
    Public Sub ShowSuccessIfPresent
        if HasSuccess then ShowSuccess
    End Sub

    '---------------------------------------------------------------------------------------------------------------------
    ' Errors
    '---------------------------------------------------------------------------------------------------------------------
    Public Property Get HasErrors
        HasErrors = (Not IsEmpty(Session(m_errors_key)))
    End Property

    Public Property Get Errors
        Errors = Session(m_errors_key)
    End Property
    
    Public Property Let Errors(ary)
        Session(m_errors_key) = ary
    End Property
    
    Public Sub AddError(msg)
        dim ary
        if IsEmpty(Session(m_errors_key)) then
            ary = Array()
            redim ary(-1)
        else
            ary = Session(m_errors_key)
        end if
        redim preserve ary(ubound(ary) + 1)
        ary(ubound(ary)) = msg
        Session(m_errors_key) = ary
    End Sub
    
    'Public Sub ShowErrors
    '    ClearErrors
    'End Sub
    
    Public Sub ShowErrors
        if HasErrors then 
            %>
                <div class="alert alert-danger alert-dismissible fade show my-2" role="alert">
                    <strong>Notice:</strong>
                    <ul class="mb-0 ps-3">
                        <%
                            dim ary, i
                            ary = Errors
                            for i = 0 to ubound(ary)
                                Response.Write "<li>" & H(ary(i)) & "</li>"
                            next
                        %>
                    </ul>
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            <%
            ClearErrors
        end if
    End Sub
    
    Public Sub ClearErrors
        Session.Contents.Remove(m_errors_key)
    End Sub
    
    '---------------------------------------------------------------------------------------------------------------------
    ' Success
    '---------------------------------------------------------------------------------------------------------------------
    Public Property Get HasSuccess
        HasSuccess = (Not IsEmpty(Session(m_success_key)))
    End Property
    
    Public Property Get Success
        Success = Session(m_success_key)
    End Property
    
    Public Property Let Success(msg)
        Session(m_success_key) = msg
    End Property
    
    Public Sub ShowSuccess
        if HasSuccess then
            %>
                <div class="alert alert-success alert-dismissible fade show my-2" role="alert">
                    <%= H(Success) %>
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            <%
            ClearSuccess
        end if
    End Sub
    
    Public Sub ClearSuccess
        Session.Contents.Remove(m_success_key)
    End Sub
    
End Class

Dim Flash
Set Flash = New Flash_Class

Function FlashFunc()
    Set FlashFunc = Flash
End Function
%>
