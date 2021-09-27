from datetime import timedelta
from decimal import Decimal
from typing import NamedTuple

import psycopg2
import requests
from airflow import DAG
from airflow.decorators import task
from airflow.hooks.base import BaseHook
from airflow.utils.dates import days_ago

OPENNOTIFY_API_URL = 'http://api.open-notify.org/iss-now.json'

CONNECTION_ID = 'analytics_db'
ANALYTICS_DB_DSN = BaseHook.get_connection(CONNECTION_ID).get_uri()


class ISSPosition(NamedTuple):
    timestamp: int
    latitude: Decimal
    longitude: Decimal


@task
def get_iss_position() -> ISSPosition:
    response = requests.get(url=OPENNOTIFY_API_URL)
    response.raise_for_status()
    body = response.json()
    return ISSPosition(
        timestamp=body['timestamp'],
        latitude=body['iss_position']['latitude'],
        longitude=body['iss_position']['longitude'],
    )


@task
def store_to_db(position: ISSPosition) -> None:
    with psycopg2.connect(ANALYTICS_DB_DSN) as connection:
        cursor = connection.cursor()
        cursor.execute(
            'INSERT INTO iss_position (timestamp, latitude, longitude) '
            'VALUES (%s, %s, %s)', position,
        )


with DAG(
        dag_id='get_iss_position',
        description="Получает положение Международной космической станции",
        schedule_interval='*/5 * * * *',
        start_date=days_ago(1),
        catchup=False,
        default_args={
            'retries': 4,
            'retry_delay': timedelta(seconds=30)
        }
) as dag:
    iss_position = get_iss_position()
    store_to_db(iss_position)
