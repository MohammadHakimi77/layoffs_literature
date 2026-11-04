from zipfile import ZipFile

with ZipFile('../externals/chartmetric.zip', 'r') as zipObj:
  # Extract all the contents of zip file in different directory
  zipObj.extractall('../externals/')
