#!/bin/bash

docker run --rm \
    --volume "$(pwd):/package" \
    --workdir "/package" \
    --env TEST_ENV_VAR=varval \
    swift:5.1 \
    /bin/bash -c "swift package resolve && swift test --parallel --build-path ./.build/linux"

