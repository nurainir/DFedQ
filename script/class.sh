####################################################################
#Script to divide multiple datasets based on class partition
# Author : Nur Aini Rakhmawati, August 4th, 2013 
# License : GPL
#input :
#argument1 = number of partition
#argument2 = strategy to compare entity with the triple
#		1 => entity could be matched either subject and object position, as a result the redundant triples arises
#		2 => entity is only compared with subject
#argument3 = result directory
#output : several chunks of the dataset 
####################################################################

part=$1
strategy=$2
resultdir=$3

#create result directory if not exist
if [ ! -d $resultdir ];
then
mkdir $resultdir
fi


function clean_up {

	rm /tmp/db
	exit $1
}

trap clean_up SIGHUP SIGINT SIGTERM

function partition()
{
strategy=$1
dataset=$2
partitionfile=$3

echo $2 $3
if [ $strategy == "1" ];
	then
		while read line
		do
			let totalline+=1
			entity=($line)
			grep "${entity[0]}" $dataset >> /tmp/part-${entity[1]}
			let finished=totalline%1000
			if [ $finished -eq 0 ];
				then
				echo "processed $totalline lines"
			fi
		done < $partitionfile
	else
	# consider entity only at subject position
	while read line
		do
			let totalline+=1
			entity=($line)
			grep -E "^<${entity[0]}" $dataset >> /tmp/part-${entity[1]}
			let finished=totalline%1000
			if [ $finished -eq 0 ];
				then
				echo "processed $totalline lines"
			fi
		done < $partitionfile
	fi


}


#concate DB 
i=0
> /tmp/db
while [ "$4" != "" ]; do
	sort -k 1,2 $4 >> /tmp/db
	uniq /tmp/db > /tmp/db1
	mv /tmp/db1 /tmp/db
	dbfile[$i]=$4
	((i++))
	
    shift
done

#put the triples to the related class
#but if there is any triples belong to more than class, record it
> /tmp/redundantclass
awk -v entity=" " -v foundtype=0 ' {
s=$1
p=$2
o=$3

if(tolower(p) == "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>") 
{
	n=split(o,a,"/")
	
	if (length(a[n])>2)
		classtemp = substr(a[n],0,length(a[n])-1)
	else
		classtemp = substr(a[n],0,length(a[n-1])-1)
	
	if (entity!=s || foundtype==0)
	{
		print s " " classtemp > "/tmp/class"
		foundtype=1
	}
	else if (foundtype==1)
		print s " " classtemp > "/tmp/redundantclass"
}	
else if(entity!=s)
	foundtype=0
entity=s

}' /tmp/db


sed -i 's/#/_/g' /tmp/class

j=0
while [ $j -ne $i ]; do
	echo "partition"
	partition $strategy ${dbfile[$j]} /tmp/class
	
((j++))	
done

>/tmp/classfreq
#remove redundant data
for filepart in /tmp/part-*
do
	fbname=`basename "$filepart"|sed 's/^.....//'`
	echo $fbname
	sort -u $filepart > $resultdir/$fbname.nt	
	wc -l $resultdir/$fbname.nt >> /tmp/classfreq
	rm $filepart
done

clean_up
