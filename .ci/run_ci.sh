#!/bin/bash -x
PKG_NAME=${1:-${DRONE_REPO##*/}}
rm -r /usr/local/lib/python*/dist-packages/${PKG_NAME}*  # pip uninstall is useless
set -e

for p in "${@:2}"
do
export CPATH=$p/include:$CPATH LIBRARY_PATH=$p/lib:$LIBRARY_PATH LD_LIBRARY_PATH=$p/lib:$LD_LIBRARY_PATH
done

git clean -xfd

python3 setup.py sdist
(cd dist/; python3 -m pip install $PKG_NAME-$(python3 ../setup.py --version).tar.gz)
(cd /; python3 -m pytest --pyargs $PKG_NAME)
(cd /; python3 -c "from pykinsol import get_include as gi; import os; assert 'kinsol_numpy.pxd' in os.listdir(gi())")

CXX=clang++-6.0 CC=clang-6.0 CFLAGS='-fsanitize=address' python3 -m pip install --force-reinstall .


PYTHONPATH=$(pwd) ./scripts/run_tests.sh
(cd examples/; jupyter nbconvert --to=html --ExecutePreprocessor.enabled=True --ExecutePreprocessor.timeout=300 *.ipynb)
(cd examples/; ../scripts/render_index.sh *.html)