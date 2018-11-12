#==========================================================================================#
#==========================================================================================#
#      This function is just a convenience function to convert RGB into colour names, with #
# default value being 255.                                                                 #
#------------------------------------------------------------------------------------------#
RGB <<- function(R,G,B) rgb(red=R,green=G,blue=B,maxColorValue=255)
#==========================================================================================#
#==========================================================================================#





#==========================================================================================#
#==========================================================================================#
#      This function is just a convenience function to convert HSV into colour names, with #
# default value being 0-360 for hue, and 0-100 for saturation and value.                   #
#------------------------------------------------------------------------------------------#
HSV <<- function(H,S,V) hsv(h=(H/360)%%1,s=0.01*S,v=0.01*V)
#==========================================================================================#
#==========================================================================================#
