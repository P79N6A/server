
# library name is derived from this file

name = (File.basename __FILE__).sub(/\.rb$/,'')

# Es search
# H  HTML
# K  constants
# N  naming
# Rb methods on Ruby native-types
# Th HTTP
# W  forms and formats
# Y  lambda-loading

%w{Y K Rb N W Th H Es}.map{|e| require name + '/' + e}
