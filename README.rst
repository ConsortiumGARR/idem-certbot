=========
CERTBOT
=========

Indice
------

#. `Note`_
#. `Base`_
#. `Deployment via Ansible`_


Note
----

Per poter eseguire ``docker pull`` delle immagini docker è necessario concedere l'accesso SSH(22), HTTP(80), HTTPS(443), GitLab(4567) alle seguenti reti dal server ``gitlab.dir.garr.it``:

- 90.147.166.0/23
- 90.147.167.0/23
- 90.147.188.0/23
- 90.147.189.0/23
- 90.147.156.0/23
- 90.147.200.0/25


Base
----

Ognuno sulla propria macchina personale deve:

#. Installare GIT:

   - ``sudo apt install --yes git``

#. Installare Docker:

   - `<https://docs.docker.com/engine/install/debian/>`_

#. Installare Ansible:

   - ``sudo apt install --yes ansible``

#. Spostarsi nella cartella dove depositare il codice preso da GIT:

   - ``cd /opt``

#. Aggiungere la chiave privata, legata alla chiave pubblica usata dal repository GIT, in un SSH Agent:

   (*questo passaggio è necessario* **SOLO** *se viene utilizzato SSH per il recupero del repository GIT*)

   - ``eval "$(ssh-agent -s)"``
   
   - ``ssh-add /PATH/SSH-PRIVATE-KEY``

#. Clonare il repository GIT in una delle due modalità:

   - SSH: ``git clone git@gitlab.dir.garr.it:IDEM/idem-certbot.git``  (**raccomandato**)

     (con SSH è possibile usare la propria chiave privata per non inserire sempre *username* e *password* di accesso)

   - HTTPS: ``git clone https://gitlab.dir.garr.it/IDEM/idem-certbot.git``

[`Indice`_]


Creazione di una nuova immagine Docker
----------------------------------------

#. Aggiornare se necessario i file utili alla creazione dell'immagine docker:

   - ``Dockerfile``
   - ``start.sh``

#. Creare la nuova immagine per il certbot (aggiornare la versione se necessario):

   - ``docker build -t gitlab.dir.garr.it:4567/idem/idem-certbot:1.0.2 .``

#. Effettuare la login al container repository privato su GitLab:

   - ``docker login gitlab.dir.garr.it:4567``

#. Effettuare il push della nuova immagine all'interno del container repository:

   - ``docker push gitlab.dir.garr.it:4567/idem/idem-certbot:1.0.2``
