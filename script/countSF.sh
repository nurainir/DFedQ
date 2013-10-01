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
datataset=0

#create result directory if not exist
if [ ! -d $NTdir ];
then
echo "can not find $1"
fi


function clean_up {

	rm /tmp/prop
	rm /tmp/class
	exit $1
}

trap clean_up SIGHUP SIGINT SIGTERM


#concate DB 
i=0
> /tmp/prop
> /tmp/class
for fileNT in $NTdir/*.nt
do
																																																						awk '{
s=$1
p=$2
o=$3
	#print p
	if(tolower(p) == "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>") 
	{
		listclass[o]=1
	}
	listprop[p]=1
 }
END{
	for(iclass in listclass)
{
	print iclass >> "/tmp/class"
}
	for(prop in listprop)
{
		print prop >> "/tmp/prop"

}


}' $fileNT
((dataset++))
done

sort /tmp/class | uniq -c > /tmp/OCC
sort /tmp/prop | uniq -c > /tmp/OCP

totalCD=`awk '{sum=sum+$1} END {print sum}' /tmp/OCC`
totalPD=`awk '{sum=sum+$1} END {print sum}' /tmp/OCP`

totalC=`wc -l < /tmp/OCC`
totalP=`wc -l < /tmp/OCP`


OCC=`echo "scale=2;$totalCD / ($totalC*$dataset)" | bc -l` 
OCP=`echo "scale=2;$totalPD / ($totalP*$dataset)" | bc -l` 

printf "%0.2f %0.2f" $OCC $OCP

> /tmp/idf
#calculate IDF of each property
awk -v db=$dataset '{
	print $2 " " $1/db >> "/tmp/idf"

}' /tmp/OCP

awk -v db=$dataset '{
	print $2 " " $1/db >> "/tmp/idf"

}' /tmp/OCC


mv /tmp/idf $2

