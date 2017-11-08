"""
cfn-flip-service
"""

from urllib import request
import boto3
import feedparser
import os
import yaml

CONFIG_FILE = "config.yaml"
MAX_ENTRIES = 5

SUPPORTED_TYPES = ("audio/mpeg",)

client = boto3.client("s3")

def handle_feed(bucket, name, url):
    feed = feedparser.parse(url)

    # Get existing files
    paginator = client.get_paginator("list_objects_v2")

    keys = [
        obj["Key"][len(name) + 1:]
        for page in paginator.paginate(Bucket=bucket, Prefix="{}/".format(name))
        for obj in page.get("Contents", [])
    ]

    for entry in feed.entries[:MAX_ENTRIES]:
        skip = False

        for enclosure in entry.enclosures:
            file_type = enclosure["type"]

            if file_type not in SUPPORTED_TYPES:
                print("{}: Ignoring enclosure of type: {}".format(name, file_type))
                continue

            href = enclosure["href"]
            file_name = os.path.basename(href)

            if file_name in keys:
                print("{}: Already downloaded '{}', skipping the remainder".format(name, href))
                skip = True
                break

            print("{}: Saving {}/{}".format(name, name, file_name))

            stream = request.urlopen(enclosure["href"])

            client.upload_fileobj(
                Fileobj=stream,
                Bucket=bucket,
                Key="{}/{}".format(name, file_name),
            )

        if skip:
            break

def handler(event, context):
    bucket = os.environ["BUCKET"]

    # Read in the config
    response = client.get_object(Bucket=bucket, Key=CONFIG_FILE)
    config = yaml.load(response["Body"])

    for name, url in config["feeds"].items():
        handle_feed(bucket, name, url)
