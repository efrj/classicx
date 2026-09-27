<%
'=======================================================================================================================
' ClassicX User Repository
'=======================================================================================================================

Class UserRepository_Class

    Public Function FindById(id)
        Dim current_id : current_id = CLng(Auth.CurrentUserId)
        Dim sql
        sql = "SELECT u.*, " &_
              "  (SELECT COUNT(*) FROM follows WHERE following_id = u.id) AS followers_count, " &_
              "  (SELECT COUNT(*) FROM follows WHERE follower_id = u.id) AS following_count, " &_
              "  (SELECT COUNT(*) FROM tweets WHERE user_id = u.id AND parent_id IS NULL) AS tweets_count, " &_
              "  (SELECT COUNT(*) FROM follows WHERE follower_id = " & current_id & " AND following_id = u.id) AS is_followed " &_
              "FROM users u WHERE u.id = ?"
        
        Dim rs : Set rs = DAL.Query(sql, Array(id))
        If rs.EOF Then
            Set FindById = Nothing
        Else
            Dim user_obj : Set user_obj = New UserModel_Class
            user_obj.Id = SafeLng(rs("id"))
            user_obj.Username = SafeStr(rs("username"))
            user_obj.Handle = SafeStr(rs("handle"))
            user_obj.Email = SafeStr(rs("email"))
            user_obj.PasswordHash = SafeStr(rs("password_hash"))
            user_obj.Name = SafeStr(rs("name"))
            user_obj.Bio = SafeStr(rs("bio"))
            user_obj.Location = SafeStr(rs("location"))
            user_obj.Website = SafeStr(rs("website"))
            user_obj.AvatarUrl = SafeStr(rs("avatar_url"))
            user_obj.BannerUrl = SafeStr(rs("banner_url"))
            user_obj.IsVerified = SafeBool(rs("is_verified"))
            user_obj.CreatedAt = rs("created_at")
            user_obj.FollowersCount = SafeLng(rs("followers_count"))
            user_obj.FollowingCount = SafeLng(rs("following_count"))
            user_obj.TweetsCount = SafeLng(rs("tweets_count"))
            user_obj.IsFollowedByCurrent = (SafeLng(rs("is_followed")) > 0)
            Set FindById = user_obj
        End If
        rs.Close
    End Function

    Public Function FindByHandle(handle)
        Dim current_id : current_id = CLng(Auth.CurrentUserId)
        ' Strip leading @ if present
        If Left(handle, 1) = "@" Then handle = Mid(handle, 2)
        
        Dim sql
        sql = "SELECT u.*, " &_
              "  (SELECT COUNT(*) FROM follows WHERE following_id = u.id) AS followers_count, " &_
              "  (SELECT COUNT(*) FROM follows WHERE follower_id = u.id) AS following_count, " &_
              "  (SELECT COUNT(*) FROM tweets WHERE user_id = u.id AND parent_id IS NULL) AS tweets_count, " &_
              "  (SELECT COUNT(*) FROM follows WHERE follower_id = " & current_id & " AND following_id = u.id) AS is_followed " &_
              "FROM users u WHERE LOWER(u.handle) = LOWER(?)"
        
        Dim rs : Set rs = DAL.Query(sql, Array(handle))
        If rs.EOF Then
            Set FindByHandle = Nothing
        Else
            Dim user_obj : Set user_obj = New UserModel_Class
            user_obj.Id = SafeLng(rs("id"))
            user_obj.Username = SafeStr(rs("username"))
            user_obj.Handle = SafeStr(rs("handle"))
            user_obj.Email = SafeStr(rs("email"))
            user_obj.PasswordHash = SafeStr(rs("password_hash"))
            user_obj.Name = SafeStr(rs("name"))
            user_obj.Bio = SafeStr(rs("bio"))
            user_obj.Location = SafeStr(rs("location"))
            user_obj.Website = SafeStr(rs("website"))
            user_obj.AvatarUrl = SafeStr(rs("avatar_url"))
            user_obj.BannerUrl = SafeStr(rs("banner_url"))
            user_obj.IsVerified = SafeBool(rs("is_verified"))
            user_obj.CreatedAt = rs("created_at")
            user_obj.FollowersCount = SafeLng(rs("followers_count"))
            user_obj.FollowingCount = SafeLng(rs("following_count"))
            user_obj.TweetsCount = SafeLng(rs("tweets_count"))
            user_obj.IsFollowedByCurrent = (SafeLng(rs("is_followed")) > 0)
            Set FindByHandle = user_obj
        End If
        rs.Close
    End Function

    Public Function Authenticate(login_text, password_text)
        Dim sql
        sql = "SELECT id, password_hash FROM users WHERE LOWER(username) = LOWER(?) OR LOWER(email) = LOWER(?) OR LOWER(handle) = LOWER(?)"
        Dim rs : Set rs = DAL.Query(sql, Array(login_text, login_text, login_text))
        If rs.EOF Then
            Set Authenticate = Nothing
        Else
            Dim stored_hash : stored_hash = CStr(rs("password_hash"))
            Dim uid : uid = CLng(rs("id"))
            rs.Close
            If stored_hash = password_text Then
                Set Authenticate = FindById(uid)
            Else
                Set Authenticate = Nothing
            End If
            Exit Function
        End If
        rs.Close
        Set Authenticate = Nothing
    End Function

    Public Function Create(user_model)
        Dim sql
        sql = "INSERT INTO users (username, handle, email, password_hash, name, bio, location, website, avatar_url, banner_url, is_verified, created_at) " &_
              "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, NOW())"
        
        Dim avatar : avatar = user_model.AvatarUrl
        If avatar = "" Then avatar = "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&auto=format&fit=crop&q=80"
        
        Dim banner : banner = user_model.BannerUrl
        If banner = "" Then banner = "https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=1200&auto=format&fit=crop&q=80"

        DAL.Exec sql, Array(user_model.Username, user_model.Handle, user_model.Email, user_model.PasswordHash, _
                            user_model.Name, user_model.Bio, user_model.Location, user_model.Website, avatar, banner)
        Dim new_id : new_id = DAL.LastInsertId
        Set Create = FindById(new_id)
    End Function

    Public Sub Update(user_model)
        Dim sql
        sql = "UPDATE users SET name = ?, bio = ?, location = ?, website = ?, avatar_url = ?, banner_url = ? WHERE id = ?"
        DAL.Exec sql, Array(user_model.Name, user_model.Bio, user_model.Location, user_model.Website, user_model.AvatarUrl, user_model.BannerUrl, user_model.Id)
    End Sub

    Public Function GetWhoToFollow(current_user_id, limit_num)
        Dim sql
        sql = "SELECT u.*, " &_
              "  (SELECT COUNT(*) FROM follows WHERE following_id = u.id) AS followers_count, " &_
              "  (SELECT COUNT(*) FROM follows WHERE follower_id = u.id) AS following_count, " &_
              "  (SELECT COUNT(*) FROM tweets WHERE user_id = u.id) AS tweets_count, " &_
              "  0 AS is_followed " &_
              "FROM users u " &_
              "WHERE u.id <> ? " &_
              "  AND u.id NOT IN (SELECT following_id FROM follows WHERE follower_id = ?) " &_
              "ORDER BY followers_count DESC, u.id ASC LIMIT " & CLng(limit_num)
        
        Dim rs : Set rs = DAL.Query(sql, Array(current_user_id, current_user_id))
        Dim list : Set list = New LinkedList_Class
        Do While Not rs.EOF
            Dim u : Set u = New UserModel_Class
            u.Id = SafeLng(rs("id"))
            u.Username = SafeStr(rs("username"))
            u.Handle = SafeStr(rs("handle"))
            u.Name = SafeStr(rs("name"))
            u.Bio = SafeStr(rs("bio"))
            u.AvatarUrl = SafeStr(rs("avatar_url"))
            u.IsVerified = SafeBool(rs("is_verified"))
            u.FollowersCount = SafeLng(rs("followers_count"))
            u.IsFollowedByCurrent = False
            list.Append u
            rs.MoveNext
        Loop
        rs.Close
        Set GetWhoToFollow = list
    End Function

    Public Function GetAllUsers()
        Dim sql : sql = "SELECT * FROM users ORDER BY id ASC"
        Dim rs : Set rs = DAL.Query(sql, Empty)
        Dim list : Set list = New LinkedList_Class
        Do While Not rs.EOF
            Dim u : Set u = New UserModel_Class
            u.Id = SafeLng(rs("id"))
            u.Username = SafeStr(rs("username"))
            u.Handle = SafeStr(rs("handle"))
            u.Name = SafeStr(rs("name"))
            u.AvatarUrl = SafeStr(rs("avatar_url"))
            u.IsVerified = SafeBool(rs("is_verified"))
            list.Append u
            rs.MoveNext
        Loop
        rs.Close
        Set GetAllUsers = list
    End Function

    Public Sub Follow(follower_id, following_id)
        If follower_id = following_id Then Exit Sub
        Dim checkSql : checkSql = "SELECT COUNT(*) AS c FROM follows WHERE follower_id = ? AND following_id = ?"
        Dim rs : Set rs = DAL.Query(checkSql, Array(follower_id, following_id))
        Dim count : count = CLng(rs("c"))
        rs.Close
        If count = 0 Then
            DAL.Exec "INSERT INTO follows (follower_id, following_id, created_at) VALUES (?, ?, NOW())", Array(follower_id, following_id)
            DAL.Exec "INSERT INTO notifications (user_id, actor_id, type, created_at) VALUES (?, ?, 'follow', NOW())", Array(following_id, follower_id)
        End If
    End Sub

    Public Sub Unfollow(follower_id, following_id)
        DAL.Exec "DELETE FROM follows WHERE follower_id = ? AND following_id = ?", Array(follower_id, following_id)
    End Sub

End Class

Dim UserRepository
Set UserRepository = New UserRepository_Class
%>
