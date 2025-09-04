#!/usr/bin/env bash

PORT=4200

echo "Starting jank-nrepl-server…"
/app/build/jank-wrapper run-main nrepl-server.core &

echo "Waiting for nrepl server to be available…"
until nc -z localhost $PORT; do
    sleep 1
done

echo "Starting rebel-readline…"
clojure -Sdeps "{:deps {com.bhauman/rebel-readline-nrepl {:mvn/version \"0.1.6\"}}}" -M -m rebel-readline.nrepl.main -p $PORT
