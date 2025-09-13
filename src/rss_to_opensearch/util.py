#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on 2025-09-02T20:55:00-04:00

@author: nate
"""
import codecs
import datetime as dt
import json
import os
import random
import re
import shutil
import time
from collections import OrderedDict
from email.utils import parsedate_to_datetime
from pathlib import Path
from urllib.parse import parse_qsl, urlencode, urlparse, urlunparse

import feedparser
import opensearchpy as osp
import tldextract
from curl_cffi import requests as cf
from loguru import logger
from opensearchpy import OpenSearch
from rss_to_opensearch.settings import settings


def _fmt_secs(seconds: float) -> str:
    seconds = max(0, int(round(seconds)))
    m, s = divmod(seconds, 60)
    return f"{m:02d}:{s:02d}"

def wait_with_progress(num_secs: float, interval: float = 30.0) -> None:
    if num_secs < 0:
        raise ValueError("num_secs must be >= 0")
    start = time.monotonic()
    end = start + num_secs
    next_tick = start + interval
    while True:
        now = time.monotonic()
        if now >= end:
            break
        # Sleep until the next interval or the end, whichever comes first
        sleep_dur = min(next_tick, end) - now
        if sleep_dur > 0:
            time.sleep(sleep_dur)
        now = time.monotonic()
        # Print only on interval ticks that occurred before the end time
        if now < end and now + 1e-9 >= next_tick:
            elapsed = now - start
            remaining = end - now
            logger.info(f"Elapsed: {_fmt_secs(elapsed)} | Remaining: {_fmt_secs(remaining)}")
            next_tick += interval
    total = time.monotonic() - start
    logger.info(f"Done. Elapsed: {_fmt_secs(total)} | Remaining: 00:00")








def normalize_url(url):
    # strip obvious trackers; keep scheme+host+path
    u = urlparse(url)
    return urlunparse((u.scheme, u.netloc, u.path.rstrip("/"), "", "", ""))

def get_project_root() -> Path:
    start_path = Path(__file__).resolve().parent
    for parent in [start_path] + list(start_path.parents):
        if (parent / "pyproject.toml").is_file():
            return parent
    raise FileNotFoundError("No pyproject.toml found.")

def add_stamp(url: str, key: str = "t") -> str:
    """
    Add a cache-busting stamp parameter to a URL, preserving existing query params.

    Args:
        url (str): The original URL.
        key (str): The query parameter name to use (default: "t").

    Returns:
        str: The URL with the stamp parameter added or replaced.
    """
    # Parse the URL into components
    parsed = urlparse(url)
    # Parse existing query string into list of (k,v)
    query_params = dict(parse_qsl(parsed.query))
    # Generate unique stamp
    stamp_val = f"{int(time.time())}-{random.randint(1000,9999)}"
    # Add/overwrite the stamp
    query_params[key] = stamp_val
    # Rebuild the URL
    new_query = urlencode(query_params)
    new_url = urlunparse(parsed._replace(query=new_query))
    return new_url

def get_feed(url, feed_settings):
    headers={
        # ask CDNs to revalidate; some honor this:
        "Cache-Control": "no-cache",
        "Pragma": "no-cache",
        "Accept": "application/rss+xml,application/xml;q=0.9,*/*;q=0.8",
    }
    if feed_settings.get('cache_stamp'):
        url = add_stamp(url)
    try:
        resp = cf.get(
            url,
            impersonate="chrome",
            timeout=20,
            headers=headers
        )
        resp.raise_for_status()
        parsed = feedparser.parse(resp.text)
    except Exception as exc:
        logger.error(f"Error fetching {url}: {exc}")
        return

    size_mb = f"{round(len(resp.content) / (1024 * 1024), 2)} MiB"
    num_ents = len(parsed.entries)
    logger.info(f"Retrieved {size_mb} in {round(resp.elapsed, 2)}s ({num_ents} entries)")

    domain = tldextract.extract(url).registered_domain

    for entry in parsed.entries:
        if link := entry.get("link"):
            entry['link'] = normalize_url(entry['link'])
        else:
            logger.warning(f'Skipping item from {domain} (no link)')

        yield entry

######################################################################

def get_id(item):
    normalize_url(item['link'])

def main():
    logger.info(__name__)
    ##################################################################
    auth = (settings.opensearch_user, settings.opensearch_pass)
    index_name = settings.opensearch_index_name
    os_client = OpenSearch(
        hosts=[{
            'host': settings.opensearch_host,
            'port': settings.opensearch_port
        }],
        http_auth=auth,
        use_ssl=settings.opensearch_use_ssl,
        verify_certs=False,
        ssl_assert_hostname=False,
        ssl_show_warn=False
    )

    while True:
        try:
            logger.info(auth)
            os_client.indices.exists(index=index_name)
            break
        except osp.exceptions.ConnectionError as exc:
            logger.warning(exc)
        except osp.exceptions.AuthenticationException as exc:
            logger.warning(exc)
        time.sleep(5)

    if not os_client.indices.exists(index=index_name):
        response = os_client.indices.create(
            index=index_name,
            body={}
        )

    index = os_client.indices.get(index=index_name)

    ##################################################################
    feeds_json = os.environ.get('RTO_FEEDS_JSON_PATH')
    feeds_json = Path(settings.feeds_json_path)
    if not feeds_json.is_file():
        logger.error(f"Couldn't find file `{feeds_json}`.")

    with open(feeds_json, "r") as fp:
        feeds = json.loads(fp.read())

    ##################################################################

    counter = 0
    for url, prefs in feeds.items():
        logger.info(f"{counter:4}: {url}")
        counter += 1
        feed_domain = tldextract.extract(url).registered_domain
        num_added_domain = 0
        num_dupes_domain = 0
        num_other_domain = 0
        for item in get_feed(url, prefs):
            item_id = item['link']
            doc_exists = os_client.exists(index=index_name, id=item_id)
            if doc_exists:
                num_dupes_domain += 1
                continue

            now = dt.datetime.now().isoformat(timespec='seconds')
            data = {
                "body": item,
                "domain": feed_domain,
                "dtg": now
            }
            resp = os_client.index(
                index=index_name,
                body=data,
                id=item_id,
                refresh=True
            )
            if resp.get("result") == "created":
                num_added_domain += 1
            else:
                num_other_domain += 1

            # endfor


        logger.info(f"Added: {num_added_domain}")
        logger.info(f"Dupes: {num_dupes_domain}")
        logger.info(f"Other: {num_other_domain}")

    wait_with_progress(60*30, 30)
