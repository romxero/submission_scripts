#!/bin/bash 

# we are going to try and convert everythign to docx


function convert_to_docx() {
    local file=$1
    local docx_file=${file%.md}.docx
    echo "Converting $file to $docx_file"
    pandoc -s $file -o $docx_file
}


export -f convert_to_docx


find . -name "*.md" -print | xargs -P 8 -I '{}' bash -c 'convert_to_docx "{}"'

