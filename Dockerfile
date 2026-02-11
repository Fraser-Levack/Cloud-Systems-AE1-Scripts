FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    iputils-ping \
    curl \
    fio \
    sysbench \
    iperf3

WORKDIR /app

ENV IPERF_SERVER= [Iperf Address]

COPY test_suite.sh .

RUN chmod +x test_suite.sh

CMD ["./test_suite.sh"]
