####################################################################
#Script to divide multiple datasets based on graph partition
# Author : Nur Aini Rakhmawati, August 1st, 2013 
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
s=$1
dataset=$2
partitionfile=$3

echo $s
if [ $s == "1" ];
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
			grep -E "^${entity[0]}" $dataset >> /tmp/part-$((entity[1]+1))
			let finished=totalline%1000
			if [ $finished -eq 0 ];
				then
				echo "processed $totalline lines"
			fi
		done < $partitionfile
	fi


}



#concate DB 
> /tmp/so
> /tmp/subject
i=0
while [ "$4" != "" ]; do
	awk -v s="x" '{ if ($3 ~ /^</)  
		{
			print $1 " " $3 >> "/tmp/so"
			if ($1 != s )  
			{
				print $1 >> "/tmp/subject" 
				s=$1
			
			}
		} 
		}
		'  $4 
	dbfile[$i]=$4
	((i++))
	
    shift
done

#sort by subject
sort -u -k 1,2 /tmp/so > /tmp/so1
mv /tmp/so1 /tmp/so

sort -u /tmp/subject > /tmp/subject1
awk '{print $0,NR}' /tmp/subject1 > /tmp/subject
rm /tmp/subject1


awk 'NR==FNR{subject[$1]=$2;next} {$1=subject[$1];$2=subject[$2]}1' /tmp/subject /tmp/so > /tmp/res
sort  -k 1n -k 2n /tmp/res > /tmp/res1
awk 'NF>1{print $0}' /tmp/res1 > /tmp/res
rm /tmp/res1

> /tmp/so
mv /tmp/subject /tmp/subjectref
awk -v s="x" '{
	if (NF>1) 
	{ print $0 >> "/tmp/so"
	  print $2,$1 >> "/tmp/so"
		if ($1 == s )
			print $2 >> "/tmp/subject"
		else
		{
			  print $1 >> "/tmp/subject"
			  print $2 >> "/tmp/subject"
	        	 s=$1
		}
		
		  	  	
	}
		}' /tmp/res 

sort -n -u /tmp/subject > /tmp/subject1
awk '{print $0,NR}' /tmp/subject1 > /tmp/subject
rm /tmp/subject1

#prepare subject reference
# 
awk 'NR==FNR{subject[$1]=$2;next} {$2=subject[$2]}1' /tmp/subject /tmp/subjectref > /tmp/subject1
##remove unused subjects
awk 'NF>1{print $0}' /tmp/subject1 > /tmp/subjectref
rm /tmp/subject1


awk 'NR==FNR{subject[$1]=$2;next} {$1=subject[$1];$2=subject[$2]}1' /tmp/subject /tmp/so > /tmp/res
sort  -k 1n -k 2n /tmp/res > /tmp/res1
edge=$((`wc -l < /tmp/res1`/2))
vertex=`tail -n 1 /tmp/res1 | awk '{print $1}'`
echo "$vertex $edge" > /tmp/res
 
awk -v s="x" '{
		if (NR ==1 )
		{
			printf "%d ", $2
			s =$1 	
		}
		else if ($1 == s )
			printf "%d ", $2
		else
{			s =$1 
			printf "\n%d ", $2
}
		}' /tmp/res1 >> /tmp/res

#ready for passing the file to METIS
sed -ie 's/ $//' /tmp/res
rm /tmp/res1 /tmp/rese

#METIS
gpmetis /tmp/res $part


paste /tmp/subjectref /tmp/res.part.$part | awk '{print $1,$3}' > /tmp/part
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
