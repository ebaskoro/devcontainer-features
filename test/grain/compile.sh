#!/bin/bash

set -e

source dev-container-features-test-lib

echo 'print("Hello World");' >> hello.gr

check "Compiles" grain hello.gr