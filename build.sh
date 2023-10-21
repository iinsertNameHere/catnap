echo "Generating build venv ..."
python3 -m venv ./buildenv
source ./buildenv/bin/activate
mkdir ./build

echo "Updating pip ..."
pip install --upgrade pip

echo "Installing cython ..."
pip3 install cython

echo "Generating main.c ..."
cython catnip.py -o ./build/main.c -3 --embed

echo "Compiling main.c ..."
PYTHONLIBVER=python$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')$(python3-config --abiflags)
gcc -Os $(python3-config --includes) ./build/main.c -o ./build/catnip $(python3-config --ldflags) -l$PYTHONLIBVER

echo "Cleaning up ..."
deactivate
rm -rf ./buildenv

echo "Finished!"