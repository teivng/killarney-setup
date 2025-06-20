# Killarney Setup

This helps you set up your dev environment on Killarney. Assume you already have a CCDB account, and your PI has added you to their allocation. For the purposes of this guide, we will use ``aip-supervisor`` as PI allocation, and ``student`` as user. These are simply examples, customize depending on your needs and configurations. We recommend you follow this guide in order. 

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