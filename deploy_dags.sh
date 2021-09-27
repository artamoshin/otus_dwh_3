#!/bin/bash
AIRFLOW_HOST=`cat terraform/airflow-vm-ip-address.txt`
scp dags/*.py ubuntu@$AIRFLOW_HOST:/home/airflow/dags
