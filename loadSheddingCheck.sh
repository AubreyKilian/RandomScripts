#!/bin/bash

log () {
        echo "`date`: $@" >> ${LOGFILE}
}

SMSCOMMAND=/home/aubrey/bin/httpsms
WORKINGDIR=$(dirname $0)
URL='https://www.capetown.gov.za/en/electricity/pages/loadshedding.aspx'
LOGFILE=$WORKINGDIR/loadshedding.log
TMPFILE=`mktemp /tmp/loadshedding.XXXXXX`

curl -m 30 -s -o ${TMPFILE} "$URL"
if ! [ "$?" == "0" ]; then
        log "Curl failed"
        exit
fi

# Ugly hack
STAGE=$(grep "ctl00_PlaceHolderMain_ctl01__ControlWrapper_RichHtmlField" ${TMPFILE} | sed -e 's/^.*<b>//; s/<\/b>.*$//;')
rm ${TMPFILE}

# Might use this later
SUSPENDED=$(echo $STAGE | grep SUSPENDED)

log $STAGE

# Lazy
touch $WORKINGDIR/loadshedding.current
touch $WORKINGDIR/loadshedding.last
mv $WORKINGDIR/loadshedding.current $WORKINGDIR/loadshedding.last
PREVIOUS=$(head -n1 $WORKINGDIR/loadshedding.last)
echo "$STAGE" > $WORKINGDIR/loadshedding.current

CHANGED=$(diff -q $WORKINGDIR/loadshedding.current $WORKINGDIR/loadshedding.last)
if ! [ "$CHANGED" = "" ]; then
        echo "Load shedding status changed from: $PREVIOUS to: $STAGE"
        cat $WORKINGDIR/recipients.list | while read NUMBER; do
                $SMSCOMMAND$NUMBER "Load shedding status changed from: $PREVIOUS to: $STAGE"
        done
fi

