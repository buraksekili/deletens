#!/usr/bin/env bash

set -e

while getopts p:n:a: flag
do
    case "${flag}" in
        p) port=${OPTARG};;
        n) namespace=${OPTARG};;
        a) address=${OPTARG};;
    esac
done

if [[ -z $namespace ]]
then
    echo "please specify namespace with -n argument" 1>&2
    exit 1 
fi

if [[ -z $port ]]
then
    port=8001
fi

if [[ -z $address ]]
then
    address=127.0.0.1
fi

check_executable() {
    printf 'checking for %s ... ' "$1"
    if ! [ -x "$(command -v $1)" ];
    then
        echo "$1 does not exists" 1>&2
        exit 1 
    fi
    echo "done"
}


check_executable kubectl
check_executable curl
check_executable jq

echo "namespace => $namespace"

# check k8s API
printf "checking k8s API => %s" "${address}:${port} ... "
curl -sS ${address}:${port}/api/  > /dev/null
echo "done"

# check if namespace exists
kubectl get namespaces $namespace

kubectl get namespaces $namespace -o json | jq '.metadata.finalizers = []' | jq '.spec = {"finalizers": []}' > temp.json

curl -k -sS -H "Content-Type: application/json" -X PUT --data-binary @temp.json ${address}:${port}/api/v1/namespaces/$namespace/finalize > /dev/null

rm temp.json || deleted=$?

if [[ $deleted -gt 0 ]]
then
    echo "couldn't delete temp.json"
fi
