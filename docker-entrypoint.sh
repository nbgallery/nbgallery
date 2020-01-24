#!/bin/bash

# Wait until mysql is up and available, retrying 10 times with a 5 second wait
MAX_TRIES=10
TRIES=0
WAIT_SECONDS=5
until [ ${TRIES} -ge ${MAX_TRIES} ]
do
    TRIES=$[${TRIES}+1]

    if mysqladmin ping --host=${GALLERY__MYSQL__HOST} --port=${GALLERY__MYSQL__PORT} \
        --user=${GALLERY__MYSQL__USERNAME} --password=${GALLERY__MYSQL__PASSWORD}; then
        echo "MySQL service at ${GALLERY__MYSQL__HOST}:${GALLERY__MYSQL__PORT} was found to be UP on ${TRIES} of ${MAX_TRIES} tries. Continuing..."
        break
    else
        echo "MySQL service at ${GALLERY__MYSQL__HOST}:${GALLERY__MYSQL__PORT} was found to be DOWN on ${TRIES} of ${MAX_TRIES} tries. Retrying..."
    fi

    sleep ${WAIT_SECONDS}
done

# Once mysql is up, create the database if it doesn't exist
echo "Creating database ${GALLERY__MYSQL__DATABASE} if it doesn't exist on ${GALLERY__MYSQL__HOST}"
mysql -h${GALLERY__MYSQL__HOST} -p${GALLERY__MYSQL__PORT} -u${GALLERY__MYSQL__USERNAME} -p"${GALLERY__MYSQL__PASSWORD}" \
    -e "CREATE DATABASE IF NOT EXISTS ${GALLERY__MYSQL__DATABASE}"

# Wait until the database has been created before starting the rest of the services, retrying 10 times with a 5 second wait
MAX_TRIES=10
TRIES=0
WAIT_SECONDS=5
until [ ${TRIES} -ge ${MAX_TRIES} ]
do
    TRIES=$[$TRIES+1]

    FOUND_DB=`mysqlshow --host=${GALLERY__MYSQL__HOST} --user=${GALLERY__MYSQL__USERNAME} \
        --password=${GALLERY__MYSQL__PASSWORD} ${GALLERY__MYSQL__DATABASE}| grep -v Wildcard \
        | grep -o ${GALLERY__MYSQL__DATABASE}`

    if [ "$FOUND_DB" == "${GALLERY__MYSQL__DATABASE}" ]; then
        echo "Database ${GALLERY__MYSQL__DATABASE} found on try ${TRIES} of ${MAX_TRIES}. Continuing to startup services..."
        break
    else
        echo "Database ${GALLERY__MYSQL__DATABASE} NOT found on try ${TRIES} of ${MAX_TRIES}"
    fi

  sleep ${WAIT_SECONDS}
done

if [ -z "$SECRET_KEY_BASE" ]; then
  export SECRET_KEY_BASE=`bundle exec rake secret | grep -v Loading`
fi
bundle exec rake db:migrate
bundle exec rake assets:precompile
bundle exec rake create_default_admin
bundle exec rails server -b 0.0.0.0
