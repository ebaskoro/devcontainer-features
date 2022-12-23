#!/bin/bash

set -e

source dev-container-features-test-lib

check "Grain installed" grain --version

reportResults