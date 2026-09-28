"""Integration checks against the local demo. Creates and deletes only its own posts."""
import concurrent.futures
import http.cookiejar
import json
import re
import urllib.error
import urllib.parse
import urllib.request
import uuid
import os
BASE = os.environ.get('CLASSICX_URL', 'http://localhost:8000')
class Client:
    def __init__(self):
        self.opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
        self.token = ''
    def request(self, path, data=None, expected=200):
        req = urllib.request.Request(BASE+path, data=None if data is None else urllib.parse.urlencode(data).encode())
        try: res = self.opener.open(req, timeout=20)
        except urllib.error.HTTPError as e: res = e
        body = res.read().decode()
        assert res.code == expected, (path, res.code, body[-900:])
        match = re.search(r'name="csrf-token" content="([^"]+)"', body)
        if match: self.token = match[1]
        return body, res.url
    def post(self, controller, action, data=None, expected=200):
        return self.request(f'/App/Controllers/{controller}/{controller}Controller.asp?_A={action}', dict(csrf_token=self.token, **(data or {})), expected)
def extract_tweet_id(url):
    m = re.search(r'/status/(\d+)', url)
    if m: return m.group(1)
    qs = urllib.parse.parse_qs(urllib.parse.urlsplit(url).query)
    return qs['id'][0]

HOME = '/App/Controllers/Home/HomeController.asp'
TWEETS = '/App/Controllers/Tweets/TweetsController.asp'
def run():
    c = Client()
    pages = [HOME, HOME+'?_A=Explore&q=ASP', HOME+'?tab=following', TWEETS+'?_A=Bookmarks', '/App/Controllers/Users/UsersController.asp?_A=Profile&handle=classicx', '/App/Controllers/Notifications/NotificationsController.asp']
    for p in pages:
        body,_ = c.request(p)
        assert '</html>' in body
    for i in range(40): c.request(HOME)
    def read(i):
        client = Client()
        return client.request(pages[i % len(pages)])[0]
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        list(pool.map(read, range(80)))
    c.request(HOME+'?_A='+urllib.parse.quote('Index:Response.Write("injected")'), expected=404)
    c.request(TWEETS+'?_A=LikePost&tweet_id=1', expected=405)
    c.request(TWEETS+'?_A=LikePost', {'tweet_id':'1'}, expected=403)
    c.request(TWEETS+'?_A=Show&id=abc', expected=400)
    c.request(TWEETS+'?_A=Show&id=999999999', expected=404)
    for q in ["'", "\\' OR 1=1 --", '?', 'ação 🚀', '<script>']:
        c.request(HOME+'?_A=Explore&q='+urllib.parse.quote(q))
    c.post('Tweets','CreatePost',{'content':' '},expected=400)
    c.post('Tweets','CreatePost',{'content':'x'*281},expected=400)
    c.post('Tweets','CreatePost',{'content':'test','image_url':'javascript:alert(1)'},expected=400)
    ids=[]
    try:
        marker='smoke-'+uuid.uuid4().hex[:12]
        body,url=c.post('Tweets','CreatePost',{'content':marker+" ação \\' ? <script>alert(1)</script> #ASP @classicx"})
        id=extract_tweet_id(url);ids.append(id)
        assert marker in body and '<script>alert(1)</script>' not in body
        assert '%241' not in body
        for action in ['LikePost','RetweetPost','BookmarkPost']:
            for active in [True,False]:
                result,_=c.post('Tweets',action,{'tweet_id':id})
                assert json.loads(result)['active'] is active
        result,_=c.post('Tweets','BookmarkPost',{'tweet_id':id})
        body,_=c.request(TWEETS+'?_A=Bookmarks');assert marker in body
        c.post('Tweets','BookmarkPost',{'tweet_id':id})
        body,url=c.post('Tweets','CreatePost',{'content':marker+' reply','parent_id':id})
        reply=extract_tweet_id(url);ids.append(reply)
        body,_=c.request(TWEETS+'?_A=Show&id='+id);assert marker+' reply' in body
        other=Client();other.request(HOME);other.post('Auth','SwitchAccount',{'user_id':'2'})
        other.post('Tweets','DeletePost',{'id':id},expected=403)
        other.post('Tweets','CreatePost',{'content':'missing parent','parent_id':'999999999'},expected=404)
        c.post('Auth','SwitchAccount',{'user_id':'999999999'},expected=404)
        c.post('Users','FollowPost',{'user_id':'1'},expected=400)
        # Concurrent toggles must leave both relationship and denormalized count consistent.
        def toggle(_):
            return c.post('Tweets','LikePost',{'tweet_id':id})
        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool: list(pool.map(toggle,range(8)))
        body,_=c.request(TWEETS+'?_A=Show&id='+id)
        assert re.search(r'id: '+id+r', isLiked: false, likesCount: 0',body), 'Like count drift'
    finally:
        for id in reversed(ids): c.post('Tweets','DeletePost',{'id':id})
    print('PASS: pages, 40 refreshes, 80 concurrent reads, validation, CSRF, CRUD, replies, reactions, bookmarks, ownership, concurrent writes')
if __name__ == '__main__': run()
