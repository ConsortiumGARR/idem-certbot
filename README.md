# CERTBOT

## Note

Per poter eseguire `docker pull` delle immagini docker è necessario
concedere l\'accesso SSH(22), HTTP(80), HTTPS(443), GitLab(4567) alle
seguenti reti dal server `gitlab.dir.garr.it`:

- 90.147.166.0/23
- 90.147.167.0/23
- 90.147.188.0/23
- 90.147.189.0/23
- 90.147.156.0/23
- 90.147.200.0/25

## Base

Ognuno sulla propria macchina personale deve:

1. Installare GIT:

    - `sudo apt install --yes git`

2. Installare Docker:

    - <https://docs.docker.com/engine/install/debian/>

3. Installare Ansible:

    - `sudo apt install --yes ansible`

4. Spostarsi nella cartella dove depositare il codice preso da GIT:

    - `cd $HOME`

5. Aggiungere la chiave privata, legata alla chiave pubblica usata dal
    repository GIT, in un SSH Agent:

    (*questo passaggio è necessario* **SOLO** *se viene utilizzato SSH
    per il recupero del repository GIT*)

    - `eval "$(ssh-agent -s)"`
    - `ssh-add /PATH/SSH-PRIVATE-KEY`

6. Clonare il repository GIT in una delle due modalità:

    - SSH: `git clone git@gitlab.dir.garr.it:IDEM/idem-certbot.git`
      (**raccomandato**)

      (con SSH è possibile usare la propria chiave privata per non
      inserire sempre *username* e *password* di accesso)

    - HTTPS:
      `git clone https://gitlab.dir.garr.it/IDEM/idem-certbot.git`

## Creazione di una nuova immagine Docker

1. Aggiornare se necessario i file utili alla creazione dell'immagine
    docker:
    - `Dockerfile`
    - `start.sh`
2. Creare la nuova immagine per il certbot:
    - `cd $HOME/idem-certbot`
    - `docker build -f docker/Dockerfile -t gitlab.dir.garr.it:4567/idem/idem-certbot:<INSERISCI_VERSIONE> .`
3. Effettuare la login al container repository privato su GitLab:
    - `docker login gitlab.dir.garr.it:4567`
4. Effettuare il push della nuova immagine all\'interno del container
    repository:
    - `docker push gitlab.dir.garr.it:4567/idem/idem-certbot:<INSERISCI_VERSIONE>`

## Deployment con Ansible

Il deployment del progetto è effettuato tramite Ansible.
Attualmente l'istanza di produzione del certbot è sul cnode `controller-ba1 IP:10.4.54.100`.

La passphrase per decifrare/visualizzare/modificare il file dei secrets e per lanciare la ricetta Ansible si trova su [Password GARR](https://password.dir.garr.it/).

1. Assicurarsi che sia completato opportumanete il file `ansible/playbook.yml`.

2. Se necessario, aggiornare anche le variabili contenute in `ansible/group_vars` e/o i secrets, cifrati con ansible vault, contenuti in `ansible/vars/secrets.yml`.

3. Lanciare il comando Ansible per il deployment dipendentemente dall'infrastruttura di deployment scelta:

   1. Produzione in caso di Disaster-Recovery ( GARR Cloud Palermo ):

      ```bash
      cd $HOME/idem-certbot/
      
      ansible-playbook ansible/playbook.yml -i ansible/inventory-pa1.ini --ask-vault-pass
      ```

   2. Produzione ( GARR INFRA Bari ):

      ```bash
      cd $HOME/idem-certbot/
      
      ansible-playbook ansible/playbook.yml -i ansible/inventory-ba1.ini --ask-vault-pass
      ```
