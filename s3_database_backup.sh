#!/bin/bash
   #===============================================================================================================
   #                                                                                                                                              
   #         FILE: s3_database_backup.sh
   #
   #        USAGE: Run it
   #
   #  DESCRIPTION: 6.5 S3 backups for databases
   #      OPTIONS:  
   # REQUIREMENTS: Set AWS creds and S3 bucket
   #       AUTHOR: Matt DeMarco (matt@memsql.com)
   #      CREATED: 07.10.2018
   #      VERSION: 1.0
   #      EUL    : 	THIS CODE IS OFFERED ON AN “AS-IS” BASIS AND NO WARRANTY, EITHER EXPRESSED OR IMPLIED, IS GIVEN. 
   #				THE AUTHOR EXPRESSLY DISCLAIMS ALL WARRANTIES OF ANY KIND, WHETHER EXPRESS OR IMPLIED.
   #				YOU ASSUME ALL RISK ASSOCIATED WITH THE QUALITY, PERFORMANCE, INSTALLATION AND USE OF THE SOFTWARE INCLUDING, 
   #				BUT NOT LIMITED TO, THE RISKS OF PROGRAM ERRORS, DAMAGE TO EQUIPMENT, LOSS OF DATA OR SOFTWARE PROGRAMS, 
   #				OR UNAVAILABILITY OR INTERRUPTION OF OPERATIONS. 
   #				YOU ARE SOLELY RESPONSIBLE FOR DETERMINING THE APPROPRIATENESS OF USE THE SOFTWARE AND ASSUME ALL RISKS ASSOCIATED WITH ITS USE.
   #
   #
   #
   #
   #
   #
   #===============================================================================================================

export BACKUPTIME=$(date +%m_%d_%y_%H%M)

function AWS_CREDS()
{
   if [ -z "$ACCESS_KEY" ];
   then
      echo "Please set your AWS ACCESS_KEY:"
      read ACCESS_KEY
   else
      echo "AWS ACCESS_KEY set to: " $ACCESS_KEY
   fi

   if [ -z "$SECRET_KEY" ];
   then
      echo "Please set your AWS SECRET_KEY:"
      read SECRET_KEY
   else
      echo "AWS SECRET_KEY set to: " $SECRET_KEY
   fi

   if [ -z "$AWS_REGION" ];
   then
      echo "Please set your AWS REGION:"
      read AWS_REGION
   else
      echo "AWS REGION set to: " $AWS_REGION
   fi
   
}

function GET_S3BUCKET()
{
   if [ -z "$S3BUCKET" ];
   then
      echo "Please set your AWS S3 BUCKET for backup location."
      read S3BUCKET
      echo "AWS S3 backup location set to: " $S3BUCKET
   else
      echo "AWS S3 backup location set to: " $S3BUCKET
   fi

}

function GET_DATABASES()
{

   DATABASELIST='/tmp/backupdb.lst'
   if [ -e "$DATABASELIST" ];
   then
      sudo rm -v $DATABASELIST
   else
      echo 'Moving on...'
   fi

   memsql -u root<<EOF
   select 
      schema_name
   from
      information_schema.schemata 
   where schema_name not in ('information_schema','memsql','cluster')
   into outfile '/tmp/backupdb.lst'
EOF

cat $DATABASELIST

}


function MAKE_BACKUP_SCRIPT()
{
   for dbname in $(cat $DATABASELIST)
   do echo $dbname

   memsql -u root --silent<<EOF
   tee /tmp/S3BACKUP_$BACKUPTIME.sql
   select
 
      concat
      ('BACKUP DATABASE $dbname to S3 "$S3BUCKET/$BACKUPTIME/" CONFIG ')
      ,
      concat
      ("'{")
      ,
      concat
      ('"region":')
      ,
      concat
      ('"$AWS_REGION"')
      ,
      concat
      ("}' CREDENTIALS ")
      ,
      concat
      ("'{")
      ,
      concat
      ('"aws_access_key_id":')
      ,
      ('"$ACCESS_KEY",')
      ,
      concat
      ('"aws_secret_access_key":')
      ,
      concat
      ('"$SECRET_KEY"')
      ,
      concat
      ("}' ; ")
      
      /*
      into outfile
      '/tmp/$dbname_$BACKUPTIME.sql'
      */

EOF

done
}


function BACKUP_DB()
{

   memsql -u root </tmp/S3BACKUP_$BACKUPTIME.sql

}

function LIST_BACKUPS()
{
   memsql -u root -e'select * from information_schema.mv_backup_history'
}

function RUN()
{
   AWS_CREDS
   GET_S3BUCKET
   GET_DATABASES
   MAKE_BACKUP_SCRIPT
   BACKUP_DB
   LIST_BACKUPS

}

# let's do this...
RUN







