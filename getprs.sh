#!/bin/bash -e

for number in `git log --pretty=oneline $2...$3 | grep "Merge pull request" | awk '{print $5}' | sed 's/#//' | sort`; do
  title=`curl -s -u "$1" https://api.github.com/repos/cloudfoundry/cf-for-k8s/pulls/${number} | jq . | jq .title`
  url=`curl -s -u "$1" https://api.github.com/repos/cloudfoundry/cf-for-k8s/pulls/$number | jq . | jq .html_url`
  echo "- $title [$number]($url)"
done
