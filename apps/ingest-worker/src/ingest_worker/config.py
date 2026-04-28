from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_prefix="", extra="ignore")

    log_level: str = Field("info", validation_alias="LOG_LEVEL")

    vector_db_address: str = Field(
        "qdrant.qdrant.svc.cluster.local:6334",
        validation_alias="VECTOR_DB_ADDRESS",
    )
    vector_db_collection: str = Field(
        "documents", validation_alias="VECTOR_DB_COLLECTION"
    )

    embedder_endpoint: str = Field(
        "http://embedder.ml.svc.cluster.local/embed",
        validation_alias="EMBEDDER_ENDPOINT",
    )
    embedder_batch_size: int = Field(32, validation_alias="EMBEDDER_BATCH_SIZE")

    mlflow_tracking_uri: str = Field(
        "http://mlflow.mlops.svc.cluster.local:5000",
        validation_alias="MLFLOW_TRACKING_URI",
    )
    mlflow_experiment: str = Field(
        "rag-ingest", validation_alias="MLFLOW_EXPERIMENT"
    )

    chunk_size: int = Field(800, validation_alias="CHUNK_SIZE")
    chunk_overlap: int = Field(100, validation_alias="CHUNK_OVERLAP")
