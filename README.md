# Dockerized GoPhish

Setting up and configuring GoPhish phishing system on Ubuntu Server with Docker.

---------------------------------------------------------------

Index:

  1. Preparation
  2. Installing GoPhish
  3. Docker Containers
  4. MariaDB - Databases
  5. GoPhish
  6. Dockerfile
  7. Warning
  8. Using GoPhish

Preparing the server, first we need a server with Ubuntu Server installed. [Ubuntu Server](https://ubuntu.com/download/server)
Once our server is installed correctly we will need the following:

  - OpenSSH: It will allow us to remotely connect to the server via ssh. (sudo apt install openssh-server)
  - Docker: We will create various containers to install GoPhish. (sudo apt install docker && sudo apt install docker.io)
  - UFW: We will use it as a firewall to open and block ports. (sudo apt install ufw)
  - Unzip: We will unzip GoPhish (sudo apt install unzip)
  - Maria DB: We will use it as a database (sudo apt install mariadb-server && sudo mysql_secure_installation)

```sh
  sudo apt install openssh-server
  sudo apt install docker && sudo apt install docker.io
  sudo apt install ufw
  sudo apt install unzip
  sudo apt install mariadb-server && sudo mysql_secure_installation
```

To activate the different services we will run the following commands:

```sh
$ sudo systemctl enable ssh
$ sudo ufw enable
$ sudo systemctl start docker
$ sudo systemctl start mariadb
```

The first thing we need to do is to connect via ssh to our remote server. From the server, we must grant access to a connection on port 22 (SSH), which can be done with the following command: ```ufw allow 22/tcp```.

With port 22 open to receive connections, we can now connect to our server with the following command: ssh -p 22 {user}@{ip} (replacing user with the username defined on the server or root, and ip with the server's public local ip address)

For added security, it is recommended to block connections to the server using root, use an SSH key, and use a remote connection port other than the default.

Now we will create a new user on our system and add it to Docker:

```sh
useradd -s /bin/bash -d /home/gophish-user/ -m -G docker gophish-user
```

Ports that will need to be open by default:

    3333/tcp: GoPhish Admin Panel
    9000/tcp: Portainer
    81/tcp: Campaigns

Open firewall rules:

```sh
root@sv:/home/gophish-user# ufw status
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere                  
3333/tcp                   ALLOW       Anywhere                  
9000/tcp                   ALLOW       Anywhere                  
81/tcp                     ALLOW       Anywhere 
```

# Installation of GoPhish

[Download](https://getgophish.com/)

[GitHub repository](https://github.com/gophish/gophish/releases)

Download the latest version of GoPhish(v0.12.1)

32-bit Linux: https://github.com/gophish/gophish/releases/download/v0.12.1/gophish-v0.12.1-linux-32bit.zip

64-bit Linux: https://github.com/gophish/gophish/releases/download/v0.12.1/gophish-v0.12.1-linux-64bit.zip

To download it faster:

For 32-bit Linux:
```sh
$ wget https://github.com/gophish/gophish/releases/download/v0.12.1/gophish-v0.12.1-linux-32bit.zip
```

For 64-bit Linux:
```sh
$ wget https://github.com/gophish/gophish/releases/download/v0.12.1/gophish-v0.12.1-linux-64bit.zip
```

Now, we will extract the zip file with the following command: ```$ unzip gophish-v0.12.1-linux-64bit.zip```
We will no longer need the compressed file so we can delete it: ```$ rm gophish-v0.12.1-linux-64bit.zip```

Now, to proceed with the installation of GoPhish, we will need to give execution permissions to the binary file and execute it.
To give execution permissions, we will use: ```$ chmod +x gophish```
And once we have permissions, we will execute it in the following way: ```$ sudo ./gophish```

Test campaign files and official documentation

Files to launch the test campaign

- landing.html
- campaign.html

# Docker Containers

Bitnami Web Server for images

The email images with the campaign are located on the local Ubuntu server at path /home/gophish-user/Docker/Gophish/
pache, which we attach as a volume (BIND):

```
docker run -d --restart always -p 8080:8080 -p 8443:8443 --name web_server -v ${HOME}/Docker/Gophish/apache:/opt/bitnami/apache2/htdocs/ bitnami/apache:latest
```

Create mysql_net bridge to be able to establish a connection.

```docker network create -d bridge mysql_net```

# MariaDB - Databases

We will need MariaDB and MySQL.

Volume: mariadb to mount the volume pointing to the Container path /var/lib/mysql

MySQL variables: 

- root_pwd = Mascl3tA
- db = gophish
- user = gophish2
- pwd = G0ph1sH

To add variables to our database we will have to execute MySQL in this way:

```sh
$ mariadb
```

And add variables like this:

```sql
SET @variable_name := value;
```

Docker command to add them:

```sh
docker run --restart always --network mysql_net --ip 192.169.0.2 --name mariadb -e MARIADB_ROOT_PASSWORD=Mascl3tA -v mariadb:/var/lib/mysql -d mariadb
```

Now we will access and create the user:

```sh
docker exec -it mariadb mysql -u root -p

...

MariaDB [(none)]> create database gophish;
MariaDB [(none)]> create user 'gophish2'@'%' identified by 'G0ph1sH';
MariaDB [(none)]> grant all privileges on gophish.* to 'gophish2'@'%';
MariaDB [(none)]> flush privileges;     

```

# GoPhish

GoPhish configuration file -> config.json


```json
{
        "admin_server": {
                "listen_url": "0.0.0.0:3333",
                "use_tls": true,
                "cert_path": "gophish_admin.crt",
                "key_path": "gophish_admin.key"
        },
        "phish_server": {
                "listen_url": "0.0.0.0:80",
                "use_tls": false,
                "cert_path": "example.crt",
                "key_path": "example.key"
        },
        "db_name": "mysql",
        "db_path": "gophish2:G0ph1sH@(192.169.0.2:3306)/gophish?charset=utf8&parseTime=True&loc=UTC",
        "migrations_prefix": "db/db_",
        "contact_address": "",
        "logging": {
                "filename": "",
                "level": ""
        }
}
```

For the configuration to be focused on a local environment, we would have to change the IP of admin_server and phish_server to our IP
local.
We can add our certificate (.crt) and our key (.key).

# Dockerfile

```Dockerfile

FROM gophish/gophish:latest
MAINTAINER Jet

USER root

ENV CONFIG_FILE config.json
ENV CRT_FILE example.crt
ENV KEY_FILE example.key

#RUN apt-get update && \
#        apt-get dist-upgrade -y && \
#        apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /opt/gophish

RUN mv config.json config.json.bkp

COPY config.json .
COPY example.com.crt .
COPY example.com.key .

RUN chown app: $CONFIG_FILERUN 
RUN chown app: $CRT_FILERUN 
RUN chown app: $KEY_FILE

EXPOSE 3333 81

ENTRYPOINT ["./gophish"]

Para crear la imagen de GoPhish : 
```
```sh
docker build -t gophish/gophish-user:latest .
```

Create the Gophish Container with the mysql_net network, then add bridge to the default network to raise the ports
and it connects to the outside and to finish I enter the Container and do an update (I ignore the error) and an upgrade:

```sh
docker run -d --name gophish --restart always --network mysql_net -p3333:3333 -p 81:81 gophish/user docker network connect bridge gophish
```

# Warning

When the Container is first created, the command ./gophish is automatically executed, and it outputs logs showing the admin user's password to access the system for the first time. You must use this password, and upon the first login, you will be prompted to change it. However, if the database already exists with the admin user's data, for example, if we need to delete the Container and start it up again without losing data, this step is not necessary since the credential is stored in the database.

Reports

GorePort.py, to obtain more visual reports than those offered by Gophish: https://github.com/chrismaddalena/Goreport. In the lib/goreport.py file, the texts generated by the system are changed because they come in English. Clone the Git repo: `git clone https://github.com/chrismaddalena/Goreport.git`. In the downloaded directory, create a Python virtual environment on any computer, activate it, and install the dependencies (the python-docx module gave me an error, so I commented it out in the text, and later I installed it manually without any problem: `python -m pip install python-docx`). 

```sh
$ cd Georeport

$ python3 -m pip install virtualenv
$ python3 -m virtualenv .my_project

$ . .my_project/bin/activate

$ python -m pip install --upgrade pip

$ python -m pip install -r requirements.txt
```

Then you create the gophish.config file and fill in the necessary data:

```sh
[Gophish]

gp_host: https://127.0.0.1:3333
api_key:<YOUR_API_KEY>

[ipinfo.io]ipinfo_token:<IPINFO_API_KEY>

[Google]
geolocate_key:<GEOLOCATE_API_KEY>
```

To obtain the reports you must check the ID of the campaign, for example https://95.216.210.150:3333/campaigns/3, the id is 3. We can obtain the reports in the following formats:

- Excel: python GoReport.py --id 3 --format excel
- Word: python GoReport.py --id 3 --format word

Infographics on Phishing:

https://www.wessii.com/infografias-phishing-y-suplantacion-de-identidad/

# Using GoPhish

We will use a case with Google

1. **Configure "Sending Profile"**

Name: Use the name you prefer. (Google)
Interface Type: Always use SMPT to use a mail web server.
From: A valid email address. (example@gmail.com)
Host: SMPT server link. (smpt.gmail.com:587)
Username: Use the username you prefer. (example@gmail.com)
Password: Your mail account password. (Ex: Example123)

It is recommended to send the available test email to check that everything has worked correctly. [victim: (subject position)]

SAVE.

2. **Configure "Landing Page"**

Name: Name of the website being cloned. (Google)
Press import site and enter the URL of the website you are going to clone.
Check "Capture Submitted Data" to receive the data collected from the victim.
Check "Capture passwords" to collect the victim's passwords. Passwords will be displayed as plain text if you don't use SSL.
Redirect to: Will redirect to the site once the password has been sent. (google.com/login)

SAVE.

3. **Email Templates**

Name: Enter the name you will use for the email (Google)
Import Email: Copy the source code of the email content and paste it to have a completed email.
Check "Change Links to point to Landing Page". It will be redirected to our landing page.
If you don't want to import an email, you will have to do this entire process manually.
Check "Add Tracking Image".
Add files to the email.

SAVE.

4. **"Groups" Configuration**

Name: Name of the group (victims)
Enter a name, last name, email address, and subject. And press ADD.

SAVE.

5. **"Campaigns" Configuration**

Name: Any name. (Google)
Email Template: Set an email template. (Google)
Landing Page: Select a name. (Google)
URL: Set the url you are using for the phishing attack (http:0.0.0.0:80 -> Default)
Sending profile: Select a sending profile. (Gmail)
Groups: Add a group.

LAUNCH CAMPAIGN.

It will start sending to the group. When the data is in, it will be accessible.

