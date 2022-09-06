#!/bin/bash
podman image build --squash-all -f Containerfile -t localhost/vrising-cutting-edge
