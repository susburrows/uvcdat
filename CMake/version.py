import sys
import pkg_resources

if len(sys.argv) < 2:
  print >> sys.stderr, "Usage: python version.py <package name> <get_version>"
  sys.exit(1)

module = sys.argv[1]

try:
  pkg = pkg_resources.get_distribution(module)
  version = pkg.version
except pkg_resources.DistributionNotFound:
  try:
    if len(sys.argv) == 3:
      # import the module
      exec('import %s' % sys.argv[1])
      version = eval(sys.argv[2])
  except:
    sys.exit(2)

sys.stdout.write(version)
