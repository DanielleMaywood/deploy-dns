#!/bin/sh

MATCHED=$(grep -E -i '^[A-Za-z0-9](?:[A-Za-z0-9\-]{0,61}[A-Za-z0-9])? (?:[a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}$' ./DOMAINS)
GIVEN=$(cat DOMAINS | tr -s '[:blank:]')

if test "$DOMAINS" != "$GIVEN_DOMAINS"
then
    exit 1
fi
