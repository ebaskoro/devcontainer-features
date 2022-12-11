#!/bin/bash

set -e

source dev-container-features-test-lib

check "SBT installed" sbt --version

reportResults