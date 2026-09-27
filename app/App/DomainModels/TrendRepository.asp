<%
'=======================================================================================================================
' ClassicX Trends Repository
'=======================================================================================================================

Class TrendModel_Class
    Public Id
    Public Category
    Public Topic
    Public PostCount
End Class

Class TrendRepository_Class
    Public Function GetTrends(limit_num)
        Dim sql : sql = "SELECT * FROM trends ORDER BY id ASC LIMIT " & CLng(limit_num)
        Dim rs : Set rs = DAL.Query(sql, Empty)
        Dim list : Set list = New LinkedList_Class
        Do While Not rs.EOF
            Dim t : Set t = New TrendModel_Class
            t.Id = SafeLng(rs("id"))
            t.Category = SafeStr(rs("category"))
            t.Topic = SafeStr(rs("topic"))
            t.PostCount = SafeStr(rs("post_count"))
            list.Append t
            rs.MoveNext
        Loop
        rs.Close
        Set GetTrends = list
    End Function

    Public Function GetTopTrends(limit_num)
        Set GetTopTrends = GetTrends(limit_num)
    End Function
End Class

Dim TrendRepository
Set TrendRepository = New TrendRepository_Class
%>
