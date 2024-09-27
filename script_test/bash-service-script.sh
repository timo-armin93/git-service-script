#!/bin/bash

# handling for errors
set -bE

# gitRepo=$1;service1=$2;service2=$3;service3=$4 # store arguments as values


# function for display of usage description
usage() { 
    echo "Usage: $0 <git_repo> <service_1> <service_2> <service_3>" 
}

# check if correct number of arguments
if [ "$#" -le 4 ]; then
    usage
else 
echo "too many args. You have $#, only 4 is allowed"
exit 1 
fi

# create temp dir
temp_repo="$HOME/temp_repo"

if [ -d $temp_repo ];then 
    \rm -rf $temp_repo
fi
mkdir -p $temp_repo && cd $temp_repo    

# function for git handling

git_handler(){
    
    git_repo="$1"
    services=("${@:2}") # start from second element to end
    git config user.name
  
  # clone git repo to temp directoy
    git clone "$git_repo" ${temp_repo}
    cp $HOME/list_directories.txt $HOME/list_markdown.txt $HOME/data.txt ${temp_repo}

    # Set user email address and name for the current repo
    git -C "${temp_repo}" config user.email "$email"
    git -C "${temp_repo}" config user.name "$name"
    
    # make changes to temp file
    file_to_add=${temp_repo}/test_example.txt
   
    echo "Hello Hello World!" > ${file_to_add}
    cd $temp_repo && git add $file_to_add $temp_repo/list_directories.txt $temp_repo/list_markdown.txt
 
    cd $temp_repo && git commit -m "test to commit txt file to dir"
    cd $temp_repo &&  git status && git log 
    cd $temp_repo && git branch -M main && git push -u origin main
}

# find and create list for directory and markdown
list_handling() {
    # find all directories in temp repo and save list
    find ${temp_repo} -type d > list_directories.txt
    
    # list the content of the file
    ls -l list_directories.txt
    
    # find all directories in temp repo with .md type and save list
    find ${temp_repo} -type f -name "*.md" > list_markdown.txt
    
    # list the content of the file
    ls -l list_directories.txt list_markdown.txt
   
    # remove files
   \rm list_directories.txt list_markdown.txt
   
   # check status
   if [ $? -eq 0 ]; then echo "List handling OK" ;else echo "List handling NOT OK";exit 1 ;fi

}

file_sorting() {
    # sort files by size 
    # find data.txt file in temp repo and sort first column
    find ${temp_repo} -name "data.txt" -exec sort -g -k1 {} + > ${temp_repo}/data_sorted.txt

ls -l ${temp_repo}/data.txt
    # calculate sum of each row in data.txt
    # print each row
    # save output to new file 
    awk '{for(x=1;x<=NF;x++) sum+=$x ;print NR":"$0"\tsum="sum;if (x=NF){sum=0}} ' $(find ${temp_repo} -name "data.txt") > ${temp_repo}/data_summed_and_sorted.txt
    
    # check status
    if [ $? -eq 0 ]; then echo "File sorted OK" ;else echo "File sorted not OK";exit 1 ;fi
}

collect_system_info() {
    # CPU model and manufacturer - save to file
    lscpu | egrep '^Vendor|^Model' > ${temp_repo}/system_cpu.txt

    # available RAM - save to file
    free -h | egrep '^M'| awk '{print $2}' > ${temp_repo}/system_ram.txt

    # current IPv4 address - save to file
    ip addr show |awk '/inet .*global/ {print $2}' > ${temp_repo}/system_ipv4.txt

    # current running processes - save to file
    top -n 1 > system_processes.txt
    
    # check status
    if [ $? -eq 0 ]; then echo "Collected info" ;else echo "Not able to collect info" ;exit 1 ;fi

}


handle_systemd_services() {
    # check all args
    services=("$@")
    
    mkdir -p ${temp_repo}/services
    
    # iterate over each service in service array
    for service in "${services[@]}"; do
        echo ${service}
        
        # save ouput to file and check status
        systemctl status "${service}" > "${temp_repo}/services/${service}.status"
        if [ $? -eq 0 ]; then echo "Service is ok" ;else echo "Service is NOT ok" ;exit 1 ;fi

    done
}

file_listing() {
    # list files by size
    ls -lsa ${temp_repo} > ${temp_repo}/sizes.txt
}

handle_systemd_services_dependencies() {
    # create new dir in temp repo
    mkdir -p ${temp_repo}/service_dependencies
    
    # iterate over running services and print first row 
    # list dependencies and save to service list-dependencies
    for i in $(systemctl --type=service --state=running | awk '/loaded active running/{print $1}'); do systemctl list-dependencies $i > ${temp_repo}/service_dependencies/$i.txt;done
    
    # check status
    if [ $? -eq 0 ]; then echo "Service list-dependencies is ok" ;else echo "Service list-dependencies is NOT ok" ;exit 1 ;fi
}

file_cleanup() {
    echo "cleaning up file..."
    
    # remove temp repo
    rm -rf "${temp_repo}"
    
    echo "file cleaned"
}


git_handler "$@"

collect_system_info

list_handling

file_sorting

handle_systemd_services "${@:2}"

handle_systemd_services_dependencies

echo ${temp_repo} ;ls -ltra ${temp_repo}
trap file_cleanup EXIT
