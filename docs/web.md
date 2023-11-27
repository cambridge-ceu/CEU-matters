# Website

> The SRCF uses Apache to serve websites so if you need to run a backend web app, for example a Django, Rails or Express server, then you will need to forward web requests, e.g., CRSid.user.srcf.net through to an app running on a localhost port.

- Technical reference, <https://docs.srcf.net/reference/>
- Tutorial, <https://docs.srcf.net/tutorials/>

## .htaccess

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
    - RewriteRule "^(Caprion/.*)$" unix:/home/jhz22/web.sock|http://localhost/$1 [P,NE,L,QSA]
    - RewriteRule "^(Caprion/.*)$" unix:/home/jhz22/web.sock|http://jhz22.user.srcf.net/$1 [P,NE,L,QSA]
* TCP -- no headers
    - RewriteRule "^(.*)$" http://localhost:8012/$1 [P,NE,L,QSA]
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

## Socket

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

### via Python

Source: <https://www.digitalocean.com/community/tutorials/python-socket-programming-server-client>

We employ `python server.py` and `python client.py` below for two interactive sessions which ends with `bye`.

#### server.py

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

#### client.py

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

## Raven authentication

Web: <https://docs.srcf.net/reference/web-hosting/raven-authentication/>

## Sample

<https://sample.soc.srcf.net/flask/>

based on `/public/societies/sample/flask/app.py`.

### Template

Check `/public/societies/sample/run-python.sh`.

### Unix socket

```bash
#!/bin/bash -e

. ~/myapp/venv/bin/activate
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

## webserver.srcf.net

(To be refined)

### uWSGI

```bash
uwsgi --socket /home/jhz22/web.sock --plugin python3 --enable-threads --wsgi-file app.py --callable app --processes 2 --master --chmod-socket=666
```

### nginx

Web: <https://nginx.org/>

#### Installation

```bash
cd ~/myapp/ftp
wget -qO- https://nginx.org/download/nginx-1.24.0.tar.gz | \
tar xfz -
cd nginx-1.24.0
./configure --prefix=/home/jhz22/myapp/nginx-1.24.0
make
make install
~/myapp/nginx-1.24.0/sbin/nginx -t

```

#### nginx.conf

Replace the following section into `/home/jhz22/myapp/nginx-1.24.0/conf/nginx.conf`

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

showing that

```
jhz22@sinkhole:~/myapp$ nginx-1.24.0/sbin/nginx -t
nginx: the configuration file /home/jhz22/myapp/nginx-1.24.0/conf/nginx.conf syntax is ok
nginx: configuration file /home/jhz22/myapp/nginx-1.24.0/conf/nginx.conf test is successful
```

#### nginx.service

:~/.config/systemd/user

```
Description=Nginx HTTP server

[Service]
ExecStart=/home/jhz22/myapp/nginx-1.24.0/sbin/nginx
Restart=always

[Install]
WantedBy=default.target
```

#### systemctl

```bash
systemctl --user daemon-reload
systemctl --user list-unit-files
systemctl --user restart nginx
```

The first line is necessary since we would get a message,

```
Warning: The unit file, source configuration file or drop-ins of nginx.service changed on disk. Run 'systemctl --user daemon-reload' to reload units.
```
