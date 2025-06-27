#!/bin/bash
#SBATCH --job-name=your_job_name
#SBATCH -A aip-supervisor
#SBATCH -N 4                         
#SBATCH --ntasks-per-node=1         
#SBATCH --cpus-per-task=60          
#SBATCH --gres=gpu:l40s:4           
#SBATCH --mem=480G
#SBATCH --time=1-00:00:00
#SBATCH --output=logs/slurm_%j.out
#SBATCH --error=logs/slurm_%j.err
#SBATCH --open-mode=append
#SBATCH --network=ib0             # Use InfiniBand

# Activate your environment
source ~/my_env/bin/activate

# Infiniband!
source ~/projects/aip-supervisor/student/ib

# Alternatively
export NCCL_IB_DISABLE=0             # Enable InfiniBand
export NCCL_SOCKET_IFNAME=ib0        # Use IB interface (verify with `ifconfig`)
export NCCL_IB_HCA=mlx5_0            # Adjust to your HCA (check with `ibstat`)
export NCCL_DEBUG=INFO               # Optional: verbose logging

# Navigate to project directory
cd ~/projects/aip-supervisor/student/my_project_directory

NPROC_PER_NODE=4 # number of GPUs per node, should correspond to GRES

# Get the master node hostname, defaults to the first Node
# If you are allocated kn001, kn002, kn003, and kn004, the master node is kn001
MASTER_HOSTNAME=$(scontrol show hostnames $SLURM_JOB_NODELIST | head -n 1)

# Extract digits from knXXX to form 10.1.1.XXX
# Cringe IP address parsing
MASTER_ADDR="10.1.1.$(echo $MASTER_HOSTNAME | grep -oE '[0-9]+')"
MASTER_PORT=29500

# Sanity checking
echo "Master host: $MASTER_HOSTNAME"
echo "MASTER_ADDR=$MASTER_ADDR"
echo "MASTER_PORT=$MASTER_PORT"
echo "Node ID: $SLURM_NODEID"


# Set env variables
export MASTER_ADDR=$MASTER_ADDR
export MASTER_PORT=$MASTER_PORT


srun torchrun \
  --nnodes=$SLURM_JOB_NUM_NODES \
  --nproc_per_node=$NPROC_PER_NODE \
  --rdzv_id=123 \
  --rdzv_backend=c10d \
  --rdzv_endpoint=$MASTER_ADDR:$MASTER_PORT \
  my_script.py