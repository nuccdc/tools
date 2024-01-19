#!/bin/bash

# Pass in the file/dir you want to scan as the only argument
clamscan -i -d Cobalt_Strike_and_Sliver.yara -r $1
