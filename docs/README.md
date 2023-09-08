# Documentation for the example designs

The documentation for these example designs is hosted at <https://refdesign.fpgadrive.com>
and it is best viewed from there. This folder of the repo contains the sources for the 
documentation, and we strongly encourage you to contribute to the documentation if you're
interested in doing so. To contribute, you can modify these sources and then make a pull
request to this repository on Github.

## How to build the docs locally

These instructions will help you to get setup to build the docs locally on your
machine. It is intended for people that wish to contribute to the documentation. If you
only wish to view the documentation, then please view it [here](https://refdesign.fpgadrive.com).

To build the documentation locally, you will need to have Python 3 with and Sphinx, MyST parser 
and the ReadTheDocs Sphinx theme installed. For this guide, we'll assume that you are using Linux 
and that it already has Python 3 installed. Ideally we would create a virtual environment and 
install all the packages we need into it using pip:

1. Install `python3-venv` (typically, it's already installed):

```
sudo apt install python3-venv -y
```

2. Create a virtual environment:

```
mkdir sphinx_venv
cd sphinx_venv
python3 -m venv sphinx_venv
```

3. Activate the virtual environment:

```
cd ..
source sphinx_venv/bin/activate
```

4. In the active virtual environment, install Sphinx, MyST and the ReadTheDocs Sphinx theme:

```
pip install -U sphinx
pip install myst-parser
pip install sphinx-rtd-theme
```

5. Build the docs:

```
cd <path-of-this-repo>/docs
make html
```

To view the locally generated docs, just browse to `<path-of-this-repo>/docs/build/html` and open
the `index.html` in a web browser. Each time you wish to rebuild the docs, you just need to run
`make html` and it will work as long as you have activated the virtual environment first.

