#!/bin/bash

exec 0</dev/rfcomm0
exec 1</dev/rfcomm0
exec 2</dev/rfcomm0

exec /bin/bash -l