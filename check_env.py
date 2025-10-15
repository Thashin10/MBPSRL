import sys
import traceback
modules = ['sys','numpy','gym','torch','tensorflow','scipy','tqdm','google.protobuf']

for m in modules:
    try:
        # support nested package names like 'google.protobuf'
        try:
            mod = __import__(m)
        except ImportError:
            # try importing nested packages
            mod = __import__(m, fromlist=['*'])
        v = getattr(mod, '__version__', None)
        print(f"{m}: OK, version={v}")
    except Exception as e:
        print(f"{m}: ERROR -> {e}")
        traceback.print_exc()

print('\nPython executable:', sys.executable)
print('Python version:', sys.version)
