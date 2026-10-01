#!/usr/bin/env python3
"""
Initialize RustFS bucket and public access policy for ClassicX media uploads.
"""

import sys
import time
import urllib.request
import urllib.error
import hmac
import hashlib
from datetime import datetime, timezone

def sign(key, msg):
    return hmac.new(key, msg.encode("utf-8"), hashlib.sha256).digest()

def get_signature_key(key, date_stamp, region_name, service_name):
    k_date = sign(("AWS4" + key).encode("utf-8"), date_stamp)
    k_region = sign(k_date, region_name)
    k_service = sign(k_region, service_name)
    k_signing = sign(k_service, "aws4_request")
    return k_signing

def send_s3_request(host, method, uri, query="", body=b"", access_key="rustfsadmin", secret_key="rustfsadmin", region="us-east-1", service="s3"):
    now = datetime.now(timezone.utc)
    amz_date = now.strftime("%Y%m%dT%H%M%SZ")
    date_stamp = now.strftime("%Y%m%d")

    payload_hash = hashlib.sha256(body).hexdigest()
    canonical_uri = uri
    canonical_querystring = query
    canonical_headers = f"host:{host}\nx-amz-content-sha256:{payload_hash}\nx-amz-date:{amz_date}\n"
    signed_headers = "host;x-amz-content-sha256;x-amz-date"
    canonical_request = f"{method}\n{canonical_uri}\n{canonical_querystring}\n{canonical_headers}\n{signed_headers}\n{payload_hash}"

    algorithm = "AWS4-HMAC-SHA256"
    credential_scope = f"{date_stamp}/{region}/{service}/aws4_request"
    hashed_cr = hashlib.sha256(canonical_request.encode("utf-8")).hexdigest()
    string_to_sign = f"{algorithm}\n{amz_date}\n{credential_scope}\n{hashed_cr}"

    signing_key = get_signature_key(secret_key, date_stamp, region, service)
    signature = hmac.new(signing_key, string_to_sign.encode("utf-8"), hashlib.sha256).hexdigest()

    auth_header = f"{algorithm} Credential={access_key}/{credential_scope}, SignedHeaders={signed_headers}, Signature={signature}"

    url = f"http://{host}{uri}"
    if query:
        url += f"?{query.rstrip('=')}"

    req = urllib.request.Request(url, data=body if body else None, method=method)
    req.add_header("host", host)
    req.add_header("x-amz-date", amz_date)
    req.add_header("x-amz-content-sha256", payload_hash)
    req.add_header("Authorization", auth_header)
    if body:
        req.add_header("Content-Type", "application/json")

    return urllib.request.urlopen(req)

def init_rustfs(host="localhost:9000", bucket="uploads"):
    print(f"Connecting to RustFS at {host}...")
    for attempt in range(15):
        try:
            # 1. Create bucket if not exists
            try:
                with send_s3_request(host, "PUT", f"/{bucket}") as resp:
                    print(f"Bucket '{bucket}' created (HTTP {resp.status}).")
            except urllib.error.HTTPError as e:
                if e.code in (409, 200):
                    print(f"Bucket '{bucket}' already exists.")
                else:
                    err_msg = e.read().decode(errors="ignore")
                    if "BucketAlreadyOwnedByYou" in err_msg or "BucketAlreadyExists" in err_msg:
                        print(f"Bucket '{bucket}' already exists.")
                    else:
                        print(f"Notice on bucket creation: HTTP {e.code} - {err_msg}")

            # 2. Set public read & write policy for uploads/*
            policy = f"""{{
  "Version": "2012-10-17",
  "Statement": [
    {{
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::{bucket}/*"
      ]
    }}
  ]
}}"""
            try:
                with send_s3_request(host, "PUT", f"/{bucket}", query="policy=", body=policy.encode("utf-8")) as resp:
                    print(f"Public policy applied to '{bucket}' (HTTP {resp.status}).")
            except urllib.error.HTTPError as e:
                print(f"Policy update HTTP {e.code}: {e.read().decode(errors='ignore')}")

            print("RustFS initialization completed successfully.")
            return True
        except Exception as ex:
            print(f"Attempt {attempt + 1}/15 failed: {ex}. Retrying in 2s...")
            time.sleep(2)

    print("Failed to initialize RustFS.")
    return False

if __name__ == "__main__":
    host = sys.argv[1] if len(sys.argv) > 1 else "localhost:9000"
    bucket = sys.argv[2] if len(sys.argv) > 2 else "uploads"
    success = init_rustfs(host, bucket)
    sys.exit(0 if success else 1)
