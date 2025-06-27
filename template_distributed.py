import os
import torch
import torch.distributed as dist


def setup_distributed():
    dist.init_process_group(backend="nccl")
    torch.cuda.set_device(int(os.environ["LOCAL_RANK"]))


def cleanup_distributed():
    dist.destroy_process_group()


def is_main_process():
    return dist.get_rank() == 0

def main():
    setup_distributed()
    
    # get local variables
    rank = dist.get_rank()
    local_rank = int(os.environ['LOCAL_RANK'])
    device = torch.device(f"cuda:{local_rank}")
    
    return 0


if __name__ == "__main__":
    main()
    