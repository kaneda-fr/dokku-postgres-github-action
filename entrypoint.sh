#!/bin/bash

SSH_PRIVATE_KEY=$1
DOKKU_USER=$2
DOKKU_HOST=$3
DOKKU_APP_NAME=$4
DOKKU_DB_NAME=$5
DOKKU_DB_DESTROY=$6
AWS_ACCESS_KEY_ID=$7
AWS_SECRET_ACCESS_KEY=$8
AWS_REGION=$9
S3_DATA_LOAD=${10}
BACKUP_ACTIVATION=${11}
BACKUP_S3=${12}
BACKUP_S3_BUCKET=${12}
BACKUP_S3_SCHEDULE=${13}


export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=$AWS_REGION

# Setup the SSH environment
mkdir -p ~/.ssh
eval `ssh-agent -s`
ssh-add - <<< "$SSH_PRIVATE_KEY"
ssh-keyscan $DOKKU_HOST >> ~/.ssh/known_hosts

# Push to Dokku git repository
SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=ERROR $DOKKU_USER@$DOKKU_HOST"

if [ $DOKKU_DB_DESTROY == "true" ] ; then
  #  exit if no DB
  eval $SSH_COMMAND  postgres:exists $DOKKU_DB_NAME || exit 0

  # Unlink App
  eval $SSH_COMMAND postgres:linked $DOKKU_DB_NAME $DOKKU_APP_NAME && eval $SSH_COMMAND postgres:unlink $DOKKU_DB_NAME $DOKKU_APP_NAME

  # Destroy DB
  eval $SSH_COMMAND  postgres:exists $DOKKU_DB_NAME  && eval $SSH_COMMAND  postgres:destroy $DOKKU_DB_NAME  --force

else
  # Create App
  eval $SSH_COMMAND apps:exists $DOKKU_APP_NAME || eval $SSH_COMMAND apps:create $DOKKU_APP_NAME

  # Create DB
  eval $SSH_COMMAND postgres:exists $DOKKU_DB_NAME || eval $SSH_COMMAND postgres:create $DOKKU_DB_NAME

  # Link App to DB
  $SSH_COMMAND postgres:linked $DOKKU_DB_NAME $DOKKU_APP_NAME
  if [ $? -ne 0 ]; then

    eval $SSH_COMMAND postgres:link $DOKKU_DB_NAME $DOKKU_APP_NAME

    # Load data if
    if [ -n "$S3_DATA_LOAD" ] ; then
      if [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ] && [ -n "$AWS_DEFAULT_REGION" ]; then
        aws sts get-caller-identity
        if [ $? -eq 0 ]; then
          aws s3 cp $S3_DATA_LOAD - | $SSH_COMMAND postgres:import $DOKKU_DB_NAME
        else
          echo "Incorrect AWS keys"
        fi
      else
        echo "Missing AWS key"
        exit 1
      fi
    fi
  fi

  # Schedule backup
  if [ -n "$BACKUP_ACTIVATION" ] && [ $BACKUP_ACTIVATION == "true" ] ; then
    if [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ] && [ -n "$AWS_DEFAULT_REGION" ]; then
      aws sts get-caller-identity
      if [ $? -eq 0 ]; then
        eval $SSH_COMMAND postgres:backup-deauth mydb
        eval $SSH_COMMAND postgres:backup-auth $DOKKU_DB_NAME $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY $AWS_DEFAULT_REGION
        if [ -n "$BACKUP_S3_SCHEDULE" ] && [ -n "$BACKUP_S3_BUCKET" ]; then
          # args=(postgres:backup-schedule $DOKKU_DB_NAME "\\\"${BACKUP_S3_SCHEDULE}\\\"" $BACKUP_S3_BUCKET)
          # echo ${args[@]}
          # eval $SSH_COMMAND "${args[@]}"
          echo "*** Backup scheduling is not yet implemented ***"
        else
          echo "Missing backup schedule parameters: $BACKUP_S3_SCHEDULE - $BACKUP_S3_BUCKET"
          exit 2
        fi
      else
        echo "Incorrect AWS keys"
      fi
    else
      echo "Missing AWS keys"
      exit 1
    fi
  fi
  # unschedule backup
  if [ -n "$BACKUP_ACTIVATION" ] && [ $BACKUP_ACTIVATION == "false" ] ; then
    eval $SSH_COMMAND postgres:backup-schedule-cat $DOKKU_DB_NAME && eval $SSH_COMMAND postgres:backup-unschedule $DOKKU_DB_NAME
  fi

  echo "*** Backup Schedule:"
  eval $SSH_COMMAND postgres:backup-schedule-cat mydb
fi

exit 0
