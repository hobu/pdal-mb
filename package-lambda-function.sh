#!/bin/bash


#./package-lambda-function.sh pythonfile.py output.zip package_directory
#./package-lambda-function.sh lambda_function.py lambda_function.zip package

PYTHONFILE="$1"
OUTPUT="$2"
PACKAGE="$3"

echo "Updating $PYTHONFILE in $OUTPUT with package $PACKAGE in $AWS_REGION for $AWS_PROFILE"

rm $OUTPUT; zip $OUTPUT $PYTHONFILE
cd $PACKAGE; zip -r9 ../$OUTPUT .; cd ..
zip -g $OUTPUT $PYTHONFILE

