<%
'=======================================================================================================================
' ClassicX Tweet / Post Repository
'=======================================================================================================================

Class TweetRepository_Class

    ' Helper to map a recordset row to a TweetModel_Class
    Public Function MapTweetRow(rs, current_user_id)

        Dim t : Set t = New TweetModel_Class
        t.Id = SafeLng(rs("id"))
        t.UserId = SafeLng(rs("user_id"))
        t.Content = SafeStr(rs("content"))
        t.ImageUrl = SafeStr(rs("image_url"))
        t.ParentId = SafeLng(rs("parent_id"))
        t.RepostId = SafeLng(rs("repost_id"))
        t.LikesCount = SafeLng(rs("likes_count"))
        t.RetweetsCount = SafeLng(rs("retweets_count"))
        t.RepliesCount = SafeLng(rs("replies_count"))
        t.ViewsCount = SafeLng(rs("views_count"))
        t.CreatedAt = SafeStr(rs("created_at"))

        t.UserName = SafeStr(rs("user_name"))
        t.UserHandle = SafeStr(rs("user_handle"))
        t.UserAvatarUrl = SafeStr(rs("user_avatar"))
        t.UserIsVerified = SafeBool(rs("user_verified"))

        t.IsLiked = (SafeLng(rs("is_liked")) > 0)
        t.IsRetweeted = (SafeLng(rs("is_retweeted")) > 0)
        t.IsBookmarked = (SafeLng(rs("is_bookmarked")) > 0)
        t.TimeAgoFormatted = Auth.FormatTimeAgo(SafeStr(rs("created_at")))


        If Not IsNull(rs("repost_handle")) Then
            t.RepostUserName = SafeStr(rs("repost_name"))
            t.RepostUserHandle = SafeStr(rs("repost_handle"))
        End If

        Set MapTweetRow = t
    End Function

    Public Function FindById(id, current_user_id)
        Dim uid : uid = CLng(current_user_id)
        Dim sql
        sql = "SELECT t.*, " &_
              "  u.name AS user_name, u.handle AS user_handle, u.avatar_url AS user_avatar, u.is_verified AS user_verified, " &_
              "  (SELECT COUNT(*) FROM likes WHERE tweet_id = t.id AND user_id = " & uid & ") AS is_liked, " &_
              "  (SELECT COUNT(*) FROM retweets WHERE tweet_id = t.id AND user_id = " & uid & ") AS is_retweeted, " &_
              "  (SELECT COUNT(*) FROM bookmarks WHERE tweet_id = t.id AND user_id = " & uid & ") AS is_bookmarked, NULL AS repost_name, NULL AS repost_handle " &_
              "FROM tweets t " &_
              "JOIN users u ON t.user_id = u.id " &_
              "WHERE t.id = ?"
        
        Dim rs : Set rs = DAL.Query(sql, Array(id))
        If rs.EOF Then
            Set FindById = Nothing
        Else
            Set FindById = MapTweetRow(rs, current_user_id)
            ' Increment views
            DAL.Exec "UPDATE tweets SET views_count = views_count + 1 WHERE id = ?", Array(id)
        End If
        rs.Close
    End Function

    Public Function GetFeed(current_user_id, feed_type, limit_num)
        Dim uid : uid = CLng(current_user_id)
        Dim sql
        If feed_type = "following" Then
            sql = "SELECT t.*, " &_
                  "  u.name AS user_name, u.handle AS user_handle, u.avatar_url AS user_avatar, u.is_verified AS user_verified, " &_
                  "  (SELECT COUNT(*) FROM likes WHERE tweet_id = t.id AND user_id = " & uid & ") AS is_liked, " &_
                  "  (SELECT COUNT(*) FROM retweets WHERE tweet_id = t.id AND user_id = " & uid & ") AS is_retweeted, " &_
                  "  (SELECT COUNT(*) FROM bookmarks WHERE tweet_id = t.id AND user_id = " & uid & ") AS is_bookmarked, " &_
                  "  NULL AS repost_name, NULL AS repost_handle " &_
                  "FROM tweets t " &_
                  "JOIN users u ON t.user_id = u.id " &_
                  "WHERE t.parent_id IS NULL " &_
                  "  AND (t.user_id = ? OR t.user_id IN (SELECT following_id FROM follows WHERE follower_id = ?)) " &_
                  "ORDER BY t.created_at DESC LIMIT " & CLng(limit_num)
            
            Dim rs : Set rs = DAL.Query(sql, Array(uid, uid))
            Dim list : Set list = New LinkedList_Class
            Do While Not rs.EOF
                list.Append MapTweetRow(rs, current_user_id)
                rs.MoveNext
            Loop
            rs.Close
            Set GetFeed = list
        Else
            ' "for_you" feed - all tweets, plus retweets
            sql = "SELECT t.*, " &_
                  "  u.name AS user_name, u.handle AS user_handle, u.avatar_url AS user_avatar, u.is_verified AS user_verified, " &_
                  "  (SELECT COUNT(*) FROM likes WHERE tweet_id = t.id AND user_id = " & uid & ") AS is_liked, " &_
                  "  (SELECT COUNT(*) FROM retweets WHERE tweet_id = t.id AND user_id = " & uid & ") AS is_retweeted, " &_
                  "  (SELECT COUNT(*) FROM bookmarks WHERE tweet_id = t.id AND user_id = " & uid & ") AS is_bookmarked, " &_
                  "  NULL AS repost_name, NULL AS repost_handle " &_
                  "FROM tweets t " &_
                  "JOIN users u ON t.user_id = u.id " &_
                  "WHERE t.parent_id IS NULL " &_
                  "ORDER BY t.created_at DESC LIMIT " & CLng(limit_num)
            
            Dim rs2 : Set rs2 = DAL.Query(sql, Empty)
            Dim list2 : Set list2 = New LinkedList_Class
            Do While Not rs2.EOF
                list2.Append MapTweetRow(rs2, current_user_id)
                rs2.MoveNext
            Loop
            rs2.Close
            Set GetFeed = list2
        End If
    End Function

    Public Function GetUserTweets(target_user_id, current_user_id, tab_type)
        Dim sql, rs, list
        Set list = New LinkedList_Class
        Dim uid : uid = CLng(current_user_id)
        Dim tid : tid = CLng(target_user_id)

        If tab_type = "replies" Then
            sql = "SELECT t.*, " &_
                  "  u.name AS user_name, u.handle AS user_handle, u.avatar_url AS user_avatar, u.is_verified AS user_verified, " &_
                  "  (SELECT COUNT(*) FROM likes WHERE tweet_id = t.id AND user_id = " & uid & ") AS is_liked, " &_
                  "  (SELECT COUNT(*) FROM retweets WHERE tweet_id = t.id AND user_id = " & uid & ") AS is_retweeted, " &_
                  "  (SELECT COUNT(*) FROM bookmarks WHERE tweet_id = t.id AND user_id = " & uid & ") AS is_bookmarked, " &_
                  "  NULL AS repost_name, NULL AS repost_handle " &_
                  "FROM tweets t " &_
                  "JOIN users u ON t.user_id = u.id " &_
                  "WHERE t.user_id = ? AND t.parent_id IS NOT NULL " &_
                  "ORDER BY t.created_at DESC LIMIT 50"
            Set rs = DAL.Query(sql, Array(tid))

        ElseIf tab_type = "likes" Then
            sql = "SELECT t.*, " &_
                  "  u.name AS user_name, u.handle AS user_handle, u.avatar_url AS user_avatar, u.is_verified AS user_verified, " &_
                  "  (SELECT COUNT(*) FROM likes WHERE tweet_id = t.id AND user_id = " & uid & ") AS is_liked, " &_
                  "  (SELECT COUNT(*) FROM retweets WHERE tweet_id = t.id AND user_id = " & uid & ") AS is_retweeted, " &_
                  "  (SELECT COUNT(*) FROM bookmarks WHERE tweet_id = t.id AND user_id = " & uid & ") AS is_bookmarked, " &_
                  "  NULL AS repost_name, NULL AS repost_handle " &_
                  "FROM likes l " &_
                  "JOIN tweets t ON l.tweet_id = t.id " &_
                  "JOIN users u ON t.user_id = u.id " &_
                  "WHERE l.user_id = ? " &_
                  "ORDER BY l.created_at DESC LIMIT 50"
            Set rs = DAL.Query(sql, Array(tid))

        Else
            ' "posts" - user posts and their retweets
            sql = "SELECT t.*, " &_
                  "  u.name AS user_name, u.handle AS user_handle, u.avatar_url AS user_avatar, u.is_verified AS user_verified, " &_
                  "  (SELECT COUNT(*) FROM likes WHERE tweet_id = t.id AND user_id = " & uid & ") AS is_liked, " &_
                  "  (SELECT COUNT(*) FROM retweets WHERE tweet_id = t.id AND user_id = " & uid & ") AS is_retweeted, " &_
                  "  (SELECT COUNT(*) FROM bookmarks WHERE tweet_id = t.id AND user_id = " & uid & ") AS is_bookmarked, " &_
                  "  NULL AS repost_name, NULL AS repost_handle " &_
                  "FROM tweets t " &_
                  "JOIN users u ON t.user_id = u.id " &_
                  "WHERE t.user_id = ? AND t.parent_id IS NULL " &_
                  "ORDER BY t.created_at DESC LIMIT 50"
            Set rs = DAL.Query(sql, Array(tid))
        End If

        Do While Not rs.EOF
            list.Append MapTweetRow(rs, current_user_id)
            rs.MoveNext
        Loop
        rs.Close
        Set GetUserTweets = list
    End Function

    Public Function GetReplies(parent_id, current_user_id)
        Dim uid : uid = CLng(current_user_id)
        Dim pid : pid = CLng(parent_id)
        Dim sql
        sql = "SELECT t.*, " &_
              "  u.name AS user_name, u.handle AS user_handle, u.avatar_url AS user_avatar, u.is_verified AS user_verified, " &_
              "  (SELECT COUNT(*) FROM likes WHERE tweet_id = t.id AND user_id = " & uid & ") AS is_liked, " &_
              "  (SELECT COUNT(*) FROM retweets WHERE tweet_id = t.id AND user_id = " & uid & ") AS is_retweeted, " &_
              "  (SELECT COUNT(*) FROM bookmarks WHERE tweet_id = t.id AND user_id = " & uid & ") AS is_bookmarked, " &_
              "  NULL AS repost_name, NULL AS repost_handle " &_
              "FROM tweets t " &_
              "JOIN users u ON t.user_id = u.id " &_
              "WHERE t.parent_id = ? " &_
              "ORDER BY t.created_at ASC"
        
        Dim rs : Set rs = DAL.Query(sql, Array(pid))
        Dim list : Set list = New LinkedList_Class
        Do While Not rs.EOF
            list.Append MapTweetRow(rs, current_user_id)
            rs.MoveNext
        Loop
        rs.Close
        Set GetReplies = list
    End Function

    Public Function CreateTweet(user_id, content, image_url, parent_id, repost_id)
        Dim p_id : p_id = Null
        If IsNumeric(parent_id) Then
            If CLng(parent_id) > 0 Then p_id = CLng(parent_id)
        End If

        Dim r_id : r_id = Null
        If IsNumeric(repost_id) Then
            If CLng(repost_id) > 0 Then r_id = CLng(repost_id)
        End If

        Dim img : img = Null
        If image_url <> "" Then img = image_url

        Dim sql
        sql = "INSERT INTO tweets (user_id, content, image_url, parent_id, repost_id, likes_count, retweets_count, replies_count, views_count, created_at) " &_
              "VALUES (?, ?, ?, ?, ?, 0, 0, 0, 1, NOW())"
        
        DAL.Exec sql, Array(user_id, content, img, p_id, r_id)
        Dim new_id : new_id = DAL.LastInsertId

        ' If this is a reply, update parent's replies count and create notification
        If Not IsNull(p_id) Then
            DAL.Exec "UPDATE tweets SET replies_count = replies_count + 1 WHERE id = ?", Array(p_id)
            Dim rsP : Set rsP = DAL.Query("SELECT user_id FROM tweets WHERE id = ?", Array(p_id))
            If Not rsP.EOF Then
                Dim parent_author_id : parent_author_id = CLng(rsP("user_id"))
                If parent_author_id <> user_id Then
                    DAL.Exec "INSERT INTO notifications (user_id, actor_id, type, tweet_id, created_at) VALUES (?, ?, 'reply', ?, NOW())", Array(parent_author_id, user_id, new_id)
                End If
            End If
            rsP.Close
        End If

        Set CreateTweet = FindById(new_id, user_id)
    End Function

    Public Sub DeleteTweet(tweet_id, user_id)
        ' Delete tweet if belongs to user
        DAL.Exec "DELETE FROM tweets WHERE id = ? AND user_id = ?", Array(tweet_id, user_id)
    End Sub

    Public Function ToggleLike(user_id, tweet_id)
        Dim checkSql : checkSql = "SELECT COUNT(*) AS c FROM likes WHERE user_id = ? AND tweet_id = ?"
        Dim rs : Set rs = DAL.Query(checkSql, Array(user_id, tweet_id))
        Dim count : count = CLng(rs("c"))
        rs.Close

        If count > 0 Then
            ' Unlike
            DAL.Exec "DELETE FROM likes WHERE user_id = ? AND tweet_id = ?", Array(user_id, tweet_id)
            DAL.Exec "UPDATE tweets SET likes_count = GREATEST(0, likes_count - 1) WHERE id = ?", Array(tweet_id)
            ToggleLike = False
        Else
            ' Like
            DAL.Exec "INSERT INTO likes (user_id, tweet_id, created_at) VALUES (?, ?, NOW())", Array(user_id, tweet_id)
            DAL.Exec "UPDATE tweets SET likes_count = likes_count + 1 WHERE id = ?", Array(tweet_id)
            
            ' Notify tweet author
            Dim rsAuthor : Set rsAuthor = DAL.Query("SELECT user_id FROM tweets WHERE id = ?", Array(tweet_id))
            If Not rsAuthor.EOF Then
                Dim author_id : author_id = CLng(rsAuthor("user_id"))
                If author_id <> user_id Then
                    DAL.Exec "INSERT INTO notifications (user_id, actor_id, type, tweet_id, created_at) VALUES (?, ?, 'like', ?, NOW())", Array(author_id, user_id, tweet_id)
                End If
            End If
            rsAuthor.Close
            ToggleLike = True
        End If
    End Function

    Public Function ToggleRetweet(user_id, tweet_id)
        Dim checkSql : checkSql = "SELECT COUNT(*) AS c FROM retweets WHERE user_id = ? AND tweet_id = ?"
        Dim rs : Set rs = DAL.Query(checkSql, Array(user_id, tweet_id))
        Dim count : count = CLng(rs("c"))
        rs.Close

        If count > 0 Then
            ' Un-retweet
            DAL.Exec "DELETE FROM retweets WHERE user_id = ? AND tweet_id = ?", Array(user_id, tweet_id)
            DAL.Exec "UPDATE tweets SET retweets_count = GREATEST(0, retweets_count - 1) WHERE id = ?", Array(tweet_id)
            ToggleRetweet = False
        Else
            ' Retweet
            DAL.Exec "INSERT INTO retweets (user_id, tweet_id, created_at) VALUES (?, ?, NOW())", Array(user_id, tweet_id)
            DAL.Exec "UPDATE tweets SET retweets_count = retweets_count + 1 WHERE id = ?", Array(tweet_id)
            
            Dim rsAuthor : Set rsAuthor = DAL.Query("SELECT user_id FROM tweets WHERE id = ?", Array(tweet_id))
            If Not rsAuthor.EOF Then
                Dim author_id : author_id = CLng(rsAuthor("user_id"))
                If author_id <> user_id Then
                    DAL.Exec "INSERT INTO notifications (user_id, actor_id, type, tweet_id, created_at) VALUES (?, ?, 'retweet', ?, NOW())", Array(author_id, user_id, tweet_id)
                End If
            End If
            rsAuthor.Close
            ToggleRetweet = True
        End If
    End Function

    Public Function ToggleBookmark(user_id, tweet_id)
        Dim checkSql : checkSql = "SELECT COUNT(*) AS c FROM bookmarks WHERE user_id = ? AND tweet_id = ?"
        Dim rs : Set rs = DAL.Query(checkSql, Array(user_id, tweet_id))
        Dim count : count = CLng(rs("c"))
        rs.Close

        If count > 0 Then
            DAL.Exec "DELETE FROM bookmarks WHERE user_id = ? AND tweet_id = ?", Array(user_id, tweet_id)
            ToggleBookmark = False
        Else
            DAL.Exec "INSERT INTO bookmarks (user_id, tweet_id, created_at) VALUES (?, ?, NOW())", Array(user_id, tweet_id)
            ToggleBookmark = True
        End If
    End Function

    Public Function GetBookmarks(current_user_id)
        Dim uid : uid = CLng(current_user_id)
        Dim sql
        sql = "SELECT t.*, " &_
              "  u.name AS user_name, u.handle AS user_handle, u.avatar_url AS user_avatar, u.is_verified AS user_verified, " &_
              "  (SELECT COUNT(*) FROM likes WHERE tweet_id = t.id AND user_id = " & uid & ") AS is_liked, " &_
              "  (SELECT COUNT(*) FROM retweets WHERE tweet_id = t.id AND user_id = " & uid & ") AS is_retweeted, " &_
              "  1 AS is_bookmarked, " &_
              "  NULL AS repost_name, NULL AS repost_handle " &_
              "FROM bookmarks b " &_
              "JOIN tweets t ON b.tweet_id = t.id " &_
              "JOIN users u ON t.user_id = u.id " &_
              "WHERE b.user_id = ? " &_
              "ORDER BY b.created_at DESC"
        
        Dim rs : Set rs = DAL.Query(sql, Array(uid))
        Dim list : Set list = New LinkedList_Class
        Do While Not rs.EOF
            list.Append MapTweetRow(rs, current_user_id)
            rs.MoveNext
        Loop
        rs.Close
        Set GetBookmarks = list
    End Function

    Public Function Search(query_text, current_user_id)
        Dim uid : uid = CLng(current_user_id)
        Dim search_pattern : search_pattern = "%" & query_text & "%"
        Dim sql
        sql = "SELECT t.*, " &_
              "  u.name AS user_name, u.handle AS user_handle, u.avatar_url AS user_avatar, u.is_verified AS user_verified, " &_
              "  (SELECT COUNT(*) FROM likes WHERE tweet_id = t.id AND user_id = " & uid & ") AS is_liked, " &_
              "  (SELECT COUNT(*) FROM retweets WHERE tweet_id = t.id AND user_id = " & uid & ") AS is_retweeted, " &_
              "  (SELECT COUNT(*) FROM bookmarks WHERE tweet_id = t.id AND user_id = " & uid & ") AS is_bookmarked, " &_
              "  NULL AS repost_name, NULL AS repost_handle " &_
              "FROM tweets t " &_
              "JOIN users u ON t.user_id = u.id " &_
              "WHERE t.content LIKE ? OR u.name LIKE ? OR u.handle LIKE ? " &_
              "ORDER BY t.created_at DESC LIMIT 50"
        
        Dim rs : Set rs = DAL.Query(sql, Array(search_pattern, search_pattern, search_pattern))
        Dim list : Set list = New LinkedList_Class
        Do While Not rs.EOF
            list.Append MapTweetRow(rs, current_user_id)
            rs.MoveNext
        Loop
        rs.Close
        Set Search = list
    End Function

End Class

Dim TweetRepository
Set TweetRepository = New TweetRepository_Class
%>
