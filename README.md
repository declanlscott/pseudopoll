# PseudoPoll

## Technologies

- Infrastructure
  - Terraform IaC
  - Cloudflare
    - DNS
    - Pages
  - AWS
    - API Gateway v1
    - Lambda
    - DynamoDB
    - EventBridge
      - Event Bus
      - Pipe
    - SQS
    - IoT Core
    - CloudWatch
    - ACM
    - IAM
    - S3
- Backend
  - Lambdas written in Go
  - Microservices
    - Poll manager (REST API for CRUD operations)
    - Vote queue (queue-based load leveling)
    - Publisher (MQTT over WebSockets)
  - JWT authorization
  - DynamoDB for persistence (single-table design)
    - Streams for change events
  - Choreographed by EventBridge
  - OpenAPI 3.0 spec
- Frontend
  - TypeScript
  - Nuxt 3
    - Vue 3 Single Page Application (SPA)
    - Nitro server
      - Backend For Frontend (BFF)
      - Typesafe fetch client generated from OpenAPI spec
    - Edge-Side Rendering (ESR) via Cloudflare
  - Authentication via Google OAuth
  - Nuxt UI
    - Tailwind CSS

## Architecture

![Architecture Diagram](architecture.png)
