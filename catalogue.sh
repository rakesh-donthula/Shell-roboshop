#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
MONGODB_HOST="mongodb.expense.icu"
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-script/16-logs.log

mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script with root privelege"
    exit 1 # failure is other than 0
fi

VALIDATE(){ # functions receive inputs through args just like shell script args
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" 
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" 
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE

dnf module enable nodejs:20 -y &>>$LOG_FILE

dnf install nodejs -y &>>$LOG_FILE

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE

mkdir /app 

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  &>>$LOG_FILE

cd /app 

unzip /tmp/catalogue.zip &>>$LOG_FILE

npm install  &>>$LOG_FILE

cp catalogue-service /etc/systemd/system/catalogue.service

systemctl daemon-reload &>>$LOG_FILE

systemctl enable catalogue  &>>$LOG_FILE
systemctl start catalogue &>>$LOG_FILE

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding Mongo repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE

mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE

systemctl restart catalogue &>>$LOG_FILE
VALIDATE $? "Catalogue.... $G Restarted $N"