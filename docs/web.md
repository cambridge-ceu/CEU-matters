# Website

> The SRCF uses Apache to serve websites so if you need to run a backend web app, for example a Django, Rails or Express server, then you will need to forward web requests, e.g., CRSid.user.srcf.net through to an app running on a localhost port.

- Technical reference, <https://docs.srcf.net/reference/>
- Tutorial, <https://docs.srcf.net/tutorials/>
- Raven authentication, <https://docs.srcf.net/reference/web-hosting/raven-authentication/>

## Sample

<https://sample.soc.srcf.net/flask/>

is based on `/public/societies/sample/flask/app.py`.

There is a driver program, `/public/societies/sample/run-python.sh`.

## Socket

### via Python

Source: <https://www.digitalocean.com/community/tutorials/python-socket-programming-server-client>

We employ `python server.py` and `python client.py` below for two interactive sessions which ends with `bye`.

#### -- server.py --

```python
import socket

def server_program():
    # get the hostname
    host = socket.gethostname()
    port = 5000  # initiate port no above 1024

    server_socket = socket.socket()  # get instance
    # look closely. The bind() function takes tuple as argument
    server_socket.bind((host, port))  # bind host address and port together

    # configure how many client the server can listen simultaneously
    server_socket.listen(2)
    conn, address = server_socket.accept()  # accept new connection
    print("Connection from: " + str(address))
    while True:
        # receive data stream. it won't accept data packet greater than 1024 bytes
        data = conn.recv(1024).decode()
        if not data:
            # if data is not received break
            break
        print("from connected user: " + str(data))
        data = input(' -> ')
        conn.send(data.encode())  # send data to the client

    conn.close()  # close the connection

if __name__ == '__main__':
    server_program()
```

#### -- client.py --

```python
import socket

def client_program():
    host = socket.gethostname()  # as both code is running on same pc
    port = 5000  # socket server port number

    client_socket = socket.socket()  # instantiate
    client_socket.connect((host, port))  # connect to the server

    message = input(" -> ")  # take input

    while message.lower().strip() != 'bye':
        client_socket.send(message.encode())  # send message
        data = client_socket.recv(1024).decode()  # receive response

        print('Received from server: ' + data)  # show in terminal

        message = input(" -> ")  # again take input

    client_socket.close()  # close the connection

if __name__ == '__main__':
    client_program()
```

### via C

Source: <https://gist.github.com/ryran/170009f84c11bf3243b1>

```c
#include <fcntl.h>
#include <sys/un.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

int main(int argc, char **argv)
{
    // The following line expects the socket path to be first argument
    char * mysocketpath = argv[1];
    // Alternatively, you could comment that and set it statically:
    //char * mysocketpath = "/tmp/mysock";
    struct sockaddr_un namesock;
    int fd;
    namesock.sun_family = AF_UNIX;
    strncpy(namesock.sun_path, (char *)mysocketpath, sizeof(namesock.sun_path));
    fd = socket(AF_UNIX, SOCK_DGRAM, 0);
    bind(fd, (struct sockaddr *) &namesock, sizeof(struct sockaddr_un));
    close(fd);
    return 0;
}
```

and compiled with `gcc cleate-a-socket.c -o create-a-socket; create-a-socket web.sock`.

The mode field of `web.sock` has flag `s`, see <https://en.wikipedia.org/wiki/Unix_file_types>.

## Web Server

This refers to `webserver.srcf.net` (`sinkhole.srcf.net`).

### gunicorn

```bash
#!/bin/bash -e

# . ~/myapp/venv/bin/activate
exec gunicorn -w 2 -b unix:/home/jhz22/web.sock --log-file - app:app
```

To access we use `curl`

```bash
curl --unix-socket /home/jhz22/web.sock http://localhost
```

or `python`

```python
import socket

sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
sock.connect('/home/jhz22/web.sock')

# Now you can send and receive data through the socket

sock.close()
```

### uWSGI

```bash
uwsgi --socket /home/jhz22/web.sock --chmod-socket=666 --enable-threads --processes 2 --master \
      --plugin python3 --wsgi-file app.py --callable app
```

### nginx

Web: <https://nginx.org/>

#### -- Installation --

```bash
cd /public/home/jhz22
wget -qO- https://nginx.org/download/nginx-1.24.0.tar.gz | \
tar xfz -
cd nginx-1.24.0
./configure --prefix=/public/home/jhz22
make
make install
/public/home/jhz22/sbin/nginx -t

```

#### -- nginx.conf --

Replace the following section into `/public/home/jhz22/conf/nginx.conf`

```
events {
    worker_connections 1024;
}

http {
    server {
        listen unix:/home/jhz22/web.sock;
        server_name jhz22.user.srcf.net;

        location / {
            proxy_pass http://unix:/home/jhz22/web.sock;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

or using uWSGI

```
server {
    listen 8000;
    server_name jhz22.user.srcf.net;

    location / {
        include uwsgi_params;
        uwsgi_pass unix:/home/jhz22/web.sock;
    }
}
```

so that upon success we see

```
jhz22@sinkhole:/public/home/jhz22/sbin/nginx -t
nginx: the configuration file /public/home/jhz22/conf/nginx.conf syntax is ok
nginx: configuration file /public/home/jhz22/conf/nginx.conf test is successful
```

#### -- nginx.service --

Location: ~/.config/systemd/user

```
Description=Nginx HTTP server

[Service]
ExecStart=/public/home/jhz22/sbin/nginx
Restart=always

[Install]
WantedBy=default.target
```

### -- systemctl --

Instances of use

```bash
systemctl --user daemon-reload
systemctl --user list-unit-files
systemctl --user restart nginx
systemctl --user status nginx
systemctl --user reset-failed nginx
systemctl --user stop nginx
```

The first line is necessary since we would get a message,

```
Warning: The unit file, source configuration file or drop-ins of nginx.service changed on disk. Run 'systemctl --user daemon-reload' to reload units.
```

### .htaccess

It sits on the current directory.

```
RequestHeader set Host expr=%{HTTP_HOST}
RequestHeader set X-Forwarded-For expr=%{REMOTE_ADDR}
RequestHeader set X-Forwarded-Proto expr=%{REQUEST_SCHEME}
RequestHeader set X-Real-IP expr=%{REMOTE_ADDR}
RewriteRule ^(.*)$ unix:<path-to-socket>|http://<url>/$1 [P,NE,L,QSA]
```

e.g.,

* Unix
    - RewriteRule "^(Caprion/.*)\$" unix:/home/jhz22/web.sock|http://localhost/\$1 [P,NE,L,QSA]
    - RewriteRule "^(Caprion/.*)\$" unix:/home/jhz22/web.sock|http://jhz22.user.srcf.net/\$1 [P,NE,L,QSA]
* TCP -- no headers
    - RewriteRule "^(.*)$" http://localhost:8012/\$1 [P,NE,L,QSA]

See also

- Check: <http://www.htaccesscheck.com/>
- Tester: <https://htaccess.madewithlove.com/>

Based on chatGPT,

* RequestHeader set Host expr=%{HTTP_HOST}: Sets the Host header to the value of the HTTP_HOST variable.
* RequestHeader set X-Forwarded-For expr=%{REMOTE_ADDR}: Sets the X-Forwarded-For header to the value of the REMOTE_ADDR variable.
* RequestHeader set X-Forwarded-Proto expr=%{REQUEST_SCHEME}: Sets the X-Forwarded-Proto header to the value of the REQUEST_SCHEME variable.
* RequestHeader set X-Real-IP expr=%{REMOTE_ADDR}: Sets the X-Real-IP header to the value of the REMOTE_ADDR variable.
* RewriteRule ^(.*)$ unix:<path-to-socket>|http://<url\>/$1 [P,NE,L,QSA]: The RewriteRule is rewriting the URL. It proxies requests to a specified URL with a Unix domain socket. Replace <path-to-socket> with the actual path to your Unix domain socket and <url> with the target URL.
  - [P,NE,L,QSA]: These are flags that modify the behavior of the RewriteRule:
      - P: Proxy flag. This tells Apache to treat the substitution as a proxy request and forward it to the specified location.
      - NE: No Escape flag. This prevents Apache from escaping special characters in the substitution, useful when substituting URLs.
      - L: Last flag. This indicates that if the current rule matches, no further rules should be processed for this request.
      - QSA: Query String Append flag. This appends the original query string to the substituted URL.

Make sure to replace <path-to-socket> and <url> with your actual values. Additionally, ensure that the necessary modules (mod_headers and mod_rewrite) are enabled in your Apache configuration.

Logs are at `/var/log/apache2/user/$USER/`.

## Benchmark tools

### Apache

```bash
ab -n 1000 -c 5 -C "somecookie=rawr" http://ourwebsite.com/
```

with output,

```
This is ApacheBench, Version 2.3 <$Revision: 1843412 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking ourwebsite.com (be patient)
Completed 100 requests
Completed 200 requests
Completed 300 requests
Completed 400 requests
Completed 500 requests
Completed 600 requests
Completed 700 requests
Completed 800 requests
Completed 900 requests
Completed 1000 requests
Finished 1000 requests


Server Software:        nginx
Server Hostname:        ourwebsite.com
Server Port:            80

Document Path:          /
Document Length:        859 bytes

Concurrency Level:      5
Time taken for tests:   33.132 seconds
Complete requests:      1000
Failed requests:        0
Total transferred:      1246000 bytes
HTML transferred:       859000 bytes
Requests per second:    30.18 [#/sec] (mean)
Time per request:       165.659 [ms] (mean)
Time per request:       33.132 [ms] (mean, across all concurrent requests)
Transfer rate:          36.73 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:       75   76   1.3     75      89
Processing:    87   89   2.6     88     123
Waiting:       87   89   2.6     88     123
Total:        163  165   3.2    164     200

Percentage of the requests served within a certain time (ms)
  50%    164
  66%    164
  75%    165
  80%    165
  90%    167
  95%    170
  98%    174
  99%    177
 100%    200 (longest request)
```

### wrk

Web: <https://github.com/wg/wrk>

```bash
wget -qO- https://github.com/wg/wrk/archive/refs/tags/4.2.0.tar.gz | tar xfz -
cd wrk-4.2.0/
make WITH_OPENSSL=/usr/include/openssl
./wrk -t2 -c4 -d30s http://127.0.0.1:8000/index.html
```

The last line gives,

```
unning 30s test @ http://127.0.0.1:8000/index.html
  2 threads and 4 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     1.23ms  616.83us  14.90ms   93.82%
    Req/Sec     1.64k   160.27     1.97k    70.50%
  98058 requests in 30.02s, 36.00MB read
  Non-2xx or 3xx responses: 98058
Requests/sec:   3266.42
Transfer/sec:      1.20MB
```

This also produces `luajit`, e.g., with a file named `add.lua`

```lua
-- Define a function that adds two numbers
function addNumbers(a, b)
    return a + b
end

-- Call the function with arguments 5 and 10
result = addNumbers(5, 10)

-- Print the result
print("The sum is: " .. result)
```

```bash
luajit add.lua
```

we obtain

```
The sum is: 15
```

## Additional information

- Caddy, <https://caddyserver.com/>, `caddy run --config webserver-configs/Caddyfile`
- Grav, <https://getgrav.org/> ([GitHub](https://github.com/caddyserver/caddy), [Linux arm64](https://caddyserver.com/api/download?os=linux&arch=arm64&idempotency=33011962771737))
- LuaJIT, <https://luajit.org/>
- ws, <https://github.com/websockets/ws>
