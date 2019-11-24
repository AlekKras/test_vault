#!/bin/bash 

#Hook to verify that comments are not done to the master branch accidentally
#Need to check the status and exit the hook if this script exits with a non-zero code
#.git/hooks/pre-commit-master-no-no
#if [[ $? == 1 ]]
#then
#  exit 1
#fi

if [[ `git symbolic-ref HEAD` == "refs/heads/master" ]]
then
   if [[ ! -f /tmp/master_commit ]]
   then
    echo "*************************"
    echo "CANNOT COMMIT TO MASTER!"
    echo "To override this behavior"
    echo "touch /tmp/master_commit"
    echo "*************************"
    exit 1
   else
    echo "Removing /tmp/master_commit"
    rm /tmp/master_commit
   fi
fi