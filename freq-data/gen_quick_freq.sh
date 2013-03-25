#!/bin/bash

# © 2013 Anthony Wong <anthony.wong@ubuntu.com>
# License: BSD

# Usage: gen_quick_freq.sh < <cangjie_input_file>
#   e.g. gen_quick_freq.sh < cj5-tc.txt

start=0
declare -a big5words
declare -a utf8words

function proc()
{
while read line; do
    [ x"$line" = "x" -o x${line:0:1} = "x#" ] && continue
    if [ $start -eq 0 ]; then
        [ "$line" = "[DATA]" ] && start=1
        continue
    fi
    code=`echo "$line" | awk '{ print $1 }'`
    char=`echo "$line" | awk '{ print $2 }'`
    if [ `echo -n $code | wc -c` -eq 1 ]; then
        newcode=$code
    else
        f=${code:0:1}
        l=${code: -1:1}
        newcode=$f$l
    fi

    big5=`echo -n "$char" | iconv -f utf-8 -t big5`
    if [ $? -eq 0 ]; then
        # Can convert the code to big5
        big5codestr=`echo -n $big5 | xxd -p`
        if [ ${big5codestr:0:2} = "a1" -o ${big5codestr:0:2} = "a2" -o ${big5codestr:0:2} = "a3" ]; then
            echo "${newcode} 1 ${char} ffff"
        else
            echo "${newcode} 1 ${char} ${big5codestr}"
        fi
    else
        # Can't convert the code to big5
        echo "${newcode} 1 ${char} ffff"
    fi
done 
}

lastcj="z"
proc | sort -d -k1,4 | while read line; do
    cj=`echo "$line" | awk '{ print $1 }'`
    char=`echo "$line" | awk '{ print $3 }'`
    big5code=`echo "$line" | awk '{ print $4 }'`
    if [ $cj != $lastcj ]; then
        freq=500
        lastcj=$cj
    else
        freq=$(($freq - 5))
    fi
    [ ${big5code} = "ffff" ] && freq=10
    /bin/echo -e "${cj}\t${char}\t${freq}"
done
