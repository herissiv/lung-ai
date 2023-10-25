#!/usr/bin/env bash

# read a folder with xml and dcm files (CT), create output as png and text file (csv format)

input="$1"
output="$2"

# input="./LIDC-IDRI-0001/01-01-2000-NA-NA-30178/3000566.000000-NA-03192/"

if [ -z "$input" ]; then
   echo "Error: no input provided"
   exit -1
fi

if [ -z "$output" ]; then
   echo "Error: no output provided"
   exit -1
fi

# is this a folder with CT data? Just count and continue
numDICOM=$(ls $input/*.dcm | wc -l)
echo "found $numDICOM dicom files..."
if [ $numDICOM -le 10 ]; then
   echo "Error: Not enough DICOM files in this folder $input"
   exit
fi


# find the xml file
xmlfile=$(ls $input/*.xml | head -1)
if [ -z "$xmlfile" ]; then
   echo "Error: no xml file found"
   exit -1
fi

echo "Start reading xml file $xmlfile"
xml_text=$(xml2 < "$xmlfile")

NoduleIDs=$(xml2 < "$xmlfile" | grep noduleID | cut -d'=' -f2 )

#O=$IFS
#IFS=$(echo -en "\n\b")
#for u in $NoduleIDs; do
#   echo "Process nodule $u"
#done
#IFS=$O

CurrentNoduleName=""
NoduleCounter=0
CurrentSOPInstanceUID=""
Coordinates=""
CurrentImage=""
number=0
O=$IFS
IFS=$(echo -en "\n\b")
for line in $(xml2 < "$xmlfile"); do
   if [[ "$line" == *"noduleID"* ]]; then
      # if we get a new nodule id we should save the old values first, and overwrite
      #if [ ! -z "$CurretNoduleName" ]; then
      #   # we find a new nodule, but we have already one from before!
      #	 echo " we have a new nodule, but one already exists"
      #fi

      # reset and start over
      CurrentNoduleName=""
      CurrentSOPInstanceUID=""
      CurrentImage=""
      Coordinates=""

      CurrentNoduleName=$(echo "$line" | cut -d'=' -f2)
      NoduleCounter=$((NoduleCounter+1))
      echo " we have a new nodule ID [$NoduleCounter]: $CurrentNoduleName"
   fi
   if [ ! -z "$CurrentNoduleName" ]; then
      # check for sopinstanceuid (identifies the file we need to look for)
      if [[ "$line" == *imageSOP_UID* ]]; then
         # if we have a new SOPInstanceUID and we have already Coordinates, save them into a text file
	 if [ ! -z "$Coordinates" ]; then
	    textfile_filename="$output/image_${CurrentSOPInstanceUID}.txt"
	    echo "$CurrentNoduleName,$CurrentSOPInstanceUID,$CurrentImage,$Coordinates" >> ${textfile_filename}
	 fi

         CurrentSOPInstanceUID=$(echo "$line" | cut -d'=' -f2)
	 echo "Found SOPInstanceuid: $CurrentSOPInstanceUID"
	 # now look for the DICOM file that has this as its SOPInstanceUID
	 for dcmfile in $(ls "$input"/*.dcm); do
	    # get the SOPInstanceUID for file 
	    currentSOP=$(dcmdump +P SOPInstanceUID "$dcmfile" | cut -d'[' -f2 | cut -d']' -f1)
	    if [ "$currentSOP" == "$CurrentSOPInstanceUID" ]; then
	       # convert this file to a new location (output folder)
	       newfilename="$output/image_${currentSOP}.png"
	       CurrentImage="$newfilename"
	       if [ ! -e "$newfilename" ]; then 
	         dcm2pnm +on2 "$dcmfile" "$newfilename"
	         echo " Found our DICOM file referenced as SOPInstanceUID in file: $dcmfile, write out as $newfilename"
	       fi
	    fi
         done
	 # reset the coordinates string so we can capture the new coordinates for this SOPInstanceUID
      	 Coordinates=""
      fi
      #
      # check now for coordinates (in pixel)
      #
      if [[ "$line" == *edgeMap/* ]]; then
      	 # get the coordinate
	 coord=$(echo "$line" | cut -d'=' -f2)
	 if [ -z "$Coordinates" ]; then
  	    Coordinates="$coord"
	 else
  	    Coordinates="${Coordinates};$coord"
	 fi
      fi
   fi

   number=$((number+1))
done
IFS=$O

