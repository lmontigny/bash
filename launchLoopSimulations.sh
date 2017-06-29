#/bin/sh

# Launch several simulation with different parameters

file="original.cfg"
limits=(500 1000 2000 3000)
for i in "${limits[@]}"
do
    echo $i
    RPM=$i
    file_out="dsd_$RPM.cfg"

    # Calculate parameters
    RPS=$(echo "$RPM/60" | bc -l)
    V_REF=$(echo "$RPM/100" | bc -l)

    # Replace line in the cfg file
    sed -e "s/rot_freq.*/rot_freq \"$RPS 0.0 0.0\"/" $file > tmp 
    sed -e "s/ref_vel.*/ref_vel $V_REF/" tmp > $file_out
    rm -f tmp

    # Launch simulation
    CUDA_VISIBLE_DEVICES=0,6 mpiexec --mca btl_smcuda_use_cuda_ipc 0 -np 2 ~/nfx/build/nanoFluidXmGPU.bin -i $file_out > noh | echo "$RPM running"

    # Postprocessing
    ./torque_comparison.sh $RPM
done
