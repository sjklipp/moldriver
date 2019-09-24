#!/bin/bash

numdist=9
dist1=1.8
dist2=2.1
dist3=2.4
dist4=2.6
dist5=2.8
dist6=3.0
dist7=3.2
dist8=3.4
dist9=10.0
numdirs=$(($numdist-1))

#exit

cp -R ref dist_$dist1
cd  dist_$dist1
sed -ie "s/STEPN/Step1/g" data/estoktp.dat
sed -ie "s/DISTN/$dist1/g" data/ts.dat
sed -ie "s/nGrid_Opt_ts/Grid_Opt_ts/g" data/estoktp.dat
sed -ie "s/nOpt_ts_1/Opt_ts_1/g" data/estoktp.dat
sed -ie "s/n1dTau_ts/1dTau_ts/g" data/estoktp.dat
sed -ie "s/nHL_ts/HL_ts/g" data/estoktp.dat
sed -ie "s/nSymm_ts/Symm_ts/g" data/estoktp.dat

runes2k

cd ..

#for npoint in $(seq "$numsite" )
#do

while true; do
    # flag represents if the app is ready, 1=ready, 0=not ready
    is_ready=0
    FILE=./dist_$dist1/finished
    if test -f "$FILE"; then
	echo "$FILE "
	is_ready=1
    fi
    FILE2=./dist_$dist1/failed
    if test -f "$FILE2"; then
        echo "$FILE2 "
        is_ready=2
    fi

   if [[ $is_ready -eq 2 ]]; then
        echo "Failed at Step 1"
        echo "stopping calculation"
        exit
   fi

    if [[ $is_ready -eq 1 ]]; then
        echo "Proceed to step 2"
        break
    else
        # idle for 60 seconds
        sleep 60
    fi
done

for npoint in $(seq "$numdirs" )
do
    nprog=$(($npoint+1))
    var="dist$nprog"
    name=dist_"${!var}"
    cp -R dist_$dist1 $name
    cp -f ref/data/estoktp.dat ./$name/data
    cp -f ref/data/ts.dat ./$name/data
    cd ./$name
    sed -ie "s/STEPN/Step2/g" data/estoktp.dat
    sed -ie "s/DISTN/${!var}/g" data/ts.dat
    sed -ie "s/nOpt_ts_1/Opt_ts_1/g" data/estoktp.dat
    sed -ie "s/n1dTau_ts/1dTau_ts/g" data/estoktp.dat
    sed -ie "s/nHL_ts/HL_ts/g" data/estoktp.dat
    sed -ie "s/nSymm_ts/Symm_ts/g" data/estoktp.dat
    rm -f ./finished
    rm -f ./failed
    if [[ $npoint -eq $numdirs ]]; then
	sed -ie "s/1dTau_ts/n1dTau_ts/g" data/estoktp.dat
	sed -ie "s/{frequencies;print,hessian}//g" output/ts_asl1_step2.inp
    fi
    runes2k
    cd ..
done

# now check if step2 calculations finished

while true; do
    # flag represents if the app is ready, 1=ready, 0=not ready
    is_ready=0
    numfinished=0
    for npoint1 in $(seq "$numdirs" )
    do
	nprog=$(($npoint1+1))
	var="dist$nprog"
	name=dist_"${!var}"
	FILE=./$name/finished
	if test -f "$FILE"; then
	    echo "$FILE "
	    is_ready=1
	    numfinished=$(($numfinished+1))
	    echo "$numfinished"
	fi
        FILE2=./$name/failed
        if test -f "$FILE2"; then
            echo "$FILE2 "
            is_ready=1
            numfinished=$(($numfinished+1))
            echo "$numfinished"
        fi
    done
    if [[ $numfinished -eq $numdirs ]]; then
        echo "Proceed to step 3"
        break
    else
        # idle for 60 seconds
        sleep 60
    fi
done

# now proceed to step3 calculations 

var="dist$numdist"
name=dist_"${!var}"
ln -s $name ./100

for npoint in $(seq "$numdirs" )
do
    nprog=$(($npoint+1))
    var="dist$npoint"
    name=dist_"${!var}"
    FILE2=./$name/failed
    if [ ! -f "$FILE2" ]; then
#    cp -R dist_$dist1 $name
	cp -f ref/data/estoktp.dat ./$name/data
	cp -f ref/data/ts.dat ./$name/data
	cd ./$name
	sed -ie "s/STEPN/Step3/g" data/estoktp.dat
	sed -ie "s/DISTN/${!var}/g" data/ts.dat
#	sed -ie "s/DISTN/$var/g" data/ts.dat
#    sed -ie "s/nOpt_ts_1/Opt_ts_1/g" data/estoktp.dat
#    sed -ie "s/n1dTau_ts/1dTau_ts/g" data/estoktp.dat
	sed -ie "s/nHL_ts/HL_ts/g" data/estoktp.dat
	sed -ie "s/nSymm_ts/Symm_ts/g" data/estoktp.dat
	sed -ie "s/nkTP/kTP/g" data/estoktp.dat
	rm -f ./finished
	runes2k
	cd ..
    fi
done

# now check if step3 calculations finished

while true; do
    # flag represents if the app is ready, 1=ready, 0=not ready
    is_ready=0
    numfinished=0
    for npoint1 in $(seq "$numdirs" )
    do
	nprog=$(($npoint1))
	var="dist$nprog"
	name=dist_"${!var}"
	FILE=./$name/finished
	if test -f "$FILE"; then
	    echo "$FILE "
	    is_ready=1
	    numfinished=$(($numfinished+1))
	    echo "$numfinished"
	fi
        FILE2=./$name/failed
        if test -f "$FILE2"; then
            echo "$FILE2 "
            is_ready=1
            numfinished=$(($numfinished+1))
            echo "$numfinished"
        fi
    done
#  heck this conditions, why ge? can't remember but needed
    if [[ $numfinished -ge $numdirs ]]; then
        echo "Proceed to step 4"
        break
    else
        # idle for 60 seconds
        sleep 60
    fi
done

# now proceed to step4 calculations 
# all the rates should have been computed

# assemble and do variational analysis

cp -R dist_$dist1 variational
cp -f ref/data/estoktp.dat ./variational/data
cd variational
sed -ie "s/nvariational/variational/g" data/estoktp.dat
sed -ie "s/nkTP/kTP/g" data/estoktp.dat
sed -ie "s/STEPN/Step3/g" data/estoktp.dat

name=dist_$dist1
var=$dist1
echo $name > blocks.dat
nfiles=$(($numdirs-1))
ndata=1

for npoint in $(seq "$nfiles" )
do
    nprog=$(($npoint+1))
    var="dist$nprog"
    name=dist_"${!var}"
    FILE2=../$name/failed
    if [ ! -f "$FILE2" ]; then
    	ndata=$(($ndata+1))
	echo $name >> blocks.dat
    fi
done



echo $ndata >> mep_dist.out
echo $dist1 >> mep_dist.out 

for npoint in $(seq "$nfiles" )
do
    nprog=$(($npoint+1))
    var="dist$nprog"
    name=dist_"${!var}"
    FILE2=../$name/failed
    if [ ! -f "$FILE2" ]; then
        echo "${!var}" >> mep_dist.out
    fi
done


cp -f blocks.dat data
cp -f mep_dist.out output
/programs/exes/assemble_var.com
runes2k

cd ..

# now proceed to preparing VRC-TST required data for correction potential


for npoint in $(seq "$numdist" )
do
#    nprog=$(($npoint+1))
    var="dist$npoint"
    name=dist_"${!var}"
#    cp -R dist_$dist1 $name
    FILE2=./$name/failed
    if [ ! -f "$FILE2" ]; then
	cp -f ref/data/estoktp.dat ./$name/data
	cp -f ref/data/ts.dat ./$name/data
	cd ./$name
	sed -ie "s/STEPN/Step4/g" data/estoktp.dat
	sed -ie "s/DISTN/${!var}/g" data/ts.dat
#	sed -ie "s/DISTN/$var/g" data/ts.dat
#    sed -ie "s/nOpt_ts_1/Opt_ts_1/g" data/estoktp.dat
#    sed -ie "s/n1dTau_ts/1dTau_ts/g" data/estoktp.dat
#    sed -ie "s/nHL_ts/HL_ts/g" data/estoktp.dat
#    sed -ie "s/nSymm_ts/Symm_ts/g" data/estoktp.dat
	sed -ie "s/npot_corr/pot_corr/g" data/estoktp.dat
	rm -f ./finished
	runes2k
	cd ..
    fi
done

# now check if step5 calculations finished

while true; do
    # flag represents if the app is ready, 1=ready, 0=not ready
    is_ready=0
    numfinished=0
    for npoint1 in $(seq "$numdist" )
    do
	nprog=$(($npoint1))
	var="dist$nprog"
	name=dist_"${!var}"
	FILE=./$name/finished
	if test -f "$FILE"; then
	    echo "$FILE "
	    is_ready=1
	    numfinished=$(($numfinished+1))
	    echo "$numfinished"
	fi
        FILE2=./$name/failed
        if test -f "$FILE2"; then
            echo "$FILE2 "
            is_ready=1
            numfinished=$(($numfinished+1))
            echo "$numfinished"
        fi
    done
#  check this conditions, why ge? can't remember but needed
    if [[ $numfinished -ge $numdirs ]]; then
        echo "Proceed to step 6"
        break
    else
        # idle for 60 seconds
        sleep 60
    fi
done

# now we are ready to run the vrc-tsts calculations

cp -R variational vrctst
cp -f ref/data/estoktp.dat ./vrctst/data

cd vrctst

sed -ie "s/nvrc_tst/vrc_tst/g" data/estoktp.dat
sed -ie "s/STEPN/Step5/g" data/estoktp.dat
runes2k
rm -f ./finished

while true; do
    # flag represents if the app is ready, 1=ready, 0=not ready                                                                    
    is_ready=0
    FILE=./finished
    if test -f "$FILE"; then
        echo "$FILE "
        is_ready=1
    fi

    if [[ $is_ready -eq 1 ]]; then
        echo "Proceed to step 7"
        break
    else
        # idle for 60 seconds                                                                                                     
        sleep 60
    fi
done

cp -f ./data/machines vrc_tst
cd vrc_tst
mkdir lr
mkdir lr/scratch
cp -f * lr
cd lr
cp -f divsur_lr.inp divsur.inp 
cd ..
mkdir sr
mkdir sr/scratch
cp -f * sr
cd sr
cp -f divsur_sr.inp divsur.inp 
cd ..
cd ..
cd ..

echo "completed calculation"



