#!/bin/bash

# Map node to GPU type manually
declare -A NODE_GPU_TYPES
NODE_GPU_TYPES["overture"]="A100"
NODE_GPU_TYPES["sonata2"]="A5000"
NODE_GPU_TYPES["quartet1"]="A6000"
NODE_GPU_TYPES["quartet2"]="A6000"
NODE_GPU_TYPES["quartet3"]="A6000"
NODE_GPU_TYPES["quartet4"]="A6000"
NODE_GPU_TYPES["quartet5"]="A6000"
NODE_GPU_TYPES["rosetta"]="A6000"
NODE_GPU_TYPES["dgx1"]="P100"
NODE_GPU_TYPES["squirtle"]="rtx6000"
NODE_GPU_TYPES["voyager"]="A6000"


# Function to convert memory units to MB
convert_to_mb() {
    local mem=$1
    if [[ $mem == *G ]]; then
        echo $(( ${mem%G} * 1024 ))
    elif [[ $mem == *M ]]; then
        echo "${mem%M}"
    else
        echo "$mem"  # fallback, shouldn't happen
    fi
}

# Function to check and print node resources
check_node() {
    local NODE_NAME=$1
     # 🛡️  Prevent empty node name causing full scontrol output
    if [ -z "$NODE_NAME" ]; then
        return
    fi

    local NODE_INFO=$(scontrol show node "$NODE_NAME")

    local TOTAL_CPUS=$(echo "$NODE_INFO" | grep -oP 'CfgTRES=.*?cpu=\K[0-9]+')
    local ALLOC_CPUS=$(echo "$NODE_INFO" | grep -oP 'AllocTRES=.*?cpu=\K[0-9]+')

    local TOTAL_MEM_RAW=$(echo "$NODE_INFO" | grep -oP 'CfgTRES=.*?mem=\K[^,]+')
    local ALLOC_MEM_RAW=$(echo "$NODE_INFO" | grep -oP 'AllocTRES=.*?mem=\K[^,]+')

    local TOTAL_MEM=$(convert_to_mb "$TOTAL_MEM_RAW")
    local ALLOC_MEM=$(convert_to_mb "$ALLOC_MEM_RAW")

    local TOTAL_GPUS=$(echo "$NODE_INFO" | grep -oP 'CfgTRES=.*?gres/gpu=\K[0-9]+' || echo 0)
    local ALLOC_GPUS=$(echo "$NODE_INFO" | grep -oP 'AllocTRES=.*?gres/gpu=\K[0-9]+' || echo 0)

    # GPU type extraction
    local GPU_INFO=$(echo "$NODE_INFO" | grep -oP 'Gres=gpu:[^[:space:]]+')
    local GPU_TYPE="unknown"
    if [[ $GPU_INFO =~ gpu:([^:]+):[0-9]+ ]]; then
        GPU_TYPE="${BASH_REMATCH[1]}"
    fi
    if [ "$GPU_TYPE" == "unknown" ]; then
    GPU_TYPE=${NODE_GPU_TYPES[$NODE_NAME]:-"unknown"}
    fi
    local FREE_CPUS=$((TOTAL_CPUS - ALLOC_CPUS))
    local FREE_MEM=$((TOTAL_MEM - ALLOC_MEM))
    local FREE_GPUS=$((TOTAL_GPUS - ALLOC_GPUS))
    local COLOR_RESET="\e[0m"
    local COLOR_RED="\e[31m"
    local COLOR_YELLOW="\e[33m"
    local COLOR_GREEN="\e[32m"

    local COLOR=""
    if [ "$FREE_GPUS" -eq 0 ] && [ "$TOTAL_GPUS" -gt 0 ]; then
        COLOR=$COLOR_RED
    elif [ "$FREE_GPUS" -gt 0 ] && [ "$FREE_GPUS" -lt "$TOTAL_GPUS" ]; then
        COLOR=$COLOR_YELLOW
    elif [ "$FREE_GPUS" -eq "$TOTAL_GPUS" ] && [ "$TOTAL_GPUS" -gt 0 ]; then
        COLOR=$COLOR_GREEN
    fi

    printf "${COLOR}%-20s CPUs: %3d/%-3d  Mem: %5.1fGB/%-5.1fGB  GPUs: %2d/%-2d (%s)${COLOR_RESET}\n" \
    "$NODE_NAME" "$FREE_CPUS" "$TOTAL_CPUS" \
    "$(bc <<< "scale=1; $FREE_MEM/1024")" "$(bc <<< "scale=1; $TOTAL_MEM/1024")" \
    "$FREE_GPUS" "$TOTAL_GPUS" "$GPU_TYPE"

}

# Main
if [ $# -eq 0 ]; then
    # No arguments: check all nodes
    NODES=$(sinfo -N -h -o "%N" | sort | uniq)

else
    # If node names provided as arguments
    NODES="$@"
fi

echo "Checking resources..."
echo "--------------------------------------------------------------------------"
for NODE in $NODES; do
    check_node "$NODE"
done
