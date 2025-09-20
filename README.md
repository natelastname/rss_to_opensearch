# rss_to_opensearch

A tool to transfer RSS feeds to OpenSearch.

## Features

- Ingests RSS feeds.
- Parses and transforms feed data.
- Publishes data to OpenSearch.

## Installation

Clone the repository and install dependencies:
```bash
pip install -r requirements.txt
```

## Usage

Run the main module:
```bash
python -m src.rss_to_opensearch
```

## Infrastructure

Terraform and other infrastructure configuration is located in the `infra` directory.

## TODO
- Remove hard coded ECR image in `./infra/ec2-deploy/files/docker-compose.yml`
