<%
'=======================================================================================================================
' ClassicX Data Access Layer (DAL) Singleton
' Connects to MariaDB using AxonASP ADODB / MySQL ODBC driver (proven from SoCoisaLegal-old)
'=======================================================================================================================

Dim DAL_Conn
Set DAL_Conn = Server.CreateObject("ADODB.Connection")
DAL_Conn.Open "DRIVER={MySQL ODBC 3.51 Driver};OPTION=3;DATABASE=bd_classicx;PWD=classicx;SERVER=db;UID=classicx;PORT=3306"


Class DAL_Class
    Public Function Query(sql, params)
        Dim cmd : Set cmd = DAL_CreateCommand(DAL_Conn, sql, params)
        Set Query = cmd.Execute()
    End Function

    Public Sub Exec(sql, params)
        Dim cmd : Set cmd = DAL_CreateCommand(DAL_Conn, sql, params)
        cmd.Execute
    End Sub

    Public Sub [Execute](sql, params)
        Exec sql, params
    End Sub

    Public Function LastInsertId
        Dim rs : Set rs = DAL_Conn.Execute("SELECT LAST_INSERT_ID() AS lid")
        If Not rs.EOF Then
            LastInsertId = CLng(rs("lid"))
        Else
            LastInsertId = 0
        End If
        rs.Close
    End Function

    Public Sub BeginTransaction
        DAL_Conn.BeginTrans
    End Sub

    Public Sub RollbackTransaction
        DAL_Conn.RollbackTrans
    End Sub

    Public Sub CommitTransaction
        DAL_Conn.CommitTrans
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
