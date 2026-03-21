# OrderFlow

A high-performance order processing system.

## Quick Start

Install dependencies and run:

```bash
pip install orderflow
```

```python
# VIOLATION DQV-01: Stale example — create_app() was renamed to initialize_app()
from orderflow import create_app

app = create_app()
app.run()
```

## Architecture

This project follows the CQRS pattern with event sourcing for all
write operations. The read model is eventually consistent via
projections.

<!-- VIOLATION DQV-07: "CQRS pattern" and "event sourcing" used without
     explanation or links. New developers cannot understand this section. -->

Commands are dispatched through the mediator and handled by
aggregate roots that emit domain events.

## API Reference

See [docs/api.md](docs/api.md) for endpoint documentation.

## Contributing

See [docs/architecture.md](docs/architecture.md) for architecture details.

<!-- VIOLATION DQV-02: Broken link — docs/architecture.md does not exist -->

## Development

```bash
python -m orderflow.server --port 8080
```

## License

MIT
