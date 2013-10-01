####################################################################
#Script to divide multiple datasets based on vertex partition
# Author : Nur Aini Rakhmawati, August 2st, 2013 
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

	rm /tmp/part*
	rm /tmp/so
	rm /tmp/subject*
	rm /tmp/res*
	exit $1
}

trap clean_up SIGHUP SIGINT SIGTERM

function partition()
{
strategy=$1
dataset=$2
partitionfile=$3


if [ $strategy == "1" ];
	then
		while read line
		do
			let totalline+=1
			entity=($line)
			grep "${entity[0]}" $dataset >> /tmp/part-$((entity[1]+1))
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
			grep -E "^<${entity[0]}" $dataset >> /tmp/part-$((entity[1]+1))
			let finished=totalline%1000
			if [ $finished -eq 0 ];
				then
				echo "processed $totalline lines"
			fi
		done < $partitionfile
	fi


}



#concate DB 
> /tmp/o
> /tmp/s
i=0
while [ "$4" != "" ]; do
	awk -v s="x" '{ if ($3 ~ /^</)  
		{
			if ($1 == s ) 			
				print $3 >> "/tmp/o"
			else 
			{
				print $1 >> "/tmp/s" 
				print $3 >> "/tmp/o"
				s=$1
			
			}
		} 
		}
		'  $4 
	dbfile[$i]=$4
	((i++))
	
    shift
done

#sort conenection S-O by subject
sort -u /tmp/s > /tmp/s1
sort -u /tmp/o > /tmp/o1
awk 'NR==FNR{a[$0]=$0;next}a[$0]' /tmp/s1 /tmp/o1 > /tmp/so
rm /tmp/s1 /tmp/s /tmp/o /tmp/o1

noentities=$((`wc -l < /tmp/so`/$part))
echo $noentities

awk -v no=0 -v max=$noentities -v part=0 '{if (no < max) 
	{ print $0,part
	  no++
	}
	else
	{
	 part++
	 no=0
	 print $0,part
	}
}' /tmp/so > /tmp/part
rm /tmp/so

j=0
while [ $j -ne $i ]; do
	echo "partition"
	partition $strategy ${dbfile[$j]} /tmp/part
	
((j++))	
done

#remove redundant data
j=1
while [ $j -le $part ]; do
	echo "sorting"
	sort -u /tmp/part-$j > $resultdir/$j.nt	
	rm /tmp/part-$j
((j++))	
done

clean_up
