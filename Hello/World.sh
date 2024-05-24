#!/bin/bash

echo
echo "Hello, World! When you see this message, the Linux Command Line Tools are working as expected!"
if ! [[ "$@" == "" ]]; then
    echo "This is script is ran with the following arguments: '$@'."
fi
echo