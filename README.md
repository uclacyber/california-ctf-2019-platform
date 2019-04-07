# california-ctf-2019-platform

Slightly customized CTFd platform for California CTF 2019.

## Deployment

    dd if=/dev/urandom of=./.ctfd_secret_key bs=64 count=1
    docker-compose up
