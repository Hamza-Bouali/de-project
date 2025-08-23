# de-project

A small data engineering repository that contains Kestra orchestration flows, Python pipeline code, helper scripts and Terraform examples used to build a NYC taxi ingestion pipeline (Postgres / S3 / Redshift).

This README explains the project layout, how to run things locally, how flows are organized and what to configure before deploying to Kestra or AWS.

## Checklist (what I'll cover)

- Describe repository contents and purpose
- Quickstart: local (venv) and Docker
- Explain Kestra flows and `taks.yaml` (inputs, triggers, tasks)
- Environment variables / secrets to configure
- Scripts, Terraform and maintenance notes

## Repository layout

- `flows/` — Kestra YAML flows. These orchestrate download → transform → upload → load tasks. Filenames include scheduled/backup/clean variants.
- `taks.yaml` — a representative Kestra flow (task definition) used for taxi ingestion (shows inputs, triggers, tasks and plugin defaults).
- `processing.ipynb` — exploratory notebook for data inspection and local testing.
- `create_flows.sh`, `update_flow.sh` — helper scripts to deploy flows to Kestra.
- `Dockerfile`, `docker-compose.yml` — container images and compose configuration for local or CI runs.
- `requirements.txt` — Python dependencies for local execution.
- `tf-tuto/` — Terraform code and state used to provision AWS resources referenced by some flows.

## What the flows do (high level)

The Kestra flows perform the typical ETL steps for NYC taxi data:

- Download parquet files from a public source (CloudFront URL).
- Convert parquet to CSV using a short Python step (pandas / pyarrow).
- Upload converted CSV to S3.
- Conditionally run Redshift COPY statements to load CSV into either the green or yellow tables depending on the `taxi` input.
- Clean up temporary files at the end of execution.

## Pipeline diagram

The following Mermaid diagram visualizes the `taks.yaml` flow: inputs, scheduled trigger, extraction, conversion, upload, conditional load to Redshift, and purge.

```mermaid
flowchart LR
	triggers[Triggers\n(monthly schedule)] --> inputs[Inputs\n(taxi, year, month)]
	inputs --> extract[Extract\n(wget parquet)]
	extract --> convert[Convert\n(parquet → CSV)\n(pandas, pyarrow)]
	convert --> upload[Upload to S3]
	upload --> branch{taxi == 'green'?}
	branch -->|green| redshift_green[Redshift COPY\n-> green_tripdata]
	branch -->|yellow| redshift_yellow[Redshift COPY\n-> yellow_tripdata]
	redshift_green --> purge[Purge temporary files]
	redshift_yellow --> purge
	convert --> purge
	classDef io fill:#f8f9fa,stroke:#333,stroke-width:1px
	class triggers,inputs,extract,convert,upload,branch,redshift_green,redshift_yellow,purge io
```

The `taks.yaml` flow demonstrates:

- Inputs: `taxi` (green|yellow), `year`, `month`.
- Triggers: monthly scheduled triggers to run the flow automatically.
- Use of variables and templating for filenames and runtime values.
- Tasks: shell download (`wget`), Python conversion, S3 upload, conditional Redshift loads, and a purge task.
- `pluginDefaults` preconfigured for Postgres, AWS and Redshift connections (replace defaults with your secrets in production).

## Quickstart — local (recommended for development)

Prerequisites: Python 3.10+ (the repo includes a venv created with Python 3.12), Docker optional.

1. Create and activate a virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
```

2. Install Python dependencies:

```bash
pip install -r requirements.txt
```

3. Run a local pipeline script to test configuration:

```bash
python main.py
# or
python pipeline.py
```

4. For exploratory work, open the Jupyter notebook:

```bash
pip install jupyterlab
jupyter lab processing.ipynb
```

## Quickstart — Docker

Build and start services defined in the repository (for example to run Postgres alongside the pipeline):

```bash
docker compose build
docker compose up
```

Review `docker-compose.yml` to see which services are created and to add or modify Postgres credentials used by local flows.

## Deploying Kestra flows

Use `create_flows.sh` or `update_flow.sh` to send your YAML flows to a Kestra server. Example usage:

```bash
./create_flows.sh          # push all flows to the configured Kestra instance
./update_flow.sh flows/02_postgres_taxi.yaml
```

Before running these scripts ensure the target Kestra URL and credentials are set in your environment or inside the scripts.

## Required environment variables / secrets

Flows expect connectivity to storage and databases. Typical environment variables to set before running flows are:

- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION` — for AWS plugin steps
- `PG_HOST`, `PG_PORT`, `PG_USER`, `PG_PASSWORD`, `PG_DATABASE` — Postgres connection used by some flows
- `REDSHIFT_USER`, `REDSHIFT_PASSWORD`, `REDSHIFT_HOST` — if you use the Redshift plugin
- Kestra server URL / token (if using `create_flows.sh` to push flows)

Note: `taks.yaml` includes `pluginDefaults` values. Replace any hard-coded values (URLs, passwords, IAM role ARNs) before deploying to production. Do not commit secrets to the repository.

## Important notes & security

- Several YAMLs include scheduled flows (filenames with `_scheduled.yaml`). Review schedule settings before deploying.
- There are backup and clean flows (`*_backup.yaml`, `*_clean.yaml`)—run them only after review and testing.
- The repository contains Terraform state under `tf-tuto/` — treat state files and `terraform_credentials.csv` as sensitive.

## Scripts and maintenance

- `create_flows.sh` — convenience script that pushes every YAML in `flows/` to Kestra.
- `update_flow.sh` — update a single flow file.
- `statup.sh` — startup helper script (file name contains a typo; inspect before use).

## Contributing

1. Fork the repository and create a feature branch.
2. Add tests or a short example for new behavior.
3. Open a pull request with a clear description and runtime impact.

## License

No license file is included. Add a `LICENSE` if you intend to publish this repo publicly with explicit licensing.

----

If you'd like, I can also:

- expand the README with per-flow environment variable lists (I can parse each flow to extract keys),
- add a small `docker-compose` example to run Postgres locally for testing flows, or
- generate a `.env.example` file from the variables referenced in `taks.yaml` and other flows.

Requirements coverage:

- Create a README based on the flows and repo: Done

