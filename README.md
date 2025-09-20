# rss_to_opensearch

A tool to transfer RSS feeds to OpenSearch.

## Features

- Ingests RSS feeds.
- Parses and transforms feed data.
- Publishes data to OpenSearch.

## Installation

Clone the repository and install dependencies using Poetry:
```bash
poetry install
```

## Usage

Run the main module:
```bash
python -m src.rss_to_opensearch
```

## Infrastructure

The deployment stack is built using Terraform for robust infrastructure-as-code implementations. This includes configurations for AWS services such as EC2, ECR, IAM, and more, ensuring a secure and scalable environment. Our CI/CD pipelines automate testing and deployments, reducing manual intervention and enhancing reliability. Detailed deployment procedures, including step-by-step instructions for scaling and troubleshooting, are available in the respective README files within the `infra` subdirectories (e.g., `ec2-deploy` and `cicd`).

## TODO
- Remove hard coded ECR image in `./infra/ec2-deploy/files/docker-compose.yml`
