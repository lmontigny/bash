#/bin/sh

# Validation suite case 
# Step 1: Parameters
# Step 2: Simulation
# Step 3: Postprocessing
#
# Note: double presicion binary should be used 
# The vtu data is compared to the vtu_reference data, variable pro variable, for exemple presure with reference_presure for each particle.

#-------------------------------------------------
# Step 1: Parameters
#-------------------------------------------------
GPU_0=4  #choose GPU CUDA_VISIBLE_DEVICES
NFX=/home/lmontigny/test.bin
START_INIT=$SECONDS

# Folder
DIR="$(dirname "$(readlink -f "$0")")"
SCRIPT_FOLDER="postprocessing"

# List of cfg file for the simulations
# To add a new one, add the cfg file inside SCRIPT_FOLDER/mySimulation/myConfigFile.cfg
# The Step 3 is using this array as well
# Each line can be commented out with #
cfgfile=( 
          "simulation/test1/simu1.cfg"
          "simulation/test2/simu2.cfg"
          "simulation/test2/RPM1/simu1.cfg"
       )

folder=(${cfgfile[@]%/*}) #remove /nameOfFile.cfg from cfgfile array
cfg=(${cfgfile[@]##*/})   #keep only nameOfFile.cfg from cfgfile array

#-------------------------------------------------
# Step 2: Loop to launch the simulations
#-------------------------------------------------
counter=0;
rm -f $DIR/noh_summary
echo "--- SIMULATION ---"
for i in ${cfgfile[@]}
do
    echo "Simulation launched: ${cfgfile[$counter]}"
    cd ${folder[$counter]}
    START_SIM_1=$SECONDS
    CUDA_VISIBLE_DEVICES=$GPU_0 nohup mpiexec --mca btl_smcuda_use_cuda_ipc 0 -np 1 $NFX -i ${cfg[$counter]} > noh 2>&1
    ELAPSED_TIME_1=$(($SECONDS - $START_SIM_1))
    printf "\n$i\n\n" >> $DIR/noh_summary; tail -n 20 noh >> $DIR/noh_summary
    cd $DIR
    echo -n "Done in "; echo "$(($ELAPSED_TIME_1/60)) min $(($ELAPSED_TIME_1%60)) sec "
    let counter+=1;
done
printf "Output of the simulations available here: \n $DIR/noh_summary\n"

## Delete data_simulation/current/ ??

#-------------------------------------------------
# Step 3: Loop to launch the postprocessing script
#-------------------------------------------------
counter=0;
echo "--- POSTPROCESSING ---"

# Extract string from the cfgfile array
sim_name=(${cfgfile[@]%.cfg*}) # string change: remove /nameOfFile.cfg from cfgfile array
sim_cfg=(${cfgfile[@]##*/})    # string change: keep only nameOfFile.cfg from cfgfile array
sim_alone=(${sim_cfg[@]%.cfg}) # string change: nameOfFile

rm -rf "$DIR/$SCRIPT_FOLDER/version2/data_simulation/current/err"
for i in ${cfgfile[@]}
do
    aa="${sim_alone[$counter]}"
    echo "Postprocessing $aa running" 
    folder_sim="${sim_name[$counter]}/OUTPUT"
    file_in=$(ls $folder_sim/*pvtu | tail -1)  #last pvtu file available
    file_out="$DIR/$SCRIPT_FOLDER/version2/data_simulation/current/$aa.csv" #csv file from the vtu
    file_out_ref="$DIR/$SCRIPT_FOLDER/version2/data_simulation/reference/$aa.csv" #reference csv file 
    /global/Paraview/ParaView-5.1.2-244-g0f0586e-Qt4-OpenGL2-MPI-Linux-64bit/bin/pvpython --mesa-llvm $SCRIPT_FOLDER/version2/python/convert_vtu_csv.py $file_in $file_out
    /usr/bin/octave --silent  --no-line-editing $SCRIPT_FOLDER/version2/matlab/error_check.m $file_out $file_out_ref
    let counter+=1
done

ELAPSED_TIME=$(($SECONDS - $START_INIT))
echo "Total duration: $(($ELAPSED_TIME/60)) min $(($ELAPSED_TIME%60)) sec"   
echo "Script done"
