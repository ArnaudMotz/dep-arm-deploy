#!/bin/sh
set -e

zypper install -y docker
chkconfig --set docker on
service docker start