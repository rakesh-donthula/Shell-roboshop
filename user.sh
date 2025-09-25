#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
START_TIME=$(date +%s)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-script/16-logs.log

mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script with root privelege"
    exit 1 # failure is other than 0
fi

VALIDATE(){ # functions receive inputs through args just like shell script args
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling nodejs"
dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enabling nodejs"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "installing nodejs"

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Adding user roboshop"
else
    echo -e "roboshop user... $Y Already Exists $N"
fi

mkdir /app 
curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downloading user application"
cd /app 
unzip /tmp/user.zip &>>$LOG_FILE
VALIDATE $? "unziping user file"
npm install &>>$LOG_FILE
VALIDATE $? "installing dependencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service &>>$LOG_FILE

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "reloading deamon"
systemctl enable user  &>>$LOG_FILE
VALIDATE $? "enabling user"
systemctl start user &>>$LOG_FILE
VALIDATE $? "starting user"

END_TIME=$(date +%s)

TOTAL_TIME=$(( $END_TIME - $START_TIME))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"
