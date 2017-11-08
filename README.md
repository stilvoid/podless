# podless

A serverless application that downloads podcasts to an S3 bucket.

## Installing

Run the `install.sh` script to create a bucket and install the podless service. The installer will include a default configuration file that subscribes you to the AWS podcast. Of course you can change this before you install :)

## Configuring

To subscribe to new podcasts or to stop downloading a podcast, you need to modify the `config.yaml` file that's stored in the S3 bucket.

The format of the config file is simple:

```yaml
feeds:
  feed_name: http://my/feed/url.rss
  another_feed: https://another/feed.rss
```

The keys of the `feeds` section are used as prefixes to the downloaded files so your S3 bucket would contain something like the following:

```
config.yaml
feed_name/
    episode01.mp3
    episode02.mp3
another_feed/
    S01E03.mp3
    S01E04.mp3
    S01E05.mp3
```

By default, the podless service will run once per day. You can modify this in the `template.yaml` file.

Also by default, the podless service will download at most the latest 5 episodes from each feed. You can change this by modifying the MAX_ENTRIES variable in `src/service.py`.

The podless service only supports RSS/Atom feeds and only downloads mp3 files at present.

If you want more features, please send me a pull request :D
