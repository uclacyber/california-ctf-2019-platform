#!/bin/sh
set -eo pipefail

WORKERS=${WORKERS:-1}
WORKER_CLASS=${WORKER_CLASS:-geventwebsocket.gunicorn.workers.GeventWebSocketWorker}
ACCESS_LOG=${ACCESS_LOG:--}
ERROR_LOG=${ERROR_LOG:--}

# Check that a .ctfd_secret_key file or SECRET_KEY envvar is set
if [ ! -f .ctfd_secret_key ] && [ -z "$SECRET_KEY" ]; then
    echo "[INFO] No secret key found. One will be generated for you." >&2
    dd if=/dev/urandom of=./.ctfd_secret_key bs=64 count=1
fi

# Check that the database is available
if [ -n "$DATABASE_URL" ]
    then
    url=`echo $DATABASE_URL | awk -F[@//] '{print $4}'`
    database=`echo $url | awk -F[:] '{print $1}'`
    port=`echo $url | awk -F[:] '{print $2}'`
    echo "Waiting for $database:$port to be ready"
    while ! mysqladmin ping -h "$database" -P "$port" --silent; do
        # Show some progress
        echo -n '.';
        sleep 1;
    done
    echo "$database is ready"
    # Give it another second.
    sleep 1;
fi

# Initialize database
python manage.py db upgrade

# Start CTFd
echo "Starting CTFd"
exec gunicorn 'CTFd:create_app()' \
    --bind '0.0.0.0:8000' \
    --workers $WORKERS \
    --worker-class "$WORKER_CLASS" \
    --access-logfile "$ACCESS_LOG" \
    --error-logfile "$ERROR_LOG"
