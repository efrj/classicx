<%
'=======================================================================================================================
' Database Access Layer - Sane Database_Class for AxonASP ADODB / MariaDB
' Inspired by proven ODBC / ADODB architecture from SoCoisaLegal-old
'=======================================================================================================================

Function DAL_CreateCommand(connection, sql, params)
    Dim cmd : Set cmd = Server.CreateObject("ADODB.Command")
    Set cmd.ActiveConnection = connection
    cmd.CommandText = sql
    cmd.CommandType = 1
    If Not IsEmpty(params) Then
        Dim values, i, value, kind, size, param
        If IsArray(params) Then
            values = params
        Else
            values = Array(params)
        End If
        For i = 0 To UBound(values)
            value = values(i)
            kind = 202 ' adVarWChar
            size = 1
            If IsNull(value) Or IsEmpty(value) Then
                value = Null
            ElseIf VarType(value) = vbBoolean Then
                kind = 11 ' adBoolean
            ElseIf IsNumeric(value) And VarType(value) <> vbString Then
                kind = 3 ' adInteger: all current numeric parameters are IDs/counts.
            Else
                size = Len(CStr(value)) + 1
            End If
            Set param = cmd.CreateParameter("p" & i, kind, 1, size, value)
            cmd.Parameters.Append param
        Next
    End If
    Set DAL_CreateCommand = cmd
End Function

Class Database_Class
    Private m_connection
    Private m_connection_string
    Private m_driver
    Private m_trace_enabled
    
    Public Sub set_trace(bool) : m_trace_enabled = bool : End Sub
    Public Property Get is_trace_enabled : is_trace_enabled = m_trace_enabled : End Property
    
    Public Sub Initialize(connection_string)
        m_connection_string = connection_string
        m_driver = "mysql"
    End Sub

    Public Sub InitializeWithDriver(driver_name)
        m_driver = driver_name
    End Sub

    Private Sub EnsureConnection
        If IsObject(DAL_Conn) Then
            If Not DAL_Conn Is Nothing Then
                Set m_connection = DAL_Conn
                Exit Sub
            End If
        End If
        If IsObject(m_connection) Then
            If Not m_connection Is Nothing Then Exit Sub
        End If
        Set m_connection = Server.CreateObject("ADODB.Connection")
        Dim connStr : connStr = m_connection_string
        If connStr = "" Or IsEmpty(connStr) Then
            connStr = "DRIVER={MySQL ODBC 3.51 Driver};OPTION=3;DATABASE=bd_classicx;PWD=classicx;SERVER=db;UID=classicx;PORT=3306"
        End If
        m_connection.Open connStr
    End Sub

    '-------------------------------------------------------------------------------------------------------------------
    ' Executes a SELECT query with parameterized arguments and returns the Recordset cursor
    '-------------------------------------------------------------------------------------------------------------------
    Public Function Query(sql, params)
        EnsureConnection
        Dim cmd : Set cmd = DAL_CreateCommand(m_connection, sql, params)
        Set Query = cmd.Execute()
    End Function

    '-------------------------------------------------------------------------------------------------------------------
    ' Executes an INSERT/UPDATE/DELETE query with parameterized arguments
    '-------------------------------------------------------------------------------------------------------------------
    Public Function Exec(sql, params)
        EnsureConnection
        Dim cmd : Set cmd = DAL_CreateCommand(m_connection, sql, params)
        cmd.Execute
        Set Exec = Nothing
    End Function

    ' Sane compatibility
    Public Sub [Execute](sql, params)
        Exec sql, params
    End Sub

    Public Function LastInsertId
        EnsureConnection
        Dim rs : Set rs = m_connection.Execute("SELECT LAST_INSERT_ID() AS lid")
        If Not rs.EOF Then
            LastInsertId = CLng(rs("lid"))
        Else
            LastInsertId = 0
        End If
        rs.Close
    End Function

    Public Function RowsAffected
        RowsAffected = 1
    End Function

    Public Sub BeginTransaction
        EnsureConnection
        m_connection.BeginTrans
    End Sub

    Public Sub RollbackTransaction
        If IsObject(m_connection) Then
            If Not m_connection Is Nothing Then m_connection.RollbackTrans
        End If
    End Sub

    Public Sub CommitTransaction
        If IsObject(m_connection) Then
            If Not m_connection Is Nothing Then m_connection.CommitTrans
        End If
    End Sub

    Public Sub Close
        If IsObject(m_connection) Then
            If Not m_connection Is Nothing Then
                On Error Resume Next
                m_connection.Close
                Set m_connection = Nothing
                Err.Clear
            End If
        End If
    End Sub

    Private Sub Class_Terminate
        If IsObject(m_connection) Then
            If Not m_connection Is DAL_Conn Then
                Close
            End If
        End If
    End Sub

End Class

%>
