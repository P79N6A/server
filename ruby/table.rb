
# the table of elements

name = (File.basename __FILE__).sub(/\.rb$/,'')

# Es search
# H  HTML
# K  constants
# N  naming
# Rb Ruby native-types
# Th HTTP
# W  forms and formats
# Y  lambdas

%w{Y K Rb N W Th H Es}.map{|e| require name + '/' + e}
