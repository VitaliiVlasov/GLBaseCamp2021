FROM busybox
CMD while true; do { echo -e "HTTP/1.1 200 OK\n\nGlobal Logic Base Camp DevOps"; } | nc -nvlp 8080; done
EXPOSE 8080
