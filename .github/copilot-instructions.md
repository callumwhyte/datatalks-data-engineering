# AI Coding Instructions for datatalks-data-engineering

## Project Overview
A learning project for the 2026 DataTalks Data Engineering course. The codebase demonstrates containerized Python data pipelines using modern tooling (uv, pyproject.toml, Docker).

### Architecture
- **Root entry**: `main.py` - simple entry point for the project
- **Pipeline module**: `pipeline/` - containerized data processing pipeline that reads command-line arguments and produces Parquet output
- **Tests**: `test/` - utility scripts for exploration (currently contains data inspection tools)

## Critical Development Patterns

### Dependency Management
- Uses **uv** as the package manager (modern, fast Python package tool)
- Dependencies declared in `pipeline/pyproject.toml` (Python >=3.13)
- Lock file: `pipeline/uv.lock` ensures reproducible builds
- Core dependencies: pandas, pyarrow (for Parquet I/O)

### Containerization
- **Single-stage Dockerfile** in `pipeline/Dockerfile` uses multi-stage patterns
- `uv sync --locked` installs dependencies reproducibly
- Entry point: `python pipeline.py` expects day argument via `sys.argv[1]`
- Virtual environment added to PATH for seamless package access

### Pipeline Execution
- Pipeline takes positional integer argument: `python pipeline.py <day>`
- Process: read day argument → create sample DataFrame → output to `output_day_<N>.parquet`
- Pandas + PyArrow stack for data manipulation

## Workflow Commands
```bash
# Install dependencies using uv
uv sync

# Run pipeline locally with day argument
python pipeline/pipeline.py 1

# Build Docker image
docker build -t datatalks-pipeline pipeline/

# Run containerized pipeline
docker run datatalks-pipeline 15
```

## Key Conventions
1. **Parquet as output format**: Always use `.to_parquet()` for data persistence (Arrow-native)
2. **Argument passing**: Single integer day parameter via sys.argv[1]
3. **Lock-based reproducibility**: Always update `uv.lock` when adding dependencies
4. **Slim base image**: Docker uses `python:3.13.10-slim` for minimal footprint
5. **Module structure**: Each pipeline component gets its own directory with `pyproject.toml`

## Important Files
- [pipeline/pyproject.toml](pipeline/pyproject.toml) - dependency declarations
- [pipeline/pipeline.py](pipeline/pipeline.py) - core pipeline logic
- [pipeline/Dockerfile](pipeline/Dockerfile) - production container configuration
- [pipeline/uv.lock](pipeline/uv.lock) - locked dependency graph

## AI Agent Notes
- This is an early-stage learning project; focus on maintaining clean separation between root utilities and containerized pipeline logic
- When extending functionality, maintain Docker reproducibility by updating lock file
- Test changes both locally and in containerized environment before committing
