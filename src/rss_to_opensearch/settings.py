#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on 2025-09-04T17:40:27-04:00

@author: nate
"""
import json
import os
import sys
from typing import Optional

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """These parameters can be configured with environment variables."""

    """
    Pydantic does the following:

    1. Reads `.env` from project root
    2. Overwrites the corresponding attributes of this object

    Thus, the hardcoded values of this object are defaults that are
    overwritten if shadowed by an environment variable in `.env`.
    """
    model_config = SettingsConfigDict(
        env_file_encoding="utf-8",
        env_file=("./develop/.env", )
    )

    ##################################################################
    # Administration
    ##################################################################

    opensearch_host: str = "127.0.0.1"
    opensearch_index_name: str = "rss_to_opensearch"
    opensearch_pass: str = "admin"
    opensearch_port: str = "9200"
    opensearch_user: str = "admin"
    opensearch_use_ssl: bool = True
    feeds_json_path: str = "/opt/rss_to_opensearch/feeds.json"


settings = Settings()
