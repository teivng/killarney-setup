# Killarney Setup

This helps you set up your dev environment on Killarney. Assume you already have a CCDB account, and your PI has added you to their allocation. For the purposes of this guide, we will use ``aip-supervisor`` as PI allocation, and ``student`` as user. These are simply examples, customize depending on your needs and configurations. We recommend you follow this guide in order. 

## ``starship``

You want to make your bash prompt based. Here's how to do it. 

Install ``starship`` **locally**:

```
curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir ~/.local/bin
```

Add this line to the end of your ``.bashrc``:

```
eval "$(starship init bash)"
```

Source and enjoy. A starter config is provided in this repository at ``starship.toml``. Copy it to ``~/.config/starship.toml`` to load the config. 

## Login

Add your ED25519 and RSA keys of your home machine to https://ccdb.alliancecan.ca/ssh_authorized_keys. Setup MFA for CCDB if you haven't already done so: https://ccdb.alliancecan.ca/multi_factor_authentications. 

Once that's done, you are free to ``ssh``: 

```
ssh student@killarney.alliancecan.ca
```

You should be dropped in ``/home/student``.

### Hopping between login nodes

If you want to hop between login nodes, you have to forward your identity from your home machine. 

1. Run ``ssh-add -l`` to check if your SSH agent registered your keys.
2. If not, add each of your IDs with ``ssh-add``. They should be by default in ``~/.ssh/``.

From now on, SSH to Killarney with the ``-A`` flag to forward your identity, allowing you to subsequently hop between ``klogin0X`` nodes freely.

### Home machine aliasing

Add this to your ``~/.bashrc`` or ``~/.zshrc``:

```
alias k="ssh -A student@killarney.alliancecan.ca"
```
Then source it. You can now type ``k`` in your terminal and get sent to your happy place. 

## Setup a ``code`` tunnel

### Install the ``code`` server

On Killarney, run the following:

```
cd ~/projects/aip-supervisor/student

curl -Lk 'https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64' --output vscode_cli.tar.gz

tar -xf vscode_cli.tar.gz

rm vscode_cli.tar.gz 
```
This installs the ``code`` server to ``~/code``. 

### Run the code server

The recommended way to maintain a persistent code server is to keep it in a ``tmux`` window, detach, then forget. 

Start a new tmux session:

```
tmux new-session -s session_name
```

In your ``tmux`` session, run:

```
/home/student/projects/aip-supervisor/student/code tunnel
```

Authenticate with either GitHub or Microsoft. Once that's done, detach the tmux session with ``Ctrl B + D``. You can forget about it. Now you can dev on your VSCode client. 

If you need to restart it, first make sure you **hop on the login node where you created your tmux session**, then attach your tmux session back. If you left it in ``klogin0X``, from any login node, run: 

```
ssh klogin0X

tmux attach
```

and we're back.

## ``srun`` jobs: interactive session

From now on, we assume development is done on your VSCode client that is properly tunneled to a login node. 

You are unable to ``srun`` or ``sbatch`` from your home directory. Navigate to your projects directory first:

```
cd ~/projects/aip-supervisor/student/
```
This will be where you develop and spend most of your time in.

You want to borrow some GPUs. In your login node (VSCode client's terminal will be hosted on the same login node you launched ``tmux``):

```
srun -A aip-supervisor -c 8 --gres=gpu:l40s:2 --mem=128G --time=1-00:00:00 --pty bash
```
You have successfully borrowed 8 cores, 2 L40S GPUs, and 128G of RAM for 1 day. You can either borrow ``l40s`` or ``h100``. 

## ``sbatch`` jobs: 

Copy the template and edit accordingly. To ``sbatch`` a job ``example_sbatch.slrm``, run:
```
sbatch example_sbatch.slrm
```

## Configure your ``python`` environments

There is no ``anaconda`` or ``miniconda``. You should use ``uv``. 

Get Rust loaded up (``uv`` uses rust):

``module load rust/1.85``

Install ``uv``:
```
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Create a virtual environment with ``uv`` and Python 3.11:
```
uv venv --python=3.11 ~/my_env
```

Activate your environment:
```
source ~/my_env/bin/activate
```

Install stuff:
```
uv pip install scikit-learn numpy torch torchaudio torchvision transformers datasets accelerate jupyter wandb hydra-core
```

Install from ``requirements.txt``:
```
uv pip install -r requirements.txt
```

From now on, for each job, manually activate your environment by sourcing the ``activate`` file in the corresponding environment's binaries. 

### IMPORTANT! ``wandb`` 

If you use the provided ``pip``, it installs packages based on a cached database of packages. The cached ``wandb`` is **bugged**. Upon importing and running ``wandb.init(...)``, it will throw an error saying ``wandb-core`` is missing. This is why we use ``uv``, among a multitude of other reasons. 

## Run a ``jupyter`` server

You want to run ``debug.ipynb`` in your repo, but your VSCode client is hooked to ``klogin0X``. You want the big machines to run your notebook instead. Assume your VSCode client has the Jupyter extension installed.

From your terminal, get some resources:

```
srun -A aip-supervisor -c 8 --gres=gpu:l40s:2 --mem=128G --time=1-00:00:00 --pty bash
```

Once in the mainframe, activate your environment **which has jupyter installed**, otherwise install with ``uv pip install jupyter``. 

With your dev environment activated, start a notebook server:
```
jupyter notebook --no-browser --port=8.8.8.8 --ip=0.0.0.0
```
You should see something like:
```
To access the server, open this file in a browser:
    file:///home/student/.local/share/jupyter/runtime/jpserver-1672444-open.html
Or copy and paste one of these URLs:
    http://kn166:8888/tree?token=dfbbfd67f17383afea30eae3eb0ee7f1d0e20a642015fef1
    http://127.0.0.1:8888/tree?token=dfbbfd67f17383afea30eae3eb0ee7f1d0e20a642015fef1
```
Copy the line that contains ``kn:XYZ:8888/tree?...``. 
With your notebook open in your VSCode client, click on "Select Kernel" &#8594; "Select Another Kernel" &#8594; "Existing Jupyter Server" &#8594; paste here &#8594; click Enter &#8594; "Python 3 (ipykernel)" and you're in!

It's recommended that right after you grab resources and ``slurm`` sends you to node ``knXYZ``, that you ``tmux`` right away, put your jupyter instance on a ``tmux`` session, then detach. In this way, you still have a terminal for ``knXYZ``, otherwise your only compute node terminal is running your ``jupyter`` server. 

### ``sbatch``-ing your ``jupyter`` server
Yes you can do it. Make a ``sbatch_jupyter.slrm`` with the desired resource configuration, make sure to configure the output to write into some file somewhere so that you can read the URL in order to paste into your VSCode client's kernel selector. 

# Distributed training

This section is not a guide to writing distributed training code. It is merely here to show correct configurations on Killarney.

## Single-node multi-GPU

You can use ``torchrun`` with ``--nproc_per_node`` the number of GPUs you wih to use, ``--nnodes=1``, or use ``accelerate``. 

## Multi-node multi-GPU

Running ``ifconfig``, two network interfaces are of interest: ``eth0`` and ``ib0``, corresponding to TCP/IP and InfiniBand respectively. Let's say you're on ``kn123``, the IP address (``eth0``) is ``10.1.1.123``, while the InfiniBand address (``ib0``) is ``10.0.1.123``. As far as we can tell, this applies to all compute nodes ``knXYZ``. 

We would like to have nodes talk to each other through ``ib0`` instead of ``eth0``. **HOWEVER**, the correct ``torchrun`` ``--rdzv_endpoint`` is going to be the ``eth0`` address, **not** the ``ib0`` address, for reasons unknown, we will not worry about those right meow.


Let's say we're doing distirbuted training on and we are allocated 8 GPUs across 2 nodes ``kn010`` and ``kn011``, with ``kn010`` being the master node. First, export certain environment variables to use InfiniBand **on both nodes**:

```
export NCCL_IB_DISABLE=0             # Enable InfiniBand
export NCCL_SOCKET_IFNAME=ib0        # Use IB interface (verify with `ifconfig`)
export NCCL_IB_HCA=mlx5_0            # Adjust to your HCA (check with `ibstat`)
export NCCL_DEBUG=INFO               # Optional: verbose logging
```

We recommend you put this in a ``~/ib`` file so that upon successful allocation of compute resources, you can ``source ~/ib`` immediately after loading your favorite modules. 

On ``kn010``: 

```
torchrun \
--nnodes=2 \
--nproc_per_node=4 \
--node_rank=0 \
--rdzv_id=123 \
--rdzv_backend=c10d \
--rdzv_endpoint=10.1.1.10:29500 \
your_script.py
```

On ``kn011``: 

```
torchrun \
--nnodes=2 \
--nproc_per_node=4 \
--node_rank=1 \
--rdzv_id=123 \
--rdzv_backend=c10d \
--rdzv_endpoint=10.1.1.10:29500 \
your_script.py
```

where ``--rdzv_id`` can be set to whatever but needs to be the same across nodes, and ``--rdzv_endpoint`` is the ``address:port`` of the master node. The only thing that changes is the node rank, with the master node at rank ``0``. **This will run on Infiniband**, even though the address is an IP address. For streamlining this setup in a ``sbatch`` file and automating IP address assignment as rendezvous endpoint, you can ask ChatGPT. 

We assume that in your main process file, you're initializing ``nccl`` correctly. 

## Multi-node ``sbatch`` 

The file ``multinode.sbatch`` gives a template on how to do multi-node multi-GPU parallelization. It sets the correct environment variables, parses the correct IP addresses, and ``srun`` ``torchrun`` jobs individually with the same rendezvous endpoint.

The script uses ``srun`` to launch jobs so that processes running on each of your nodes inherit Slurm's environment variables in order to get global rank and local rank variables for your GPUs. 

A ``nccl`` template using ``torch.distributed`` is provided in ``template_distributed.py``. This sets up a few functions that grab environment parameters and sets up your device.

### How/why does this work? 
Don't worry about it.

### Help! My model doesn't fit on one GPU

→ Megatron-LM, DeepSpeed, FairScale, FSDP. Apparently you can also use ``accelerate`` and set DeepSpeed stage ``2`` or ``2``, it will automatically shard your model, handle optimizer partitioning, and manage CPU/GPU offloading.

## Using macros in ``~/.bashrc``
Borrow some GPUs:
```
gpu_node l40s 1 12 64G
```
Cancel all jobs except 12345:
```
scexcept 12345
```
Nuke all your jobs:
```
sc
```
Monitor your jobs:
```
sq
sq
sq
sq
```
Monitor your jobs lazily:
```
wsq
```

Dopamine hit:
```
wn
```

## Final remarks

Templates for macros to paste in ``~/.bashrc`` as well as for ``sbatch`` are provided in this repo. 

Also, use ``uv``. 
