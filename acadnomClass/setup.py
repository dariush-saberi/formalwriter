from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

ext_modules=[
    Extension("langmodel",         ["langmodel.pyx"]),
    Extension("nom",       ["nominalizerV8N.pyx"]),
    Extension("acadz",         ["academizerV3.pyx"]),
    Extension("freephrase",         ["freephrase.pyx"]),
]

setup(
  name = 'FormalWriter',
  cmdclass = {'build_ext': build_ext},
  ext_modules = ext_modules,
)
