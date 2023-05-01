# Info de la materia: ST0263 Topicos Especiales en Telematica

# Estudiante: Julian David Ramirez Lopera, jdramirezl@eafit.edu.co

# Estudiante: Andres Salazar Galeano, asalaza5@eafit.edu.co

# Profesor: Edwin Nelson Montoya, emontoya@eafit.brightspace.com

# Despliegue de aplicacion LAMP Monolitica con servicios distribuidos en GCP

# 1. breve descripción de la actividad

Esta actividad consta de realizar el despliegue de la plataforma Moodle utilizando servicios de cloud para cubrir requisitos de almacenamiento, base de datos, maquinas virtuales, load balancing, certificados, y auto-scaling.

## 1.1. Que aspectos cumplió o desarrolló de la actividad propuesta por el profesor (requerimientos funcionales y no funcionales)

- [x] Desplegar una aplicacion LAMP con contenedores
- [x] Alta disponibilidad con 2 o mas contenedores de la app LAMP
- [x] Alta disponibilidad con balanceador de cargas
- [x] Alta disponibilidad con autoscaling 
- [x] Permitir el trafico de HTTPS
- [x] Tener certificado SSL propio
- [x] Uso de persistencia de datos con NFS
- [x] Uso de base de datos

## 1.2. Que aspectos NO cumplió o desarrolló de la actividad propuesta por el profesor (requerimientos funcionales y no funcionales)

N/A

# 2. información general de diseño de alto nivel

SDKFHASHDGASHDFASDFASHDFLASHDF
ASDFJASDFJASKDFASDFJASKJDFKASDF
SDKFHASHDGASHDFASDFASHDFLASHDF

ASDFJASDFJASKDFASDFJASKJDFKASDF
SDKFHASHDGASHDFASDFASHDFLASHDF

ASDFJASDFJASKDFASDFJASKJDFKASDF
SDKFHASHDGASHDFASDFASHDFLASHDF

ASDFJASDFJASKDFASDFJASKJDFKASDF



- Arquitectura: 
    * Monolitica con varios nodos para alta disponibilidad


- Mejores practicas: 
    * Implementacion de contenedores, 
    * Balanceo de cargas para alta disponibilidad con varios nodos, 
    * SSL con certificados propios, 
    * NFS para archivos distribuidos, 
    * Uso de variables de entorno. 
    * Correcta notacion de archivos y carpetas


# 3. Descripción del ambiente de EJECUCIÓN

- Maquinas virtuales utilizando Google Compute Engine y Ubuntu 22.04.
- Servicio Load Balancer.
- Servicio Instance Groups para manejo de autoscaling.
- Google Cloud Volumes para manejo de almacenamiento (NFS).
- Instance de MySQL utilizando Google Cloud SQL.
- Imagen Moodle de docker.


# IP o nombres de dominio en nube o en la máquina servidor.

- Cloud Load Balancing
    * HTTP: 34.107.161.133:80
    * HTTPS: 34.117.65.8:443
    * DOMINIO: reto4.jdramirezl.online
- Cloud Compute Engine (Virtual Machines)
    * VM 1 (instance-group-1-0mlj): 10.128.0.21
    * VM 2 (instance-group-1-xx6h): 10.128.0.22
- Cloud MySQL:
    * 10.63.192.3
- Cloud Volumes:
    * 172.31.219.4
    * Mount point: /nfs-moodle

</br>

## Descripción y como se configura los parámetros del proyecto

Los parametros del proyecto se configuran mas que todo al momento de creacion de cada uno de los componentes, incluso en algunos casos no es posible realizar cambios sobre los componentes una vez creados como en el caso de los instance templates de Google Compute Engine. 

Los parametros constan mas que nada de direcciones IP para la conexion entre diferentes servicios, y configuraciones especificas de cada servicio como sistemas operativo utilizado, nombre de base da datos, usuarios, entre otros.

</br>

### Maquinas Virtuales (Moodle)

- El docker-compose esta en: `/home/andresalazar138/reto-4/docker-compose.yml`
- Aqui se puede modificar:
    * ports: Cambiar los puertos de entrada. En general no hay necesidad de modificar
    * environment: Aqui se encuentran todas las variables con respecto a la base de datos
    * volumes: El directorio en el  que esta montado el NFS y que se replicara al Docker

```docker
version: "3.3"

services:
  moodle:
    image: bitnami/moodle:4.1.2
    restart: always
    ports:
      - 80:8080
      - 443:8443
    environment:
      - MOODLE_DATABASE_TYPE=mysqli # El tipo de base de datos
      - MOODLE_DATABASE_HOST= DATABASE IP
      - MOODLE_DATABASE_PORT_NUMBER= 3306 # El puerto
      - MOODLE_DATABASE_NAME= DATABASE NAME
      - MOODLE_DATABASE_USER= DATABASE USER
      - MOODLE_DATABASE_PASSWORD= DATABASE PASS
      - MOODLE_SKIP_BOOTSTRAP= yes
      - MOODLE_USERNAME= CHOSEN USERNAME
      - MOODLE_PASSWORD= CHOSEN PASSWORD
    volumes:
      - /mnt/nfs-moodle:/bitnami

```

## Como se lanza el servidor.

Debemos ingresar y levantar cada servicio como sea necesario

- Load balancer:

Esta se crea en la seccion `Cloud Load Balancing`. Aqui elegimos uno de tipo HTTPS de clase global al cual le configuramos:

    * Frontend: Elegimos un nombre, el protocolo en HTTPS, creamos una IP estatica, creamos un certificado con el servicio de GCP especificando el subdominio y habilitamos el redirect de HTTP a HTTPS
    * Backend: Creamos un nuevo servicio, le damos nombre, elegimos el instance group (Creado desde la imagen de una MV original) y por ultimo elegimos el maximum utilization (En nuestro caso 800%)

Ya siendo asi esperamos hasta 24 horas para que se genere el certificado SSL y ya podemos usar HTTPS.

Para correrlo no hay que hacer nada, estos solo se crean y borran sin pausar
</br>

- Maquinas Virtuales:

Las maquinas virtuales son creadas a partir de un instance template de acuerdo a la carga que se imponga sobre la aplicacion. Este template permite especificar un script que puede ser corriedo a la hora de iniciar la maquina virtual. En nuestro caso, este sera el encargado de correr el servicio de docker que sirve la aplicacion.

```sh
#!/bin/bash
sudo docker-compose -f /home/andresalazar138/reto-4/docker-compose.yml up -d
```
</br>
- Database:

La configuracion que realizamos sobre MySQL consto de simplemente permitir los debidos accesos a esta, crear la base de datos `moodledb`, y el usuario `moodleuser`.

Aparte de esto, si la base de datos ya esta creada, unicamente se debe ingresar y levantarla para disponibilizar este servicio a las maquinas virtuales de moodle.
</br>
- NFS volume

Para crear un sistema de archivos compartidos tenemos multiples opciones como discos persistentes, filestore, etc.

En nuestro caso decidimos usar los Cloud Volumes de Netapp (Un third-party).

Para crear uno de estos en la seccion `Volumes` de `Cloud Volumes` le damos crear y elegimos `CVS-Performance` para mayor performance y no usar storage pool. Ya habiendo elegida la region y nivel de servicio le damos un nombre al Volume, elegimos la ruta del sistema compartido (En nuestro caso `/nfs-moodle`) y el tipo de protocolo y creamos.


Para correr es igual que el Load Balancer, este solo se crea y borra, no se detiene entonces siempre esta disponible.

</br>

## Una mini guia de como un usuario utilizaría el software o la aplicación

Con el servidor ya corriendo:

1. Ingresar a la pagina web reto4.jdramirezl.online
2. Ingresar a la plataforma de moodle como de costumbre

## Resultados
SDKFHASHDGASHDFASDFASHDFLASHDF
ASDFJASDFJASKDFASDFJASKJDFKASDF
SDKFHASHDGASHDFASDFASHDFLASHDF

ASDFJASDFJASKDFASDFJASKJDFKASDF
SDKFHASHDGASHDFASDFASHDFLASHDF

ASDFJASDFJASKDFASDFJASKJDFKASDF
SDKFHASHDGASHDFASDFASHDFLASHDF

ASDFJASDFJASKDFASDFJASKJDFKASDF

# Comentarios

Como se habia mencionado anteriormente, la aplicacion permite el ingreso utilizando HTTPS (puerto 443), sin embargo tambien habilitamos la opcion de redireccionar todas las solicitudes hechas a utlizando HTTP para ser convertidas a HTTPS.


# referencias:
[Enunciado oficial](https://interactivavirtual.eafit.edu.co/d2l/le/content/122343/viewContent/615349/View)
[Load Balancer Backend Service](https://cloud.google.com/load-balancing/docs/backend-service)
[SSL](https://cloud.google.com/load-balancing/docs/ssl-certificates)
[GCP certificate stuck on provisioning](https://stackoverflow.com/questions/52812271/why-is-my-gcp-load-balancer-certificate-stuck-at-provisioning)

[GCP HTTPS SSL mismatch](https://stackoverflow.com/questions/62572290/google-cloud-https-err-ssl-version-or-cipher-mismatch)

[Cloud Volumes with netapp](https://cloud.google.com/architecture/partners/netapp-cloud-volumes/creating-nfs-volumes)



#### versión README.md -> 1.0 (2023-marzo)
