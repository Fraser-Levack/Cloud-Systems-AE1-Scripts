sudo docker build -t vm-benchmark .


sudo docker run --rm   --network=host   -v $(pwd)/logFiles:/app/logFiles   vm-benchmark
