# syntax=docker/dockerfile:1

# The Dockerfile specifies how to build a docker container containing our
# application. Dockerfiles specify the build process in multiple layers - 
# this helps optimize the build process, as we can start from a cached layer 
# build if lower layers have not changed.

# LAYER 1 - Starting Image

# Start from an image (a serialized machine) running linux with dotnet 6.0
# pre-installed. This will be downloaded from a microsoft server, and will 
# be the largest part of our image (so we want to only do it once). We'll also 
# give this image a name - "build-env" as it is the environment within which
# we will build our application
FROM mcr.microsoft.com/dotnet/sdk:6.0 as build-env

# LAYER 2 - Application Code

# For this layer, we copy our application code into the src directory so that 
# we have everything needed for our application in the image. This is also where
# development and production images start to have differences.  

# We first copy the complete source code
COPY . ./

# Then we run the dotnet restore command to install those project dependencies
# This step will not need to be repeated unless the dependencies change
RUN dotnet restore src/

# Now we built our release.  We'll ouput this to a top-level /out directory.
RUN dotnet publish src/ -c Release -o out

# IMAGE 2 

# Now we actually create a *second* image - this one should contain *only* the
# release files and any necessary support. We will copy the release files into 
# it, and then we can abandon our build environment.

# We'll start from a clean image - note that we use the aspnet image, which 
# contains only the runtime aspnet support instead of the full sdk.  This 
# keeps our image as lightweight as possible.
FROM mcr.microsoft.com/dotnet/aspnet:6.0

# We set a working directory - in this case, we'll put our app files in the App
# directory, wich will make it easy to find if we ever need to manually open the 
# image.
WORKDIR /App

# We then copy our production build from the previous image into the App directory.
COPY --from=build-env /out .

EXPOSE 80

# Finally, the entry  point tells a Docker host how to launch our application.
# This is essentially a list of command line arguments, i.e.
#  $ dotnet K12OutreachMap.dll
ENTRYPOINT ["dotnet", "K12OutreachMap.dll"]