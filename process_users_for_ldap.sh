#!/bin/bash
# yikes!
# this is a script that will take a yaml file and create a list of users to add to a groupßßßß
#read password

MY_NUM_PROCS=8 # number of parallel processes to run

# make sure we have the temporary directory here 


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
#ldapmodify -h domcon02.czbiohub.org  -D "admin.rwhite@czbiohub.org" -Y GSSAPI -f users.ldif

exit 0

# more work will start here 
function main()
{
    #this is where everything happens
    # grab password 
    read MY_PASS
    echo ${MY_PASS} | kinit admin.rwhite # get a ticket
    MY_TMP_DIR=$(mktemp -d /dev/shm/ldap.XXXXXX)
    # findPatronsAndGenList 
    cat ${MY_PATRON_LIST} | xargs -I '{}' -P ${MY_NUM_PROCS} bash -c 'createShmUserFile ${MY_TMP_DIR} {}'
    # combine files   
}

main 

exit 0 

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
