####################################################################
#Script to count the frequency of properties
# Author : Nur Aini Rakhmawati, August 13th, 2013 
# License : GPL
#input :
#argument1 = directory dataset containing NT files
#argument2 = file result
#output : properties number of occurence
####################################################################

NTdir=$1


function clean_up {

	rm /tmp/db
	exit $1
}

trap clean_up SIGHUP SIGINT SIGTERM


#concate DB 
i=0
> /tmp/prop
while [ "$1" != "" ]; do

awk '{
prop[$2]++
 }
END{
for (p in prop)
	print p " " prop[p] >> "/tmp/prop"
}' $1
 shift
done

awk '{
prop[$1]=+$2
}END{
for (p in prop)
	print p " " prop[p] >> "/tmp/prop1"
}' /tmp/prop

mv /tmp/prop1 /tmp/prop


#integer programming

clean_up
