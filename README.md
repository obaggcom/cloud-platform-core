# Web Service Application

A lightweight, high-performance web service container optimized for cloud deployments.

## Features

- **High Performance**: Built on Alpine Linux for minimal footprint.
- **Scalable**: Ready for horizontal scaling on Northflank, Koyeb, Render, etc.
- **Monitoring**: Integrated system health monitoring agent.
- **Secure**: Default TLS support and WebSocket transport.

## Deployment

### Quick Start (Northflank / Koyeb / Render)

1.  **Fork** this repository.
2.  **Create Service**: Select "Web Service" or "Docker" deployment.
3.  **Configure Environment Variables**:

| Variable | Description | Default |
| :--- | :--- | :--- |
| `UUID` | Service ID (UUID format) | *(Auto-generated)* |
| `WSPATH` | WebSocket Endpoint Path | `/vless` |
| `PORT` | Service Port | `8080` |

### Monitoring Integration (Optional)

To enable the system monitoring agent, add the following variables:

| Variable | Description | Example |
| :--- | :--- | :--- |
| `NZ_SERVER` | Monitor Server Address | `monitor.example.com:8008` |
| `NZ_CLIENT_SECRET` | Client Secret Key | `your-secret-key` |
| `NZ_TLS` | Enable TLS for Monitor | `true` or `false` |

## Local Development

```bash
docker build -t web-service .
docker run -d -p 8080:8080 -e UUID=your-uuid web-service
```

## License

MIT License
