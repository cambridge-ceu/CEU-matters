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

Note that it is `Listening at: http://127.0.0.1:8000`.

## References

(Notes here are based on [Chapter 6](../c6) of Farrell (2023), while Adedeji (2023) shall be relevant to REST API).

Farrell D. (2023) The Well-Grounded Python Developer-HOW THE PROS USE PYTHON AND FLASK. Manning Publications Co.

- [GitHub](https://github.com/writeson) [code](https://github.com/writeson/the-well-grounded-python-developer).
- [Live book](https://livebook.manning.com/book/the-well-grounded-python-developer/).

Adedeji O. (2023) Full-Stack Flask and React. Packt Publishing

- [GitHub](https://github.com/PacktPublishing/Full-Stack-Flask-and-React)
