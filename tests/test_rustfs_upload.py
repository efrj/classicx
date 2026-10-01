#!/usr/bin/env python3
"""
Test post image uploads to RustFS in ClassicX.
"""

import re
import sys
import io
import urllib.request
import urllib.parse
import http.cookiejar

BASE_URL = "http://localhost:8000"
RUSTFS_URL = "http://localhost:9000"

def get_csrf_token(html):
    m = re.search(r'name=["\']csrf-token["\']\s+content=["\']([^"\']+)["\']', html)
    if not m:
        m = re.search(r'name=["\']csrf_token["\']\s+value=["\']([^"\']+)["\']', html)
    return m.group(1) if m else None

def create_multipart(fields, files):
    boundary = "----ClassicXRustFSTestBoundary7MA4YWxkTrZu0gW"
    body = bytearray()
    for name, value in fields.items():
        body.extend(f"--{boundary}\r\n".encode("utf-8"))
        body.extend(f'Content-Disposition: form-data; name="{name}"\r\n\r\n'.encode("utf-8"))
        body.extend(str(value).encode("utf-8"))
        body.extend(b"\r\n")
    for name, (filename, content, mime) in files.items():
        body.extend(f"--{boundary}\r\n".encode("utf-8"))
        body.extend(f'Content-Disposition: form-data; name="{name}"; filename="{filename}"\r\n'.encode("utf-8"))
        body.extend(f"Content-Type: {mime}\r\n\r\n".encode("utf-8"))
        body.extend(content)
        body.extend(b"\r\n")
    body.extend(f"--{boundary}--\r\n".encode("utf-8"))
    content_type = f"multipart/form-data; boundary={boundary}"
    return body, content_type

def run_tests():
    cj = http.cookiejar.CookieJar()
    opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj))

    print("1. Fetching login page...")
    resp = opener.open(f"{BASE_URL}/login")
    login_html = resp.read().decode("utf-8")
    csrf = get_csrf_token(login_html)
    assert csrf, "CSRF token not found on login page"

    print("2. Logging in as alice...")
    login_data = urllib.parse.urlencode({
        "username": "alice",
        "password": "password123",
        "csrf_token": csrf
    }).encode("utf-8")
    resp = opener.open(f"{BASE_URL}/login/post", data=login_data)
    feed_html = resp.read().decode("utf-8")
    assert "alice" in feed_html or resp.status in (200, 302), "Login failed"

    csrf = get_csrf_token(feed_html) or csrf

    print("3. Uploading image to /tweets/upload...")
    # 1x1 transparent PNG bytes
    png_bytes = bytes([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
        0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
    ])

    body, ctype = create_multipart(
        {"csrf_token": csrf},
        {"image_file": ("test_rustfs.png", png_bytes, "image/png")}
    )
    req = urllib.request.Request(f"{BASE_URL}/tweets/upload", data=body, method="POST")
    req.add_header("Content-Type", ctype)

    upload_resp = opener.open(req)
    upload_json_str = upload_resp.read().decode("utf-8")
    print(f"Upload response: {upload_json_str}")
    import json
    data = json.loads(upload_json_str)
    assert data.get("success") is True, f"Upload unsuccessful: {data}"
    rustfs_img_url = data.get("url")
    assert "9000/uploads/" in rustfs_img_url, f"Unexpected image URL: {rustfs_img_url}"

    print(f"4. Verifying image can be downloaded directly from RustFS ({rustfs_img_url})...")
    with urllib.request.urlopen(rustfs_img_url) as img_resp:
        assert img_resp.status == 200, f"Failed to download image from RustFS, status: {img_resp.status}"
        downloaded_bytes = img_resp.read()
        assert len(downloaded_bytes) == len(png_bytes), f"Downloaded size mismatch: {len(downloaded_bytes)} vs {len(png_bytes)}"
        print("Image downloaded from RustFS successfully.")

    print("5. Posting a tweet with the RustFS image URL...")
    post_text = "Testing RustFS post uploads! 🚀 #RustFS"
    create_data = urllib.parse.urlencode({
        "content": post_text,
        "image_url": rustfs_img_url,
        "csrf_token": csrf
    }).encode("utf-8")
    post_resp = opener.open(f"{BASE_URL}/tweets/create", data=create_data)
    post_html = post_resp.read().decode("utf-8")
    assert post_text in post_html or rustfs_img_url in post_html, "Post content or RustFS image not found in response"
    print("Tweet created and verified successfully with RustFS media URL!")

    print("6. Testing direct multipart post upload to /tweets/create...")
    direct_post_text = "Direct multipart post with RustFS!"
    body2, ctype2 = create_multipart(
        {"content": direct_post_text, "csrf_token": csrf},
        {"image_file": ("direct_upload.png", png_bytes, "image/png")}
    )
    req2 = urllib.request.Request(f"{BASE_URL}/tweets/create", data=body2, method="POST")
    req2.add_header("Content-Type", ctype2)
    post_resp2 = opener.open(req2)
    post_html2 = post_resp2.read().decode("utf-8")
    assert direct_post_text in post_html2, "Direct multipart post content not found in response"
    assert "http://localhost:9000/uploads/" in post_html2, "RustFS image URL not found in post detail HTML"
    print("Direct multipart post created and image rendered successfully!")

    print("\nALL RUSTFS UPLOAD TESTS PASSED SUCCESSFULLY! 🎉")

if __name__ == "__main__":
    run_tests()
