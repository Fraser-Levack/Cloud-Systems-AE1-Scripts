FROM ubuntu:latest

ENV cpu_arch=amd64

RUN apt-get update -y && \
 apt-get install -y sysbench && \
 apt-get install -y fio && \
 apt-get install -y iperf3 && \
 apt-get clean

CMD ["/usr/bin/sysbench"]
