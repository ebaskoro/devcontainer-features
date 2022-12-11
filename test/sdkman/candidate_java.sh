#!/bin/bash

set -e

source dev-container-features-test-lib

check "Java installed" java --version

reportResults