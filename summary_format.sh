grep -v R */Summary.txt|sed 's/\s(/(/g'|sed 's/\/Summary.txt:/\t/'|sed 's/\s\+/\t/g'
