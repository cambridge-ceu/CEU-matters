# Flask on SRCF

Tests are made under SRCF, where several aspects are required. A particular directory called `templates` is created.

```bash
if [ ! -d templates ]; then mkdir templates; fi
```

## app.py

```python
from flask import Flask, render_template
from datetime import datetime

app = Flask(__name__)

@app.route("/")
def home():
  return render_template("index.html", now=datetime.now())
```

## templates/index.html

```html
<!DOCTYPE html>
<html>
<head>
<!-- Required meta tags -->
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
<title>Your First Web Server</title>
</head>
<body>
<h1>Current time: {{now}}</h1>
</body>
</html>
```

which includes `{{now}}` in `Jinja2` template syntax.

## app.sh

```bash
export FLASK_ENV=development
export FLASK_APP=app.py
flask run
```

In addition, `flask routes` gives the following information

```
Endpoint  Methods  Rule
--------  -------  -----------------------
home      GET      /
static    GET      /static/<path:filename>
```

## localhost

Upon running Flask using the default port 5000, it can be acessed via

```bash
firefox http://127.0.0.1:5000
```

It then produces the following output,

```
Current time: 2023-11-18 16:29:33.365224
```

## gunicorn

The syntax is as follows,

```bash
gunicorn -w 4 app:app
```

Note that it is `Listening at: http://127.0.0.1:8000`, and it is easily changed via the `--bind/-b option`.

> According to the Gunicorn documentation, the recommended number of workers (-w #) for an application running on a single production server is (2 × number_of_CPU cores) + 1. The formula is loosely based on the idea that for any given CPU core, one worker will be performing IO (input/output) operations, and the other worker will be performing CPU operations.

## uWSGI

It is convenient to create a configuration file named `uwsgi.ini`, 

```
[uwsgi]

master = true
module = app:app
http-socket = :9090
http-timeout = 86400
http-timeout-asynchronous = true
logto = uwsgi.log

plugin = python3
processes = 4
threads = 2
```

then start with

```bash
uwsgi --ini uwsgi.ini
```

Now http://127.0.0.1:9090 is accessible and `wsgi.log`

```
*** Starting uWSGI 2.0.18-debian (64bit) on [Tue Nov 21 11:35:15 2023] ***
compiled with version: 10.0.1 20200405 (experimental) [master revision 0be9efad938:fcb98e4978a:705510a708d3642c9c962beb663c476167e4e8a4] on 11 April 2020 11:15:55
os: Linux-5.4.0-164-generic #181-Ubuntu SMP Fri Sep 1 13:41:22 UTC 2023
nodename: pip
machine: x86_64
clock source: unix
pcre jit disabled
detected number of CPU cores: 4
current working directory: /public/home/jhz22
detected binary path: /usr/bin/uwsgi-core
your processes number limit is 95938
your process address space limit is 53687091200 bytes (51200 MB)
your memory page size is 4096 bytes
detected max file descriptor number: 1024
lock engine: pthread robust mutexes
thunder lock: disabled (you can enable it with --thunder-lock)
uwsgi socket 0 bound to TCP address :9090 fd 3
Python version: 3.8.10 (default, May 26 2023, 14:05:08)  [GCC 9.4.0]
Python main interpreter initialized at 0x563bff726bb0
python threads support enabled
your server socket listen backlog is limited to 100 connections
your mercy for graceful operations on workers is 60 seconds
mapped 416880 bytes (407 KB) for 8 cores
*** Operational MODE: preforking+threaded ***
WSGI app 0 (mountpoint='') ready in 0 seconds on interpreter 0x563bff726bb0 pid: 1501687 (default app)
*** uWSGI is running in multiple interpreter mode ***
spawned uWSGI master process (pid: 1501687)
spawned uWSGI worker 1 (pid: 1501875, cores: 2)
spawned uWSGI worker 2 (pid: 1501876, cores: 2)
spawned uWSGI worker 3 (pid: 1501877, cores: 2)
spawned uWSGI worker 4 (pid: 1501879, cores: 2)
[pid: 1501879|app: 0|req: 1/1] 127.0.0.1 () {40 vars in 651 bytes} [Tue Nov 21 11:35:27 2023] GET / => generated 1227 bytes in 24 msecs (HTTP/1.1 200) 2 headers in 81 bytes (1 switches on core 0)
```

## References

1. Highlight: [Chapter 6](../c6) Sharing with the internet
    - Farrell D. (2023) The Well-Grounded Python Developer-HOW THE PROS USE PYTHON AND FLASK. Manning Publications Co.
    - [GitHub](https://github.com/writeson) [code](https://github.com/writeson/the-well-grounded-python-developer).
    - [Live book](https://livebook.manning.com/book/the-well-grounded-python-developer/).

2. Highlight: RESTful API
    - Adedeji O. (2023) Full-Stack Flask and React. Packt Publishing
    - [GitHub](https://github.com/PacktPublishing/Full-Stack-Flask-and-React)
