#!/bin/bash
# Script to convert objdump -D output to "\xZZ" format
# using an optional/customized value to concatenation
#
# Version: 0.5b - Release Date: 2011-03-17
#  - Fix for instructions 6 bytes long
# Version: 0.4b - Release Date: 2010-07-02
#
# Written by: Flavio do Carmo Junior aka waKKu @ DcLabs

function usage() {
        echo "Written by: Flavio do Carmo Junior aka waKKu"
        echo
        echo "Usage: %0 <object file> [#columns|rawfile] [concat]"
        echo "1:"
        echo -e "\t[#columns] -> defaults to 16"
        echo -e "\t[concat] -> defaults to empty (C syntax)"
        echo
        echo -e "\tIn order to use a [concat] you must provide [#columns]"
        echo -e "\tExample: $0 shell.o 8 . # Perl syntax"
        echo -e "\tExample: $0 shell.o 12 ' + \\\\' # Python syntax with spaces"
        echo
        echo "2:"
        echo -e "\t[rawfile] -> creates a RAW file with the shellcode (if the"
        echo '                  file already exists, it will be truncated)'
        echo
        echo -e "\tExample: $0 shell.o shell.bin"
        echo
}

if [ $# -lt 1 ]; then
        usage
        exit 1
fi

if [ -e $1 ]; then
        FileName="$1"
elif [ -e "${PWD}/$1" ]; then
        FileName="${PWD}/$1"
else
        echo "$1: File not found."
        exit 2
fi

if ! [[ "$(file -i ${FileName})" =~ "application/x-object" ]]; then
        echo "${FileName}: is not a valid x-object file."
        exit 3
fi

# Variables
NumColumns=${2:-16}
ShellCode=($(objdump -D ${FileName} | sed '{/[0-9a-f]:/!d}' | cut -c7-23))
SCLength=${#ShellCode[@]}
ConcatChar="$3"

function printsc() {
        echo -n '"'
        count=0
        while [ $count -lt ${SCLength} ]; do
                if [ ${count} -ne 0 ] && [ $((${count} % ${NumColumns})) -eq 0 ]; then
                        echo -en "\"${ConcatChar} \n\""
                fi
                echo -n "\\x${ShellCode[${count}]}"
                let count+=1
        done
        echo "\""
}

function nullcheck() {
        #Check for NULL Bytes
        if [[ "${ShellCode[@]}" =~ "00" ]]; then 
                NullBytes=$(grep -o '00' <<< "${ShellCode[@]}" | wc -l)
                echo "***** NULL BYTE FOUND (${NullBytes}) *****" >&2
        else 
                NullBytes=0
                echo "ShellCode is clean (0 nulls)" >&2
        fi
}

# Main Function
nullcheck
if ! [[ "${NumColumns}" =~ "[[A-Za-z.]" ]]; then
        echo -e "Using ${NumColumns} opcodes/line\n" >&2
        echo "// ShellCode -> [ 'File:$(basename ${FileName})',
'Size:${SCLength} bytes', 'NULLs: ${NullBytes}' ]"
        printsc
        echo >&2
else
        OutFile=${NumColumns}
        NumColumns=16
        printsc
        printf "\\x$(sed -r 's/ +/\\x/g' <<<${ShellCode[@]})" > ${OutFile}
        echo
        echo "ShellCode generated to file: ${OutFile}"
        echo "ShellCode Size: ${SCLength} bytes"
        echo "NULL Bytes Found: ${NullBytes}"
fi
