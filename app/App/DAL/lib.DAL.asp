<%
'=======================================================================================================================
' ClassicX Data Access Layer (DAL) Singleton
' Connects to MariaDB using AxonASP ADODB / MySQL ODBC driver (proven from SoCoisaLegal-old)
'=======================================================================================================================

Dim DAL_Conn

Function DAL_GetConnection()
    Dim needOpen : needOpen = False
    If Not IsObject(DAL_Conn) Then
        needOpen = True
    ElseIf DAL_Conn Is Nothing Then
        needOpen = True
    Else
        On Error Resume Next
        If DAL_Conn.State = 0 Then needOpen = True
        If Err.Number <> 0 Then needOpen = True
        Err.Clear
        On Error Goto 0
    End If
    If needOpen Then
        Set DAL_Conn = Server.CreateObject("ADODB.Connection")
        DAL_Conn.Open "DRIVER={MySQL ODBC 3.51 Driver};OPTION=3;DATABASE=bd_classicx;PWD=classicx;SERVER=db;UID=classicx;PORT=3306"
    End If
    Set DAL_GetConnection = DAL_Conn
End Function

Class DAL_Class
    Public Function Query(sql, params)
        Dim conn : Set conn = DAL_GetConnection()
        Dim cmd : Set cmd = DAL_CreateCommand(conn, sql, params)
        Set Query = cmd.Execute()
    End Function

    Public Sub Exec(sql, params)
        Dim conn : Set conn = DAL_GetConnection()
        Dim cmd : Set cmd = DAL_CreateCommand(conn, sql, params)
        cmd.Execute
    End Sub

    Public Sub [Execute](sql, params)
        Exec sql, params
    End Sub

    Public Function LastInsertId
        Dim conn : Set conn = DAL_GetConnection()
        Dim rs : Set rs = conn.Execute("SELECT LAST_INSERT_ID() AS lid")
        If Not rs.EOF Then
            LastInsertId = CLng(rs("lid"))
        Else
            LastInsertId = 0
        End If
        rs.Close
    End Function

    Public Sub BeginTransaction
        Dim conn : Set conn = DAL_GetConnection()
        conn.BeginTrans
    End Sub

    Public Sub RollbackTransaction
        Dim conn : Set conn = DAL_GetConnection()
        conn.RollbackTrans
    End Sub

    Public Sub CommitTransaction
        Dim conn : Set conn = DAL_GetConnection()
        conn.CommitTrans
    End Sub

    Public Sub Close
        On Error Resume Next
        If IsObject(DAL_Conn) Then
            If Not DAL_Conn Is Nothing Then
                DAL_Conn.Close
                Set DAL_Conn = Nothing
            End If
        End If
        Err.Clear
    End Sub
End Class

Dim DAL
Set DAL = New DAL_Class
%>
