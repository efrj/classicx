<%
'=======================================================================================================================
' ClassicX User Repository
'=======================================================================================================================

Class UserRepository_Class

    Public Function FindById(ByVal id)
        Dim current_id : current_id = CLng(Auth.CurrentUserId)
        Dim sql
        sql = "SELECT u.*, " &_
              "  (SELECT COUNT(*) FROM follows WHERE following_id = u.id) AS followers_count, " &_
              "  (SELECT COUNT(*) FROM follows WHERE follower_id = u.id) AS following_count, " &_
              "  (SELECT COUNT(*) FROM tweets WHERE user_id = u.id AND parent_id IS NULL) AS tweets_count, " &_
              "  (SELECT COUNT(*) FROM follows WHERE follower_id = " & current_id & " AND following_id = u.id) AS is_followed " &_
              "FROM users u WHERE u.id = ?"
        
        If Not IsNumeric(id) Then
            Set FindById = Nothing
            Exit Function
        End If
        If CLng(id) < 1 Then
            Set FindById = Nothing
            Exit Function
        End If
        Dim rs : Set rs = DAL.Query(sql, Array(id))
        If Not IsObject(rs) Then
            Set FindById = Nothing
            Exit Function
        ElseIf rs Is Nothing Then
            Set FindById = Nothing
            Exit Function
        End If
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

    Public Function FindByHandle(ByVal handle_input)
        Dim current_id : current_id = CLng(Auth.CurrentUserId)
        Dim h : h = CStr(handle_input)
        ' Strip leading @ if present
        If Left(h, 1) = "@" Then h = Mid(h, 2)
        
        Dim sql
        sql = "SELECT u.*, " &_
              "  (SELECT COUNT(*) FROM follows WHERE following_id = u.id) AS followers_count, " &_
              "  (SELECT COUNT(*) FROM follows WHERE follower_id = u.id) AS following_count, " &_
              "  (SELECT COUNT(*) FROM tweets WHERE user_id = u.id AND parent_id IS NULL) AS tweets_count, " &_
              "  (SELECT COUNT(*) FROM follows WHERE follower_id = " & current_id & " AND following_id = u.id) AS is_followed " &_
              "FROM users u WHERE LOWER(u.handle) = LOWER(?)"
        
        Dim rs : Set rs = DAL.Query(sql, Array(h))
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

    Public Function FindByEmail(email)
        Dim sql : sql = "SELECT id FROM users WHERE LOWER(email) = LOWER(?)"
        Dim rs : Set rs = DAL.Query(sql, Array(email))
        If rs.EOF Then
            rs.Close
            Set FindByEmail = Nothing
        Else
            Dim uid : uid = SafeLng(rs("id"))
            rs.Close
            Set FindByEmail = FindById(uid)
        End If
    End Function

    Public Function HashPassword(raw_password, salt)
        Dim s : s = salt
        If s = "" Then
            Dim rsSalt : Set rsSalt = DAL.Query("SELECT HEX(RANDOM_BYTES(16)) AS s", Empty)
            s = SafeStr(rsSalt("s"))
            rsSalt.Close
        End If
        Dim rsHash : Set rsHash = DAL.Query("SELECT SHA2(CONCAT(?, ?), 256) AS h", Array(s, raw_password))
        Dim h : h = SafeStr(rsHash("h"))
        rsHash.Close
        HashPassword = "sha256$" & s & "$" & h
    End Function

    Public Function VerifyPassword(raw_password, stored_hash)
        If Left(stored_hash, 7) = "sha256$" Then
            Dim parts : parts = Split(stored_hash, "$")
            If UBound(parts) = 2 Then
                Dim s : s = parts(1)
                Dim expected_h : expected_h = parts(2)
                Dim rsH : Set rsH = DAL.Query("SELECT SHA2(CONCAT(?, ?), 256) AS h", Array(s, raw_password))
                Dim computed_h : computed_h = SafeStr(rsH("h"))
                rsH.Close
                VerifyPassword = (LCase(computed_h) = LCase(expected_h))
                Exit Function
            End If
        End If
        ' Fallback for legacy plain text passwords (seed accounts)
        VerifyPassword = (stored_hash = raw_password)
    End Function

    Public Function Authenticate(login_text, password_text)
        Dim sql
        sql = "SELECT id, password_hash FROM users WHERE LOWER(username) = LOWER(?) OR LOWER(email) = LOWER(?) OR LOWER(handle) = LOWER(?)"
        Dim rs : Set rs = DAL.Query(sql, Array(login_text, login_text, login_text))
        If rs.EOF Then
            rs.Close
            Set Authenticate = Nothing
            Exit Function
        End If
        Dim stored_hash : stored_hash = SafeStr(rs("password_hash"))
        Dim uid : uid = SafeLng(rs("id"))
        rs.Close
        If VerifyPassword(password_text, stored_hash) Then
            ' Automatically upgrade plain-text hash to salted SHA-256
            If Left(stored_hash, 7) <> "sha256$" Then
                Dim new_hashed : new_hashed = HashPassword(password_text, "")
                DAL.Exec "UPDATE users SET password_hash = ? WHERE id = ?", Array(new_hashed, uid)
            End If
            Set Authenticate = FindById(uid)
        Else
            Set Authenticate = Nothing
        End If
    End Function

    Public Function Register(username, handle, email, password, name)
        Dim cleanHandle : cleanHandle = handle
        If Left(cleanHandle, 1) = "@" Then cleanHandle = Mid(cleanHandle, 2)

        Dim hashed_pw : hashed_pw = HashPassword(password, "")
        Dim avatar : avatar = "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&auto=format&fit=crop&q=80"
        Dim banner : banner = "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=1200&auto=format&fit=crop&q=80"

        Dim sql
        sql = "INSERT INTO users (username, handle, email, password_hash, name, bio, location, website, avatar_url, banner_url, is_verified, created_at) " &_
              "VALUES (?, ?, ?, ?, ?, '', '', '', ?, ?, 0, NOW())"
        DAL.Exec sql, Array(username, cleanHandle, email, hashed_pw, name, avatar, banner)
        Dim new_id : new_id = DAL.LastInsertId
        Set Register = FindById(new_id)
    End Function

    Public Sub ResetPassword(user_id, new_password)
        Dim hashed_pw : hashed_pw = HashPassword(new_password, "")
        DAL.Exec "UPDATE users SET password_hash = ? WHERE id = ?", Array(hashed_pw, user_id)
    End Sub

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

    Public Sub UpdateProfile(id, name, bio, user_loc, website, avatar_url, banner_url)
        Dim sql
        sql = "UPDATE users SET name = ?, bio = ?, location = ?, website = ?, avatar_url = ?, banner_url = ? WHERE id = ?"
        DAL.Exec sql, Array(name, bio, user_loc, website, avatar_url, banner_url, id)
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

    Public Function SearchUsers(query_text, current_user_id)
        Dim uid : uid = CLng(current_user_id)
        Dim search_pattern : search_pattern = "%" & query_text & "%"
        Dim sql
        sql = "SELECT u.*, " &_
              "  (SELECT COUNT(*) FROM follows WHERE following_id = u.id) AS followers_count, " &_
              "  (SELECT COUNT(*) FROM follows WHERE follower_id = u.id) AS following_count, " &_
              "  (SELECT COUNT(*) FROM tweets WHERE user_id = u.id AND parent_id IS NULL) AS tweets_count, " &_
              "  (SELECT COUNT(*) FROM follows WHERE follower_id = " & uid & " AND following_id = u.id) AS is_followed " &_
              "FROM users u " &_
              "WHERE u.name LIKE ? OR u.handle LIKE ? OR u.bio LIKE ? " &_
              "ORDER BY followers_count DESC, u.id ASC LIMIT 30"
        Dim rs : Set rs = DAL.Query(sql, Array(search_pattern, search_pattern, search_pattern))
        Dim list : Set list = New LinkedList_Class
        Do While Not rs.EOF
            Dim u : Set u = New UserModel_Class
            u.Id = SafeLng(rs("id"))
            u.Username = SafeStr(rs("username"))
            u.Handle = SafeStr(rs("handle"))
            u.Email = SafeStr(rs("email"))
            u.Name = SafeStr(rs("name"))
            u.Bio = SafeStr(rs("bio"))
            u.Location = SafeStr(rs("location"))
            u.Website = SafeStr(rs("website"))
            u.AvatarUrl = SafeStr(rs("avatar_url"))
            u.BannerUrl = SafeStr(rs("banner_url"))
            u.IsVerified = SafeBool(rs("is_verified"))
            u.CreatedAt = rs("created_at")
            u.FollowersCount = SafeLng(rs("followers_count"))
            u.FollowingCount = SafeLng(rs("following_count"))
            u.TweetsCount = SafeLng(rs("tweets_count"))
            u.IsFollowedByCurrent = (SafeLng(rs("is_followed")) > 0)
            list.Append u
            rs.MoveNext
        Loop
        rs.Close
        Set SearchUsers = list
    End Function

    Public Function GetFollowers(target_user_id, current_user_id)
        Dim tid : tid = CLng(target_user_id)
        Dim cid : cid = CLng(current_user_id)
        Dim sql
        sql = "SELECT u.*, " &_
              "  (SELECT COUNT(*) FROM follows WHERE following_id = u.id) AS followers_count, " &_
              "  (SELECT COUNT(*) FROM follows WHERE follower_id = u.id) AS following_count, " &_
              "  (SELECT COUNT(*) FROM tweets WHERE user_id = u.id AND parent_id IS NULL) AS tweets_count, " &_
              "  (SELECT COUNT(*) FROM follows WHERE follower_id = " & cid & " AND following_id = u.id) AS is_followed " &_
              "FROM follows f " &_
              "JOIN users u ON f.follower_id = u.id " &_
              "WHERE f.following_id = ? " &_
              "ORDER BY f.created_at DESC LIMIT 50"
        Dim rs : Set rs = DAL.Query(sql, Array(tid))
        Dim list : Set list = New LinkedList_Class
        Do While Not rs.EOF
            Dim u2 : Set u2 = New UserModel_Class
            u2.Id = SafeLng(rs("id"))
            u2.Username = SafeStr(rs("username"))
            u2.Handle = SafeStr(rs("handle"))
            u2.Name = SafeStr(rs("name"))
            u2.Bio = SafeStr(rs("bio"))
            u2.AvatarUrl = SafeStr(rs("avatar_url"))
            u2.IsVerified = SafeBool(rs("is_verified"))
            u2.FollowersCount = SafeLng(rs("followers_count"))
            u2.FollowingCount = SafeLng(rs("following_count"))
            u2.TweetsCount = SafeLng(rs("tweets_count"))
            u2.IsFollowedByCurrent = (SafeLng(rs("is_followed")) > 0)
            list.Append u2
            rs.MoveNext
        Loop
        rs.Close
        Set GetFollowers = list
    End Function

    Public Function GetFollowing(target_user_id, current_user_id)
        Dim tid : tid = CLng(target_user_id)
        Dim cid : cid = CLng(current_user_id)
        Dim sql
        sql = "SELECT u.*, " &_
              "  (SELECT COUNT(*) FROM follows WHERE following_id = u.id) AS followers_count, " &_
              "  (SELECT COUNT(*) FROM follows WHERE follower_id = u.id) AS following_count, " &_
              "  (SELECT COUNT(*) FROM tweets WHERE user_id = u.id AND parent_id IS NULL) AS tweets_count, " &_
              "  (SELECT COUNT(*) FROM follows WHERE follower_id = " & cid & " AND following_id = u.id) AS is_followed " &_
              "FROM follows f " &_
              "JOIN users u ON f.following_id = u.id " &_
              "WHERE f.follower_id = ? " &_
              "ORDER BY f.created_at DESC LIMIT 50"
        Dim rs : Set rs = DAL.Query(sql, Array(tid))
        Dim list : Set list = New LinkedList_Class
        Do While Not rs.EOF
            Dim u3 : Set u3 = New UserModel_Class
            u3.Id = SafeLng(rs("id"))
            u3.Username = SafeStr(rs("username"))
            u3.Handle = SafeStr(rs("handle"))
            u3.Name = SafeStr(rs("name"))
            u3.Bio = SafeStr(rs("bio"))
            u3.AvatarUrl = SafeStr(rs("avatar_url"))
            u3.IsVerified = SafeBool(rs("is_verified"))
            u3.FollowersCount = SafeLng(rs("followers_count"))
            u3.FollowingCount = SafeLng(rs("following_count"))
            u3.TweetsCount = SafeLng(rs("tweets_count"))
            u3.IsFollowedByCurrent = (SafeLng(rs("is_followed")) > 0)
            list.Append u3
            rs.MoveNext
        Loop
        rs.Close
        Set GetFollowing = list
    End Function

End Class

Dim UserRepository
Set UserRepository = New UserRepository_Class
%>
