
# the table of elements

# Es search
# H  HTML
# K  constants
# N  naming
# Rb Ruby native-types
# Th HTTP
# W  forms and formats
# Y  lambdas

%w{Y K Rb N Es W H Th}.map{|e| require 'infod/' + e}
