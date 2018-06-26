#!/bin/bash
chmod a+w "`dirname $0`/libs/phpqrcode"
if [ -d "`dirname $0`/pdf" ]
then
    chmod a+w "`dirname $0`/pdf"
    find "`dirname $0`/pdf" -mindepth 1 -maxdepth 1 -type d -ctime +1 -exec rm -rf {} \;
fi