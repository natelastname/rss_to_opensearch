# RSS to OpenSearch

Transform and transport your RSS feeds seamlessly into OpenSearch with our powerful and flexible tool.

## 🚀 Project Overview

**RSS to OpenSearch** is designed to efficiently ingest, parse, and publish RSS feed data into OpenSearch, enabling real-time search and analytics capabilities. This project leverages modern cloud infrastructure to ensure scalability, security, and reliability.

## ✨ Features

- **Ingest RSS Feeds**: Automatically fetch and process RSS feeds.
- **Data Transformation**: Parse and transform feed data for optimal storage and retrieval.
- **OpenSearch Integration**: Seamlessly publish data to OpenSearch for enhanced search capabilities.
- **Infrastructure as Code**: Utilize Terraform for automated, scalable infrastructure deployment.
- **CI/CD Pipelines**: Automated testing and deployment for continuous integration and delivery.

## 🛠️ Technology Stack

- **Programming Language**: Python
- **Infrastructure**: Terraform, AWS (EC2, ECR, IAM)
- **Search Engine**: OpenSearch
- **Package Management**: Poetry
- **CI/CD**: GitHub Actions

## 📦 Setup Instructions

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/yourusername/rss_to_opensearch.git
   cd rss_to_opensearch
   ```

2. **Install Dependencies**:
   ```bash
   poetry install
   ```

3. **Configure Environment Variables**:
   Ensure all necessary environment variables are set, such as AWS credentials and OpenSearch configurations.

4. **Deploy Infrastructure**:
   Navigate to the `infra` directory and apply Terraform configurations:
   ```bash
   cd infra
   terraform init
   terraform apply
   ```

## 📄 Usage

Run the main module to start processing RSS feeds:
```bash
python -m src.rss_to_opensearch
```

## 🌟 Extending the Project

This project can be extended to support additional data sources beyond RSS feeds, such as JSON or XML APIs. It can also be adapted to integrate with other search engines or data storage solutions, providing flexibility for various use cases.

## 📚 Documentation

Detailed documentation and deployment procedures are available in the `infra` subdirectories, including `ec2-deploy` and `cicd`.

## 📝 TODO

- Remove hard-coded ECR image in `./infra/ec2-deploy/files/docker-compose.yml`
- Implement additional data source support
- Enhance error handling and logging mechanisms

## 🤝 Contributing

We welcome contributions! Please read our [contributing guidelines](CONTRIBUTING.md) for more details.

## 📧 Contact

For questions or support, please contact [yourname@domain.com](mailto:yourname@domain.com).
