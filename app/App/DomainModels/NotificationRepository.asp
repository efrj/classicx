<%
'=======================================================================================================================
' ClassicX Notification Repository
'=======================================================================================================================

Class NotificationModel_Class
    Public Id
    Public UserId
    Public ActorId
    Public ActorName
    Public ActorHandle
    Public ActorAvatar
    Public ActorIsVerified
    Public NotifType
    Public TweetId
    Public TweetContent
    Public TweetAuthorHandle
    Public IsRead
    Public CreatedAt
    Public TimeAgoFormatted
End Class

Class NotificationRepository_Class
    Public Function GetNotifications(user_id)
        Dim sql
        sql = "SELECT n.*, n.type AS notif_type, " &_
              "  u.name AS actor_name, u.handle AS actor_handle, u.avatar_url AS actor_avatar, u.is_verified AS actor_verified, " &_
              "  t.content AS tweet_content, author.handle AS tweet_author_handle " &_
              "FROM notifications n " &_
              "JOIN users u ON n.actor_id = u.id " &_
              "LEFT JOIN tweets t ON n.tweet_id = t.id " &_
              "LEFT JOIN users author ON t.user_id = author.id " &_
              "WHERE n.user_id = ? " &_
              "ORDER BY n.created_at DESC LIMIT 50"
        
        Dim rs : Set rs = DAL.Query(sql, Array(user_id))
        Dim list : Set list = New LinkedList_Class
        If IsObject(rs) Then
            If Not rs Is Nothing Then
                Do While Not rs.EOF
                    Dim n : Set n = New NotificationModel_Class
                    n.Id = SafeLng(rs("id"))
                    n.UserId = SafeLng(rs("user_id"))
                    n.ActorId = SafeLng(rs("actor_id"))
                    n.ActorName = SafeStr(rs("actor_name"))
                    n.ActorHandle = SafeStr(rs("actor_handle"))
                    n.ActorAvatar = SafeStr(rs("actor_avatar"))
                    n.ActorIsVerified = SafeBool(rs("actor_verified"))
                    n.NotifType = SafeStr(rs("notif_type"))
                    n.TweetId = SafeLng(rs("tweet_id"))
                    n.TweetContent = SafeStr(rs("tweet_content"))
                    n.TweetAuthorHandle = SafeStr(rs("tweet_author_handle"))
                    n.IsRead = SafeBool(rs("is_read"))
                    n.CreatedAt = SafeStr(rs("created_at"))
                    n.TimeAgoFormatted = Auth.FormatTimeAgo(SafeStr(rs("created_at")))
                    list.Append n
                    rs.MoveNext
                Loop
                rs.Close
            End If
        End If
        Set GetNotifications = list
    End Function

    Public Sub MarkAllAsRead(user_id)
        DAL.Exec "UPDATE notifications SET is_read = 1 WHERE user_id = ?", Array(user_id)
    End Sub

    Public Function GetUnreadCount(user_id)
        Dim rs : Set rs = DAL.Query("SELECT COUNT(*) AS c FROM notifications WHERE user_id = ? AND is_read = 0", Array(user_id))
        If Not rs.EOF Then
            GetUnreadCount = CLng(rs("c"))
        Else
            GetUnreadCount = 0
        End If
        rs.Close
    End Function
End Class

Dim NotificationRepository
Set NotificationRepository = New NotificationRepository_Class
%>
