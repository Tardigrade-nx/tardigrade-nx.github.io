#!/bin/bash

# mulren.sh v1.1
# Multiple-file renaming tool for bash
# Coded by Mia (http://beyondds.free.fr)

# Init counter <Cx-y-z> with x=start, y=step, z=nbDigits
init_counter()
{
  MR_COUNTER=""
  # Extract counter <Cx-y-z> if any
  MR_TEMP=`expr "$MR_PATTERN" : '.*\(<C[0-9]*-[0-9]*-[0-9]*>\)'`
  if [ -n "$MR_TEMP" ]
  then
    # There is a counter specified
    # Remove <C   >
    let "MR_LEN=${#MR_TEMP}-3"
    MR_TEMP="${MR_TEMP:2:MR_LEN}"
    # Extract the 3 parameters of the counter
    MR_COUNTER=(`echo $MR_TEMP | tr '-' ' '`) 
  fi
}

# Build new name for a given file and pattern
new_name ()
{
  MR_NEW_NAME_REPLY=""
  MR_PATTERN_TEMP="$MR_PATTERN"
  # Loop through every segment (text or token) of the pattern
  while [ -n "$MR_PATTERN_TEMP" ]
  do
    MR_FILE_NAME=${MR_FILE%.*}
    # Extract text at the beginning, if any
    MR_TEMP=`expr "$MR_PATTERN_TEMP" : '\([^<>]*\)'`
    if [ -z "$MR_TEMP" ]
    then
      # First segment is a token => extract it
      MR_TEMP=`expr "$MR_PATTERN_TEMP" : '\(<[^<>]*>\)'`
      if [ -z "$MR_TEMP" ]
      then
        echo "Invalid Pattern!"
        exit 1
      fi
      # Replace token by the corresponding text
      case "$MR_TEMP" in
        "<N>" )
          # Replace <N> by the file name without extension
          MR_NEW_NAME_REPLY="$MR_NEW_NAME_REPLY$MR_FILE_NAME"
          ;;
        "<E>" )
          # Replace <E> by the extension, if any
          MR_EXTENSION="${MR_FILE##*.}"
          if [ "$MR_FILE" != "$MR_EXTENSION" ]
          then
            # There is an extension
            MR_NEW_NAME_REPLY="$MR_NEW_NAME_REPLY$MR_EXTENSION"
          fi
          ;;
        \<N*-*\> )
          # Replace <Nx-y> with the corresponding substring
          # Get position 1 (x)
          MR_POS1=${MR_TEMP#\<N}
          MR_POS1=${MR_POS1%\-*}
          # Default = 1
          [ -z "$MR_POS1" ] && MR_POS1=1
          # The user starts at 1
          let "MR_POS1-=1"
          # Get position 2 (y)
          MR_POS2=${MR_TEMP#*\-}
          MR_POS2=${MR_POS2%\>}
          # Default = last character
          [ -z "$MR_POS2" ] && MR_POS2=${#MR_FILE_NAME}
          # The user starts at 1
          let "MR_POS2-=1"
          # Check the two positions
          if [ $MR_POS1 -gt $MR_POS2 ] || [ $MR_POS1 -ge ${#MR_FILE_NAME} ] || [ $MR_POS2 -ge ${#MR_FILE_NAME} ] || [ $MR_POS1 -lt 0 ] || [ $MR_POS2 -lt 0 ]
          then
            echo "Token out of range: $MR_TEMP"
            exit 1
          fi
          # Perform the operation
          let "MR_LEN=$MR_POS2-$MR_POS1+1"
          MR_NEW_NAME_REPLY="${MR_NEW_NAME_REPLY}${MR_FILE_NAME:MR_POS1:MR_LEN}"
          ;;
        \<C*-*-*\> )
          # Replace <Cx-y-z> with the corresponding counter
          # If MR_COUNTER was not initialized, then the counter is invalid
          if [ -z "$MR_COUNTER" ]
          then
            echo "Invalid counter: $MR_TEMP"
            exit 1
          fi
          # Perform the operation
          MR_NEW_NAME_REPLY="$MR_NEW_NAME_REPLY"`printf "%0${MR_COUNTER[2]}d" ${MR_COUNTER[0]}`
          # Increment the counter
          let "MR_COUNTER[0]+=MR_COUNTER[1]"
          ;;
        \<R*/*\> )
          # Replacement <Rx/y>
          # Get x and y
          MR_POS1=${MR_TEMP#\<R}
          MR_POS1=${MR_POS1%\/*}
          MR_POS2=${MR_TEMP#*\/}
          MR_POS2=${MR_POS2%\>}
          # Check x
          if [ -z "$MR_POS1" ]
          then
            echo "Invalid replacement: $MR_TEMP"
            exit 1
          fi
          # Perform operation
          MR_FILE="${MR_FILE//$MR_POS1/$MR_POS2}"
          ;;
        \<U\> )
          # To upper case
          MR_FILE=`echo "$MR_FILE" | tr '[:lower:]' '[:upper:]'`
          ;;
        \<L\> )
          # To lower case
          MR_FILE=`echo "$MR_FILE" | tr '[:upper:]' '[:lower:]'`
          ;;
        * )
          echo "Unkown token: $MR_TEMP"
          exit 1      
          ;;      
      esac
    else
      # First segment is text => concat it to new name
      MR_NEW_NAME_REPLY="$MR_NEW_NAME_REPLY$MR_TEMP"
    fi
    # Remove segment from pattern
    MR_PATTERN_TEMP=${MR_PATTERN_TEMP:${#MR_TEMP}}
  done
}

# Check whether every output name is unique, exit if not
check_output_files ()
{
  if [ ${#MR_OUTPUT_FILES[*]} -gt 1 ]
  then
    # Check needed
    MR_I=0
    let "MR_LIMIT=${#MR_OUTPUT_FILES[*]}-1"
    while [ $MR_I -lt $MR_LIMIT ]
    do
      let "MR_J=$MR_I+1"
      while [ $MR_J -le $MR_LIMIT ]
      do
        if [ "${MR_OUTPUT_FILES[MR_I]}" = "${MR_OUTPUT_FILES[MR_J]}" ]
        then
          echo "Some output files are identical! Please modify pattern."
          exit 1
        fi
        let "MR_J+=1"
      done
      let "MR_I+=1"
    done
  fi
}

# Check that there are at least 2 arguments (the pattern and one or more files)
if [ $# -lt 2 ]
then
  echo
  echo "Usage: `basename $0` \"pattern\" file1 file2 etc."
  echo
  echo "Pattern can contain text and special tokens:"
  echo
  echo "<N>      Name of the file without extension."
  echo "<E>      Extension of the file (if any)."
  echo "<Nx-y>   Substring of the file name from position x to y."
  echo "<Nx->    Substring of the file name from position x to the end."
  echo "<N-y>    Substring of the file name from the start to position y."
  echo "<Cx-y-z> Counter with x=start, y=step, z=nbDigits."
  echo "         Only one counter is allowed."
  echo "<Rx/y>   Replace all x with y in the original file name."
  echo "<Rx/>    Remove all x in the original file name."
  echo "<U>      Convert original file name to upper case."
  echo "<L>      Convert original file name to lower case."
  echo
  exit 1
fi

# Save pattern
MR_PATTERN="$1"
# Remove the pattern from the list of arguments
shift
# Init counter, if any
init_counter
# Loop through all files and compute new name
MR_I=0
for MR_FILE in "$@"
do
  new_name
  MR_OUTPUT_FILES[$MR_I]="$MR_NEW_NAME_REPLY"
  let "MR_I+=1"
done 

# Display before / after names
echo
MR_I=0
for MR_FILE in "$@"
do
  echo "$MR_FILE -> ${MR_OUTPUT_FILES[MR_I]}"
  let "MR_I+=1"
done 
echo

# Make sure that every output name is unique
check_output_files

# Ask for confirmation
MR_NB_FILES_RENAMED=0
echo "Rename the files? [y/N]"
read MR_KEYPRESS
case "$MR_KEYPRESS" in
  "y" | "Y" )
    # Rename the files
    MR_I=0
    for MR_FILE in "$@"
    do
      mv "$MR_FILE" "${MR_OUTPUT_FILES[MR_I]}"
      [ $? -eq 0 ] && let "MR_NB_FILES_RENAMED+=1"
      let "MR_I+=1"
    done
    ;;
esac
echo "$MR_NB_FILES_RENAMED file(s) renamed."
