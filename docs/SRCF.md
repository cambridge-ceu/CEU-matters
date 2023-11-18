# SRCF website

> The SRCF uses Apache to serve websites so if you need to run a backend web app, for example a Django, Rails or Express server, then you will need to forward web requests.

- Port binding, <https://docs.srcf.net/reference/shell-and-files/software-and-installation/#port-binding>
- Website traffic, <https://docs.srcf.net/reference/web-hosting/web-applications/#routing-traffic-to-your-app>

e.g., CRSid.user.srcf.net through to an app running on a localhost port.

## .htaccess

It sits on the current directory.

```
RequestHeader set Host expr=%{HTTP_HOST}
RequestHeader set X-Forwarded-For expr=%{REMOTE_ADDR}
RequestHeader set X-Forwarded-Proto expr=%{REQUEST_SCHEME}
RequestHeader set X-Real-IP expr=%{REMOTE_ADDR}
RewriteRule ^(.*)$ unix:<path-to-socket>|http://<url>/$1 [P,NE,L,QSA]
```

Based on chatGPT,

* RequestHeader set Host expr=%{HTTP_HOST}: Sets the Host header to the value of the HTTP_HOST variable.
* RequestHeader set X-Forwarded-For expr=%{REMOTE_ADDR}: Sets the X-Forwarded-For header to the value of the REMOTE_ADDR variable.
* RequestHeader set X-Forwarded-Proto expr=%{REQUEST_SCHEME}: Sets the X-Forwarded-Proto header to the value of the REQUEST_SCHEME variable.
* RequestHeader set X-Real-IP expr=%{REMOTE_ADDR}: Sets the X-Real-IP header to the value of the REMOTE_ADDR variable.
* RewriteRule ^(.*)$ unix:<path-to-socket>|http://<url>/$1 [P,NE,L,QSA]: The RewriteRule is rewriting the URL. It proxies requests to a specified URL with a Unix domain socket. Replace <path-to-socket> with the actual path to your Unix domain socket and <url> with the target URL.
  - [P,NE,L,QSA]: These are flags that modify the behavior of the RewriteRule:
      - P: Proxy flag. This tells Apache to treat the substitution as a proxy request and forward it to the specified location.
      - NE: No Escape flag. This prevents Apache from escaping special characters in the substitution, useful when substituting URLs.
      - L: Last flag. This indicates that if the current rule matches, no further rules should be processed for this request.
      - QSA: Query String Append flag. This appends the original query string to the substituted URL.

Make sure to replace <path-to-socket> and <url> with your actual values. Additionally, ensure that the necessary modules (mod_headers and mod_rewrite) are enabled in your Apache configuration.

## Examples

* Unix
  - RewriteRule ^(.*)\$ unix:/home/jhz22/web.sock|http://localhost/\$1 [P,NE,L,QSA]
* TCP -- no headers
  - RewriteRule "^(.*)\$" http://localhost:8012/\$1 [P,NE,L,QSA]

## Raven authentication

Web: <https://docs.srcf.net/reference/web-hosting/raven-authentication/>

## Testing

First, install Python packages.

```python
python3 --version
pip install flask
pip install pyopenssl
```

Create a `app.py`

```python
from flask import Flask
import os

current_directory = os.path.basename(os.getcwd())
print("Enter Directory:", current_directory)

app = Flask(__name__)

@app.route('/')
def hello():
    current_directory = os.path.basename(os.getcwd())
    print("Current Directory:", current_directory)
    return 'Hello, ' + current_directory

if __name__ == '__main__':
    app.run(ssl_context='adhoc', port=11211, debug=True)
```

so as to run `python3 app.py`. The port can be visited as `https://127.0.0.1:4321` from a browser.

