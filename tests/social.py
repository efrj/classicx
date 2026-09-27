"""Local Docker demo test. Uses two isolated temporary users; removes them afterward."""
import json
import subprocess
import uuid
from smoke import Client, HOME, TWEETS

def sql(statement):
    return subprocess.check_output(['docker','exec','classicx_db','mariadb','-N','-B','-uclassicx','-pclassicx','bd_classicx','-e',statement],text=True).strip()

def run():
    prefix='qa_'+uuid.uuid4().hex[:10]
    ids=[]
    try:
        for n in [1,2]:
            handle=f'{prefix}_{n}'
            ids.append(sql(f"INSERT INTO users(username,handle,email,password_hash,name) VALUES ('{handle}','{handle}','{handle}@example.invalid','disabled','{handle}'); SELECT LAST_INSERT_ID();"))
        a,b=Client(),Client()
        for client,id in [(a,ids[0]),(b,ids[1])]:
            client.request(HOME);client.post('Auth','SwitchAccount',{'user_id':id})
        for _ in range(2):
            data,_=a.post('Users','FollowPost',{'user_id':ids[1]});assert json.loads(data)['active']
        assert sql(f'SELECT COUNT(*) FROM follows WHERE follower_id={ids[0]} AND following_id={ids[1]}')=='1'
        assert sql(f"SELECT COUNT(*) FROM notifications WHERE actor_id={ids[0]} AND user_id={ids[1]} AND type='follow'")=='1'
        notices,_=b.request('/App/Controllers/Notifications/NotificationsController.asp');assert prefix+'_1' in notices
        b.post('Notifications','ReadPost');assert sql(f'SELECT COUNT(*) FROM notifications WHERE user_id={ids[1]} AND is_read=0')=='0'
        _,url=b.post('Tweets','CreatePost',{'content':prefix+' followed post'})
        from urllib.parse import parse_qs,urlsplit
        postid=parse_qs(urlsplit(url).query)['id'][0]
        body,_=a.request(HOME+'?tab=following');assert prefix+' followed post' in body
        a.post('Tweets','RetweetPost',{'tweet_id':postid})
        body,_=a.request('/App/Controllers/Users/UsersController.asp?_A=Profile&handle='+prefix+'_1');assert prefix+' followed post' in body
        a.post('Users','UnfollowPost',{'user_id':ids[1]})
        assert sql(f'SELECT COUNT(*) FROM follows WHERE follower_id={ids[0]} AND following_id={ids[1]}')=='0'
        body,_=a.request(HOME+'?tab=following');assert prefix+' followed post' not in body
        a.post('Auth','Logout')
        body,_=a.request(HOME);assert 'ClassicX Official' in body
        print('PASS: follow/unfollow, idempotent follow, notifications, mark read, following feed, profile repost, demo reset')
    finally:
        if ids: sql('DELETE FROM users WHERE id IN ('+','.join(ids)+')')

if __name__=='__main__': run()
