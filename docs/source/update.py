'''
Opsero Electronic Design Inc.

When data.json is updated with new information, this Python script can be run to update
the main README.md file of the repo. We use this to make sure that the target design
information is consistent in all parts of the documentation.
Potentially we can also use this to update the makefiles and the .gitignore when we
add new target designs.
'''

import os
import json

# Load the JSON data
def load_json():
    with open('data.json') as f:
        return json.load(f)

# Create design tables for the README.md file
# This function determines the formatting of the design tables
def create_tables(data):
    tables = []
    links = {}
    for group in data['groups']:
        tables.append('### {} designs'.format(group['name']))
        tables.append('')
        tables.append('| Target board          | Target design   | M2 ports    | FMC Slot    | License<br> required |')
        tables.append('|-----------------------|-----------------|-------------|-------------|-------|')
        for design in data['designs']:
            if 'group' not in design:
                print('group not in design:',design)
            if design['group'] == group['label']:
                col1 = '[{0}]'.format(design['board']).ljust(21)
                col2 = '`{0}`'.format(design['label']).ljust(15)
                col3 = '{0}'.format(design['ports']).ljust(11)
                col4 = '{0}'.format(design['connector']).ljust(11)
                col5 = '{0}'.format(design['license']).ljust(5)
                tables.append('| {0} | {1} | {2} | {3} | {4} |'.format(col1,col2,col3,col4,col5))
                links[design['board']] = design['link']
        tables.append('')
    # Add the board links
    for k,v in links.items():
        tables.append('[{0}]: {1}'.format(k,v))
    return(tables)

# Update the README.md file target design tables
def update_readme(file_path,data):
    # Read the content of the file
    with open(file_path, 'r') as infile:
        lines = infile.readlines()

    # Open the same file in write mode to overwrite it
    with open(file_path, 'w') as outfile:
        inside_updater = False

        for line in lines:
            if '<!-- updater start -->' in line:
                # Write the start tag to the file
                outfile.write(line)
                # Write the tables
                tables = create_tables(data)
                for l in tables:
                    outfile.write("{}\n".format(l))
                inside_updater = True
            elif '<!-- updater end -->' in line:
                # Write the end tag to the file
                outfile.write(line)
                inside_updater = False
            elif not inside_updater:
                # Write the line if not inside the updater block
                outfile.write(line)

data = load_json()
file_path = '../../README.md'
update_readme(file_path,data)

