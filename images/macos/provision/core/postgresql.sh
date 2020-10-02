#!/bin/bash -e

#Install latest version of postgresql
brew install postgres

#Service postgresql should be started before use.
brew services start postgresql

echo "Check PostgreSQL service is running"
i=10
COMMAND='brew services list | grep "postgresql started"'
while [ $i -gt 0 ]; do
    echo "Check PostgreSQL service status"
    eval $COMMAND && break
    ((i--))
    if [ $i == 0 ]; then
        echo "PostgreSQL service not started, all attempts exhausted"
        exit 1
    fi
    echo "PostgreSQL service not started, wait 10 more sec, attempts left: $i"
    sleep 10
done

#Verify that PostgreSQL is ready for accept incoming connections.
# exit codes:
# ready - 0
# reject - 1
# connection timeout - 2
# incorrect credentials or parameters - 3
pg_isready

#Stop postgresql
brew services stop postgresql