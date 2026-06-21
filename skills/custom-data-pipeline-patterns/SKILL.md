---
name: custom-data-pipeline-patterns
description: Use for data engineering, ETL, pandas, SQL, notebooks, ML pipelines. Covers data inspection, pipeline design, notebook hygiene, property-based testing for transforms. Trigger on: data, pipeline, ETL, pandas, polars, SQL, notebook, Jupyter, ML, feature engineering, DataFrame.
---

# Data Pipeline Patterns

## Always inspect data before transforming

Before any transformation:
```python
print(df.shape)        # rows, columns
print(df.dtypes)       # column types
print(df.head())       # first rows
print(df.describe())   # summary stats
print(df.isnull().sum())  # null counts per column
```

Confirm your assumptions about the data. Never assume dtypes, ranges, or null patterns.

## Library selection

| Use case | Library |
|---|---|
| Tabular data, fits in memory | `pandas` |
| Larger-than-memory datasets | `polars` (lazy evaluation) |
| Database interaction | `SQLAlchemy` or `sqlmodel` |
| Never | Raw string-interpolated SQL (injection risk) |
| ML pipelines | `scikit-learn` pipelines, `mlflow` for tracking |
| Workflow orchestration | `Airflow` or `Prefect` (DAG-based, idempotent, retryable) |

## Notebook hygiene

- Clear output before committing (`jupyter nbconvert --clear-output --inplace`).
- Don't commit large data files. Use `.gitignore` for `data/`, `outputs/`, `*.csv`, `*.parquet`.
- Refactor long notebooks into modules. Notebooks are for exploration; modules are for production.
- Move imports to the top. Add type hints to functions.
- One logical cell = one cell. Don't mix unrelated operations.

## ML patterns

- Separate: data loading → preprocessing → model definition → training → evaluation.
- Never mix train and test data. Check for data leakage (temporal splits, group splits).
- Log metrics: train/val/test separately. Sanity-check (no unrealistically good results).
- Use `mlflow` or `wandb` for experiment tracking.

## Pipeline design

- **Idempotent** — running twice with the same input produces the same output.
- **Retryable** — transient failures (network, DB) should be retried with backoff.
- **Observable** — log progress, errors, metrics at each stage.
- **Testable** — each stage is a pure function that can be unit-tested independently.

## Property-based testing for transforms

Use `hypothesis` (Python):
```python
from hypothesis import given, strategies as st

@given(st.lists(st.integers(min_value=0), min_size=1))
def test_no_nulls_after_cleaning(values):
    df = pd.DataFrame({"value": values})
    result = clean_data(df)
    assert result["value"].isnull().sum() == 0
```

Properties to check:
- Output has no nulls in required columns.
- Output row count is consistent (e.g. dedup reduces or equals input count).
- Output values are within expected ranges.
- Monotonic transforms preserve ordering.
