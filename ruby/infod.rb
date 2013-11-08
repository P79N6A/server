
# the table of elements

# Es infrastructure
# H  HTML
# K  constants
# N  naming
# Rb Ruby native-types
# Th HTTP
# Y  lambdas

%w{Y K Rb N Es H Th}.map{|e| require 'infod/' + e}
