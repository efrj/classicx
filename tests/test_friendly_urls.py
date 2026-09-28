"""Test suite for ClassicX friendly / clean URLs:
Verifies that all routes work via friendly URLs, root redirect works,
static assets are unaffected, and all rendered links in the UI use friendly URLs.
"""
import http.cookiejar
import json
import re
import urllib.parse
import urllib.request
import uuid
from smoke import Client, BASE

def run():
    c = Client()

    # 1. Root redirect
    req = urllib.request.Request(BASE + '/', headers={'User-Agent': 'Mozilla/5.0'})
    res = urllib.request.urlopen(req)
    assert '/home' in res.url, f"Expected root / to redirect to /home, got {res.url}"

    # 2. Main Navigation Friendly URLs
    urls_to_test = [
        ('/home', 'Home'),
        ('/home?tab=following', 'Following'),
        ('/explore', 'Explore'),
        ('/explore?q=ClassicASP&type=top', 'ClassicASP'),
        ('/explore?q=ClassicASP&type=latest', 'ClassicASP'),
        ('/explore?q=classicx&type=people', 'ClassicX Official'),
        ('/notifications', 'Notifications'),
        ('/bookmarks', 'Bookmarks'),
        ('/login', 'Sign in'),
        ('/register', 'Create your account'),
        ('/forgot', 'Find your account'),
        ('/@classicx', 'ClassicX Official'),
        ('/@classicx/followers', 'Followers'),
        ('/@classicx/following', 'Following'),
        ('/classicx', 'ClassicX Official'),
        ('/classicx/followers', 'Followers'),
        ('/classicx/following', 'Following'),
        ('/user/classicx', 'ClassicX Official'),
        ('/tweet/1', 'ClassicX'),
        ('/status/1', 'ClassicX'),
        ('/elonmusk/status/1', 'ClassicX'),
    ]

    for path, expected_text in urls_to_test:
        body, final_url = c.request(path)
        assert expected_text in body, f"Expected '{expected_text}' in response for {path}"

    # 3. Static asset preservation
    req_css = urllib.request.Request(BASE + '/Content/css/classicx.css')
    res_css = urllib.request.urlopen(req_css)
    assert res_css.code == 200, "Static CSS failed to load"
    assert 'text/css' in res_css.headers.get('Content-Type', ''), "CSS should have text/css content type"

    # 4. Verify rendered links in the UI are friendly URLs (no /App/Controllers in href)
    home_body, _ = c.request('/home')
    nav_links = re.findall(r'href="([^"]+)"\s+class="x-nav-link', home_body)
    assert len(nav_links) > 0, "Navigation links not found"
    for link in nav_links:
        assert not link.startswith('/App/Controllers/'), f"Navigation link should be friendly, got: {link}"
        assert link in ['/home', '/explore', '/notifications', '/bookmarks', '/@classicx'], f"Unexpected nav link: {link}"

    # 5. POST actions via friendly URLs
    marker = 'friendly-' + uuid.uuid4().hex[:8]
    create_body, create_url = c.request('/tweets/create', {'csrf_token': c.token, 'content': f'Testing friendly URL posts {marker}'})
    assert marker in create_body, f"Created tweet not found in timeline: {marker}"

    print("PASS: friendly URLs, root redirect, static assets, friendly UI links, and friendly POST actions")

if __name__ == '__main__':
    run()
