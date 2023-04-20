# GoPhish Dockerizado

Montando y configurando sistema de phishing GoPhish en sistema Ubuntu Sever con Docker.

---------------------------------------------------------------

Índice :

  1. Preparación
  2. Instalación de GoPhish
  3. Containers de Docker
  4. MariaDB - Bases de datos
  5. GoPhish
  6. Dockerfile
  7. Advertencia
  8. Uso de GoPhish

Preparando el servidor, lo primero necesitaremos un servidor con Ubuntu Server instalado. [Ubuntu Server](https://ubuntu.com/download/server)
Cuando nuestro servidor esté instalado correctamente necesitaremos lo siguiente :

  - OpenSSH : Nos permitirá la conexión remota al servidor mediante ssh. (sudo apt install openssh-server)
  - Docker : Crearemos diversos contenedores para instalar GoPhish. (sudo apt install docker && sudo apt install docker.io)
  - UFW : Lo usaremos como firewall para abrir y bloquear puertos. (sudo apt install ufw)
  - Unzip : Descomprimiremos GoPhish (sudo apt install unzip)
  - Maria DB : Lo utilizaremos como base de datos (sudo apt install mariadb-server && sudo mysql_secure_installation)
  
  ```sh
  sudo apt install openssh-server
  sudo apt install docker && sudo apt install docker.io
  sudo apt install ufw
  sudo apt install unzip
  sudo apt install mariadb-server && sudo mysql_secure_installation
```
Para activar los distintos servicios ejecutaremos los siguientes comandos:

```
$ sudo systemctl enable ssh
$ sudo ufw enable
$ sudo systemctl start docker
$ sudo systemctl start mariadb
```

Lo primero de todo sera conectarnos mediante ssh a nuestro servidor remoto. Desde el servidor deberemos dar acceso a una conexión en el puerto 22(SSH), lo podemos ejectuar con el siguiente comando : ```ufw allow 22/tcp```.

Con el puerto 22 ya abierto para recibir conexiones ya podremos conectarnos a nuestro servidor con el siguiente comando : ```ssh -p 22 {usuario}@{ip}``` (Sustituyendo usuario por el nombre de usuario definido en el servidor o root y la ip por la ip local
publica del servidor)

Para más seguridad se recomienda bloquear las conexiones al servidor mediante root, utilizar una clave SSH y utilizar un puerto de conexión remota distinto al predeterminado.

Ahora crearemos un usuario nuevo en nuestro sistema y lo añadiremos a Docker : 
```sh
useradd -s /bin/bash -d /home/gophish-user/ -m -G docker gophish-user
```

Puertos que requerirán estar abiertos de manera predeterminada:

- 3333/tcp : Admin Panel GoPhish
- 9000/tcp : Portainer
- 81/tcp : Campañas

Reglas de la Firewall abiertas:
```
root@sv:/home/gophish-user# ufw status
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere                  
3333/tcp                   ALLOW       Anywhere                  
9000/tcp                   ALLOW       Anywhere                  
81/tcp                     ALLOW       Anywhere     
```
# Instalación de GoPhish

[Descargar](https://getgophish.com/)

[Repositorio de GitHub](https://github.com/gophish/gophish/releases)

Descargar la versión mas reciente de GoPhish(v0.12.1)

Linux de 32 Bits : https://github.com/gophish/gophish/releases/download/v0.12.1/gophish-v0.12.1-linux-32bit.zip

Linux 64 Bits : https://github.com/gophish/gophish/releases/download/v0.12.1/gophish-v0.12.1-linux-64bit.zip

Para descargarlo de manera más rápida:

Para Linux de 32 Bits:
```sh
$ wget https://github.com/gophish/gophish/releases/download/v0.12.1/gophish-v0.12.1-linux-32bit.zip
```

Para Linux de 64 Bits:
```sh
$ wget https://github.com/gophish/gophish/releases/download/v0.12.1/gophish-v0.12.1-linux-64bit.zip
```

Ahora, extraeremos el archivo zip con el siguiente comando : ```$ unzip gophish-v0.12.1-linux-64bit.zip```
Ya no necesitaremos el comprimido así que podemos eliminarlo : ```$ rm gophish-v0.12.1-linux-64bit.zip```

Ahora, para proceder con la instalación de GoPhish tendremos que darle permisos de ejecución al archivo binario y ejecutarlo.
Para darle permisos de ejecución usaremos : ```$ chmod +x gophish```
Y una vez ya con permisos, lo ejecutaremos de la siguiente manera : ```$ sudo ./gophish```

Archivos de campña test y documentación oficial

Archivos para lanzar la campaña de prueba

- landing.html
- campaign.html

# Containers de Docker

Servidor Web Bitnami para imágenes

Las imágenes del email con la campaña se encuentran en el servidor local de Ubunto en el path/home/gophish-user/Docker/Gophish/
pache, el cual atachamos como volumen (BIND):

```sh
docker run -d --restart always -p 8080:8080 -p 8443:8443 --name web_server -v ${HOME}/Docker/Gophish/apache:/opt/bitnami/apache2/htdocs/ bitnami/apache:latest
```

Crear mysql_net bridge para poder esablecer una conexión.

```docker network create -d bridge mysql_net```

# MariaDB - Bases de datos

Necesitaremos MariaDB y MySQL.

Volume: mariadb para montarle el volumen apuntando al path del Container /var/lib/mysql

Variables MySQL : 

- root_pwd = Mascl3tA
- db = gophish
- user = gophish2
- pwd = G0ph1sH

Para añadir variables a nuestra base de datos tendremos que ejecutar MySQL de esta manera:
```sh
$ mariadb
```
Y añadir variables así :
```sql
SET @variable_name := value;
```

Comando Docker para añadirlas :
```sh
docker run --restart always --network mysql_net --ip 192.169.0.2 --name mariadb -e MARIADB_ROOT_PASSWORD=Mascl3tA -v mariadb:/var/lib/mysql -d mariadb
```
         
Ahora accederemos y crearemos el usuario : 
```sh
docker exec -it mariadb mysql -u root -p

...

MariaDB [(none)]> create database gophish;
MariaDB [(none)]> create user 'gophish2'@'%' identified by 'G0ph1sH';
MariaDB [(none)]> grant all privileges on gophish.* to 'gophish2'@'%';
MariaDB [(none)]> flush privileges;     

```

# GoPhish

Fichero de configuracion de GoPhish -> config.json

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
Para que la configuración sea enfocada a un entorno local habría que cambiar la IP de admin_server y phish_server a nuestra IP
local.
Podremos añadir nuestro certificado(.crt) y nuestra llave(.key). 

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

Crear el Container de Gophish con la red de mysql_net, le agrego luego a la red por defecto bridgepara que levante los puertos
y se conecte con el exterior y para finalizar entro a el Container yhago un update (ignoro el error) y un upgrade:

```sh
docker run -d --name gophish --restart always --network mysql_net -p3333:3333 -p 81:81 gophish/user docker network connect bridge gophish
```

# Advertencia

Cuando se crea por primera vez el Container se ejecuta automáticamente elcomando ./gophish, y este lanza unos logs en donde mue
tran la contraseña del usuario admin paraacceder por primera vez al sistema. Hay que usar esta y en el primer login ya te pide
cambiarla. Si porel contrario la base de datos ya existe con los datos de usuario admin, por ejemplo si tenemos queeliminar el
Container y levantarlo de nuevo pero sin perder datos, este paso no es necesario ya que semantiene la credencial guardada en la
base de datos.

Reportes

GorePort.py, para obtener reportes más visuales que los ofrecidos por Gophish : https://github.com/chrismaddalena/GoreportEn el
archivo lib/goreport.py se cambian los textos que genera el sistema, porque vienen en inglés. Clonamos el repo de Git : ```git
clone https://github.com/chrismaddalena/Goreport.git``` En el directorio descargado me creo un entorno virtual de Python en cua
quier equipo, lo activo einstalo las dependencias (el módulo python-docx me dio error, así que lo comenté en el txtposteriorme
te lo instalé a mano sin ningún problema ```python -m pip install python-docx```):

```sh
$ cd Georeport

$ python3 -m pip install virtualenv
$ python3 -m virtualenv .my_project

$ . .my_project/bin/activate

$ python -m pip install --upgrade pip

$ python -m pip install -r requirements.txt
```

Luego creas el archivo gophish.config y completas los datos necesarios:
```sh
[Gophish]

gp_host: https://127.0.0.1:3333
api_key:<YOUR_API_KEY>

[ipinfo.io]ipinfo_token:<IPINFO_API_KEY>

[Google]
geolocate_key:<GEOLOCATE_API_KEY>
```

Para obtener los informes debes de comprobar el ID de la campaña, por ejemplohttps://95.216.210.150:3333/campaigns/3 el id es 3
 Podemos obtener los informes en formato:

- excel: python GoReport.py --id 3 --format excel

- word: python GoReport.py --id 3 --format word

Infografías sobre Phishing

https://www.wessii.com/infografias-phishing-y-suplantacion-de-identidad/

# Uso de GoPhish

Utilizaremos un caso con Google

1. **Configurar "Sending Profile"**

Name : Utiliza el nombre que prefieras. (Google)

Interface Type : Utiliza siempre SMPT para utilizar un servidor web de mail.

From : Una dirección de correo electrónico válida. (example@gmail.com)

Host : Link del servidor SMPT. (smpt.gmail.com:587)

Username : Utiliza el nombre de usuario que prefieras. (example@gmail.com)

Password : Contraseña de tu cuenta de mail. (Ex : Example123)

Se recomienda enviar el mail de prueba disponible para comprobar que todo ha funcionado correctamente. [victim:(positionasunto)


SAVE.

2. **Configurar "Landing Page"**

Name : Nombre de la página web que se intenta clonar. (Google)

Presione importar sitio e ingrese la URL del sitio web que va a clonar.

Marque "Capture Sumbitted Data" para recibir los datos recopilados de la víctima.

Marque "Capture passwords" para recopilar las contraseñas de la víctima. Las contraseñas se mostrarán como texto sin formato si
no usa un  SSL.

Redirect to :  Redirigirá al sitio una vez que se haya enviado la contraseña. (google.com/login)

SAVE.

3. **Email Templates**

Name :  Introduce el nombre que vas a utilizar para el Mail  (Google)

Import Email : Copie el código fuente del contenido del correo electrónico y cópielo para tener un correo electrónico hecho.

Marque "Change Links to point to Landing Page" Será redirigido a nuestra página de destino. .

Si no quieres importar un correo electrónico tendrás que hacer todo este proceso manualmente. 

Marque "Add Tracking Image".

Añadir archivos al mail.

SAVE.

4. **Configuraciión de "Groups"**

Name : Nombre del grupo (victims)

Ingrese un nombre, apellido, dirección de correo electrónico y asunto. Y presione ADD. 

SAVE

5. **Configuración de "Campaigns".**

Name : Cualquier nombre. (Google)

Email Template : Establecer una plantilla de correo electrónico  (Google)

Landing Page : Seleccionar un nombre (Google)

URL : Establezca la url que está utilizando para el ataque de phishing  (http:0.0.0.0:80 -> Default)

Sending profile : Seleccione un perfil emisor. (Gmail)

Groups : Añadir un grupo.

LAUNCH CAMPAIGN

Comenzará a enviar al grupo. Cuando los datos estén dentro, serán accesibles. 
