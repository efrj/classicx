"""Test suite for ClassicX extended features:
- Registration and secure SHA256 salted password hashing
- Password authentication and error handling
- Password recovery (forgot password)
- Profile editing (name, bio, location, website, avatar, banner)
- Followers and Following user list pages
- Explore search tabs (Top, Latest, People)
- Following feed repost distribution
"""
import json
import re
import uuid
from urllib.parse import parse_qs, urlsplit
from smoke import Client, HOME, TWEETS, db_query as sql

AUTH = '/App/Controllers/Auth/AuthController.asp'
USERS = '/App/Controllers/Users/UsersController.asp'

def run():
    prefix = 'feat_' + uuid.uuid4().hex[:8]
    created_handles = []
    
    try:
        # 1. Registration
        c1 = Client()
        c1.request(HOME)
        handle1 = f'{prefix}_u1'
        email1 = f'{handle1}@example.com'
        name1 = f'User One {prefix}'
        pass1 = 'secret_pass_1'
        
        c1.post('Auth', 'RegisterPost', {
            'handle': handle1,
            'email': email1,
            'name': name1,
            'password': pass1
        })
        created_handles.append(handle1)
        
        # Verify user exists in database and password is salted sha256
        db_hash = sql(f"SELECT password_hash FROM users WHERE handle='{handle1}'")
        assert db_hash.startswith('sha256$'), f"Expected sha256 prefix in hash, got {db_hash}"
        parts = db_hash.split('$')
        assert len(parts) == 3, f"Expected 3 parts (sha256$salt$hash), got {parts}"
        assert len(parts[1]) == 32, f"Expected 32 hex salt, got {len(parts[1])}"
        assert len(parts[2]) == 64, f"Expected 64 hex sha256 hash, got {len(parts[2])}"
        
        # Verify authenticated state
        body, _ = c1.request(HOME)
        assert name1 in body or handle1 in body, "Expected registered user name/handle on timeline"

        # 2. Authentication (Login with correct vs incorrect password)
        c_login = Client()
        c_login.request(HOME)
        
        # Attempt login with wrong password
        c_login.post('Auth', 'LoginPost', {
            'login': handle1,
            'password': 'wrong_password_xyz'
        })
        # Verify still not authenticated as user1 (check active user badge)
        body, _ = c_login.request(HOME)
        assert f'@{handle1}</span>' not in body, "User should not be the active user after bad password"

        # Attempt login with correct password
        c_login.post('Auth', 'LoginPost', {
            'login': handle1,
            'password': pass1
        })
        body, _ = c_login.request(HOME)
        assert f'@{handle1}</span>' in body, "User should be the active user after valid password"

        # 3. Password recovery / Reset (Forgot)
        new_pass1 = 'new_secret_pass_2'
        c_forgot = Client()
        c_forgot.request(HOME)
        c_forgot.post('Auth', 'ForgotPost', {
            'login': email1,
            'password': new_pass1
        })
        
        # Old password should now fail
        c_relogin = Client()
        c_relogin.request(HOME)
        c_relogin.post('Auth', 'LoginPost', {
            'login': handle1,
            'password': pass1
        })
        body, _ = c_relogin.request(HOME)
        assert f'@{handle1}</span>' not in body, "Old password should no longer log in"
        
        # New password should succeed
        c_relogin.post('Auth', 'LoginPost', {
            'login': handle1,
            'password': new_pass1
        })
        body, _ = c_relogin.request(HOME)
        assert f'@{handle1}</span>' in body, "New password should log in"

        # 4. Profile Editing
        new_name = f'Updated {name1}'
        new_bio = 'Passionate developer exploring Classic ASP and MariaDB.'
        new_loc = 'Silicon Valley, CA'
        new_web = 'https://classicx.example.com'
        new_avatar = 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'
        new_banner = 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600'
        
        c_relogin.post('Users', 'UpdateProfilePost', {
            'name': new_name,
            'bio': new_bio,
            'location': new_loc,
            'website': new_web,
            'avatar_url': new_avatar,
            'banner_url': new_banner
        })
        
        profile_page, _ = c_relogin.request(f'{USERS}?_A=Profile&handle={handle1}')
        assert new_name in profile_page, f"Updated name not found in profile: {new_name}"
        assert new_bio in profile_page, "Updated bio not found in profile"
        assert new_loc in profile_page, "Updated location not found in profile"
        assert new_web in profile_page, "Updated website not found in profile"

        # 5. Followers & Following User Lists
        c2 = Client()
        c2.request(HOME)
        handle2 = f'{prefix}_u2'
        email2 = f'{handle2}@example.com'
        name2 = f'User Two {prefix}'
        pass2 = 'secret_pass_2'
        c2.post('Auth', 'RegisterPost', {
            'handle': handle2,
            'email': email2,
            'name': name2,
            'password': pass2
        })
        created_handles.append(handle2)
        
        u1_id = sql(f"SELECT id FROM users WHERE handle='{handle1}'")
        u2_id = sql(f"SELECT id FROM users WHERE handle='{handle2}'")
        
        # User 1 follows User 2
        c_relogin.post('Users', 'FollowPost', {'user_id': u2_id})
        
        # Check User 2's Followers list page
        followers_page, _ = c_relogin.request(f'{USERS}?_A=Followers&handle={handle2}')
        assert handle1 in followers_page, "User 1 should appear in User 2's Followers list"
        assert new_name in followers_page, "User 1's name should appear in User 2's Followers list"
        
        # Check User 1's Following list page
        following_page, _ = c_relogin.request(f'{USERS}?_A=Following&handle={handle1}')
        assert handle2 in following_page, "User 2 should appear in User 1's Following list"
        assert name2 in following_page, "User 2's name should appear in User 1's Following list"

        # 6. Explore Search Tabs: Top, Latest, People
        # Create a unique tweet from User 2
        unique_term = f'tag_{prefix}'
        _, tweet_url = c2.post('Tweets', 'CreatePost', {'content': f'Exploring search with {unique_term} today!'})
        
        # Search Top
        top_page, _ = c1.request(f'{HOME}?_A=Explore&q={unique_term}&type=top')
        assert unique_term in top_page, "Search Top tab should return matching tweet"
        
        # Search Latest
        latest_page, _ = c1.request(f'{HOME}?_A=Explore&q={unique_term}&type=latest')
        assert unique_term in latest_page, "Search Latest tab should return matching tweet"
        
        # Search People
        people_page, _ = c1.request(f'{HOME}?_A=Explore&q={prefix}&type=people')
        assert handle1 in people_page, "Search People tab should find handle1"
        assert handle2 in people_page, "Search People tab should find handle2"

        # 7. Following feed repost distribution
        # User 1 is following User 2. User 2 retweets User 1's post.
        # User 3 follows User 2. User 3 should see User 1's post in their Following feed distributed as a repost!
        c3 = Client()
        c3.request(HOME)
        handle3 = f'{prefix}_u3'
        c3.post('Auth', 'RegisterPost', {
            'handle': handle3,
            'email': f'{handle3}@example.com',
            'name': f'User Three {prefix}',
            'password': 'password123'
        })
        created_handles.append(handle3)
        u3_id = sql(f"SELECT id FROM users WHERE handle='{handle3}'")
        
        # User 3 follows User 2
        c3.post('Users', 'FollowPost', {'user_id': u2_id})
        
        # User 1 creates post P1
        _, p1_url = c_relogin.post('Tweets', 'CreatePost', {'content': f'P1 by user 1 {prefix}'})
        from smoke import extract_tweet_id
        p1_id = extract_tweet_id(p1_url)
        
        # User 2 retweets P1
        c2.post('Tweets', 'RetweetPost', {'tweet_id': p1_id})
        
        # User 3 checks Following feed: should see P1 with "reposted" or User 2 reposting
        feed_page, _ = c3.request(f'{HOME}?tab=following')
        assert f'P1 by user 1 {prefix}' in feed_page, "Following feed should include reposted post from followed user"
        assert name2 in feed_page or handle2 in feed_page, "Following feed should indicate reposting user"

        # 9. Verify X-style Delete Modal and Copy Toast UI
        home_html, _ = c_relogin.request(HOME)
        assert 'id="deletePostModal"' in home_html, "Expected deletePostModal in DOM"
        assert 'Delete post?' in home_html, "Expected X-style 'Delete post?' in modal"
        assert 'id="xToast"' in home_html, "Expected X toast notification pill in DOM"
        assert 'copyPostLink(' in home_html, "Expected copyPostLink helper call on tweet cards"
        assert "alert('Link copied" not in home_html, "No native alert() calls should remain in tweet cards"
        assert 'onclick="alert(' not in home_html, "No native alert() in onclick attributes"
        assert "confirm('Delete this post?')" not in home_html, "No native confirm() should remain for delete"

        print("PASS: registration, salted password hashing, login, password recovery, profile edit, user lists, explore tabs, following feed reposts, X-style modal and toast")
    finally:
        if created_handles:
            handles_in = "'" + "','".join(created_handles) + "'"
            sql(f"DELETE FROM users WHERE handle IN ({handles_in})")

if __name__ == '__main__':
    run()
