### CREATES A "PUBLIC" VERSION OF THE REPLICATION PACKAGE
### BY REMOVING FILES MARKET AS CONFIDENTIAL WITH
### SUMMARY FILE INFORMATION.
### IN ADDITION, IT SPLITS ANY FILE EXCEEDING 4 GB INTO
### SUBPARTS SO THAT THE PACKAGE CAN BE UPLOADED
### TO DATAVERSE.

from datetime import datetime
import os
import pandas as pd
import shutil

def split_file(file_path, max_size=4 * 1024 * 1024 * 1024):
    """
    Splits a file into multiple parts if it exceeds max_size bytes.

    :param file_path: Path to the file to split.
    :param max_size: Maximum size of each part in bytes.
    :return: List of part filenames.
    """
    part_number = 1
    part_filenames = []
    with open(file_path, 'rb') as f:
        while True:
            chunk = f.read(max_size)
            if not chunk:
                break
            part_filename = f"{file_path}_part{part_number}"
            with open(part_filename, 'wb') as part_file:
                part_file.write(chunk)
            part_filenames.append(part_filename)
            part_number += 1
    return part_filenames

def create_readme(file_path, part_filenames):
    """
    Creates a _readme.txt file explaining how to rejoin the split parts.

    :param file_path: Path to the original file that was split.
    :param part_filenames: List of part filenames.
    """
    
    part_cleaned = []
    for f in part_filenames:
      part_cleaned.append(os.path.basename(f))
    readme_path = os.path.join(os.path.dirname(file_path), os.path.basename(file_path)+'_readme.txt')
    with open(readme_path, 'w') as f:
        f.write(f"The file '{os.path.basename(file_path)}' was split into parts because it exceeded 4 GB.\n\n")
        f.write("To rejoin the parts, use the following command:\n\n")
        f.write("Linux/Mac:\n")
        f.write("```sh\n")
        f.write("cat " + " ".join(part_cleaned) + f" > {os.path.basename(file_path)}\n")
        f.write("```\n\n")
        f.write("Windows:\n")
        f.write("```sh\n")
        f.write("copy /b " + " + ".join(part_cleaned) + f" {os.path.basename(file_path)}\n")
        f.write("```\n")

df = pd.read_csv('docs/files_in_repository.csv', keep_default_na=False)

pd.set_option('display.max_columns', 500)
pd.set_option('display.width', 1000)

path = '../public_platformpower/'
try:
    shutil.rmtree(path, ignore_errors=False, onerror=None)
except:
    1+1

cnt = 0

for index, row in df.iterrows():
    cnt += 1
    print(row['filename'], row['path'])
    os.makedirs(os.path.dirname(path + row['full_filepath']), exist_ok=True)

    if row['confidential'] == False:
        source_file_path = row['full_filepath']
        dest_file_path = path + row['full_filepath']
        
        # Check if the file exceeds 4GB and split if necessary
        if os.path.getsize(source_file_path) > 4 * 1024 * 1024 * 1024:
            part_filenames = split_file(source_file_path)
            for part_filename in part_filenames:
                shutil.copy2(part_filename, os.path.join(path, part_filename))
            create_readme(dest_file_path, part_filenames)
        else:
            shutil.copy2(source_file_path, dest_file_path)
    else:
        with open(path + row['full_filepath'] + '.txt', 'w') as f:
            f.write('This file replaces the original file (' + row['full_filepath'] + '), which has been marked as confidential and is only available upon request for the purpose of replication. For more information, see readme of this replication package.')
    
    #if (cnt > 50): break

print('done')

with open(path + 'log.txt', 'w') as f:
    f.write('Finished building public copy of repository.\n')
