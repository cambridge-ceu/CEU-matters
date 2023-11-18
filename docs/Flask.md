# Flask on SRCF

Tests are made under SRCF, where several aspects are required.

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

which includes a `Jinja2` template syntax.

## app.sh

```bash
export FLASK_ENV=development
export FLASK_APP=app.py

if [ ! -d templates ]; then mkdir templates; fi
flask run
```

## http://127.0.0.1:5000

Upon running flast using the default port 5000, it can be acessed via

```bash
firefox http://127.0.0.1:5000
```

It then produces the following output,

```
Current time: 2023-11-18 16:29:33.365224
```

## Reference

Farrell D. (2023) The Well-Grounded Python Developer-HOW THE PROS USE PYTHON AND FLASK, Chapter 6. Sharing with the internet. 89-112. Manning Publications Co.
