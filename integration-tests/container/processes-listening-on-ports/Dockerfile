FROM ubuntu:jammy


RUN apt update -y && apt install gcc lsof python3 socat -y

COPY process-listening-on-ports.c /process-listening-on-ports.c
RUN gcc process-listening-on-ports.c -o process-listening-on-ports

COPY open-close-ports-load.py /open-close-ports-load.py
COPY open-close-ports-load-2.py /open-close-ports-load-2.py

ENTRYPOINT /process-listening-on-ports
