#!/bin/bash
## ## ## ## 
# this is a script that will take a yaml file and create a list of users to add to a groupßßßß

MY_NUM_PROCS=8 # number of parallel processes to run

# make sure we have the temporary directory here 

# associative arrays for groups and projects 
declare -A GROUP_HMAP
declare -A PROJECT_HMAP

PROJECT_OLD_MEMBERS_KEY="old.members"
PROJECT_NAME_KEY="project"

## ## 
PROJECT_NAME="TEST_PROJECT"


function processGroupAssociations()
{

    local declare -A INT_PROJECT_HMAP
    local declare -A INT_PROJECT_HMAP


}

function extractGroups()
{
    
    local MY_YAML_DATA=$1    
    echo ${MY_YAML_DATA} | yq 'to_entries | .[] | .key' | sed 's/${PROJECT_NAME_KEY}//g' | sed 's/${PROJECT_OLD_MEMBERS_KEY}//g'

}

function ingestYamlFile ()
{
    local MY_YAML_FILE=$1

    if [ -f $MY_YAML_FILE ]; then
      local MY_VC=$(cat $MY_YAML_FILE)
      echo ${MY_VC}
      exit 0
    else
        echo "The file $MY_YAML_FILE does not exist"
        exit 1
    fi
}



function testIfBashVersionIsRight ()
{
# this function tests to see if the bash version is greater than 4
    echo $BASH_VERSION | grep -qE '^[4-9]' || { echo "This script requires bash version 4 or greater"; exit 1; }
}


function testIfCommandsExist ()
{
# this function tests to see if the commands we need are available
local MY_COMMANDS=(yq wget ldapsearch ldapmodify kinit xargs awk sort cat grep sed)

for i in ${MY_COMMANDS[@]}; do
    if ! command -v $i &> /dev/null
    then
        echo "$i could not be found"
        exit 1
    fi
done


}


function findGroup ()
{
# this function will find the group in the yaml file
local MY_GROUP=$1


}


# creat dirs
# process yaml file
# create array of entries 
# create a tmp file for each entry and process each entry


function createShmUserFile()
{

local $MY_WORK_DIR=$1
local $MY_FILE_NAME=$MY_WORK_DIR/$(uuidgen).ldif
cat << EOF > $MY_WORK_DIR/$(uuidgen).ldif
dn: CN=group.tlg.icd,OU=BiohubSecurityGroups,DC=czbiohub,DC=org
changeType: modify
add: member
$MY_USER_LINE
EOF

return $MY_FILE_NAME

}

function findPatronsAndGenList()
{

for user in $(<group.tlg.icd.members); 
do 

ldapsearch -h domcon02.czbiohub.org    -b "DC=czbiohub,DC=org"    -D "admin.rwhite@czbiohub.org"    -O "maxssf=256,minssf=256" -Y GSSAPI "sAMAccountName=${user}" dn 2>/dev/null | grep -A 1 "^dn:" | sed 's/dn:/member:/g'

done > group.tlg.icd.members.dn



}



# export functions here 
export -f createShmUserFile

cat /exa1/hpc/projects/intracellular_dashboard/project_people.yaml | awk '/^  -/ {print $2}' | sort -u > group.tlg.icd.members




cat group.tlg.icd.members.dn | xargs -I '{}' ldapmodify -h domcon02.czbiohub.org  -D "admin.rwhite@czbiohub.org" -Y GSSAPI -f << EOF 
dn: CN=group.tlg.icd,OU=BiohubSecurityGroups,DC=czbiohub,DC=org
changeType: modify
add: member
'{}'
EOF



# combine files 
#cat header.ldif group.tlg.icd.members.dn > users.ldif

# add the users to the group

exit 0

# more work will start here 
function main()
{ 

    # first find out if we are running zsh or bash? 
    echo $SHELL | grep zsh  &> /dev/null || 
    { 
        #since we are not running zsh, we can test the bash version

        testIfBashVersionIsRight #test to see if the bash version is right
                
    }
    
    testIfCommandsExist #test to see if our commands exists on the platform

    # grab the yaml file
    MY_PATRON_YAML_LIST=$(ingestYamlFile $1)

    # now read the password
    echo "Please enter your kerberos password: " # get password
    read MY_PASS

    # authenticate via kerberos
    echo ${MY_PASS} | kinit admin.rwhite # get a ticket
    MY_TMP_DIR=$(mktemp -d /dev/shm/ldap.XXXXXX)

    # findPatronsAndGenList 
    cat ${MY_PATRON_LIST} | xargs -I '{}' -P ${MY_NUM_PROCS} bash -c 'createShmUserFile ${MY_TMP_DIR} {}'
    # combine files   
}

# run the main function
main 

exit 0 


# yq '.project' data.yml grab the project name

cat << EOF > ./somefile.ldif
dn: CN=group.bioengineering,OU=BiohubSecurityGroups,DC=czbiohub,DC=org
changeType: modify
add: member
member: CN=Deepika Sundarraman,OU=Employee,OU=BiohubUsers,OU=CZ Biohub SF,DC=czbiohub,DC=org

EOF

ldapmodify -h domcon02.czbiohub.org  -D "admin.rwhite@czbiohub.org" -Y GSSAPI -f somefile.ldif


One jbod is missing 12 disks. John needs to investigate exactly whats going on.
We'll try it and if it doesn't. Work well .
Starfish guys -> CZii settled down into their role of working
CZID data movements -> Look more into Amazon stuff -> temporary spot to set storage might be needed.



'to_entries | .[] | .key'