#!/bin/bash
set -e

dep ensure

bazel build //...