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

Sulla propria macchina personale si deve:

01. Installare GIT:

    - `sudo apt install --yes git`

02. Installare Docker:

    - <https://docs.docker.com/engine/install/debian/>

03. Installare Ansible:

    - `sudo apt install --yes ansible`

04. Spostarsi nella cartella dove depositare il codice preso da GIT:

    - `cd $HOME`

05. Aggiungere la chiave privata, legata alla chiave pubblica usata dal repository GIT, in un SSH Agent:

    (*questo passaggio è necessario* **SOLO** *se viene utilizzato SSH per il recupero del repository GIT*)

    - `eval "$(ssh-agent -s)"`
    - `ssh-add /PATH/SSH-PRIVATE-KEY`

06. Clonare il repository GIT in una delle due modalità:

    - SSH: `git clone git@gitlab.dir.garr.it:IDEM/idem-certbot.git` (**raccomandato**)

      (con SSH è possibile usare la propria chiave privata per non inserire sempre *username* e *password* di accesso)

    - HTTPS: `git clone https://gitlab.dir.garr.it/IDEM/idem-certbot.git`

## Creazione di una nuova immagine Docker

01. Aggiornare, se necessario, i file utili alla creazione dell'immagine docker:

    - `idem-certbot/docker/Dockerfile`
    - `idem-certbot/docker/start.sh`

02. Creare la nuova immagine (il numero di versione segue il [Semantic Versioning](https://semver.org/lang/it/)):

    - `cd $HOME/idem-certbot`
    - `docker build -f docker/Dockerfile -t gitlab.dir.garr.it:4567/idem/idem-certbot:MAJOR.MINOR.PATCH .`

03. Effettuare la login al container registry:

    - `docker login gitlab.dir.garr.it:4567`

04. Effettuare il push della nuova immagine sul container registry:

    - `docker push gitlab.dir.garr.it:4567/idem/idem-certbot:MAJOR.MINOR.PATCH`

## Deployment con Ansible

Il deployment del progetto viene eseguito con Ansible.
Attualmente l'istanza di produzione del certbot è sul `cnode1-ba1-controller` (`10.4.54.100`).

La passphrase utilizzata per cifrare/decifrare/visualizzare/modificare il file `ansible/vars/secrets.yml` e per lanciare la ricetta Ansible si trova su [Password GARR](https://password.dir.garr.it/) in **Ansible Vault IDEM Setup repositories**.

1. Se necessario, aggiornare le variabili in:

   - `ansible/group_vars`
   - `ansible/vars`

    La passphrase da utilizzare per cifrare/decifrare/visualizzare/modificare il file `ansible/vars/secrets.yml` si trova su [Password GARR](https://password.dir.garr.it/) in **Ansible Vault IDEM Setup repositories**.

2. Salvare la passphrease all'interno del file `idem-certbot/.vault_pass.txt`

3. Aggiungere la chiave privata, legata alla chiave pubblica usata dal repository GIT, in un SSH Agent:

    (*questo passaggio è necessario* **SOLO** *se viene utilizzato SSH per il recupero del repository GIT*)

    - `eval "$(ssh-agent -s)"`
    - `ssh-add /PATH/SSH-PRIVATE-KEY`

4. Lanciare il comando Ansible per il deployment dipendentemente dall'infrastruttura di deployment scelta:

   - Test ( GARR Cloud Catania ):

     ```bash
     cd $HOME/idem-certbot/

     ansible-playbook ansible/playbook-ct1.yml -i ansible/inventory-ct1.ini --vault-password-file .vault_pass.txt -u GARR_USER
     ```

   - Produzione in caso di Disaster-Recovery ( GARR Cloud Palermo ):

     ```bash
     cd $HOME/idem-certbot/

     ansible-playbook ansible/playbook-pa1.yml -i ansible/inventory-pa1.ini --vault-password-file .vault_pass.txt -u GARR_USER
     ```

   - Produzione ( GARR INFRA Bari ):

     ```bash
     cd $HOME/idem-certbot/

     ansible-playbook ansible/playbook-ba1.yml -i ansible/inventory-ba1.ini --vault-password-file .vault_pass.txt -u GARR_USER
     ```

## Deployment per VM

01. Creare la cartella che conterrà quanto necessario sulla VM:

    `mkdir /opt/idem-certbot`

02. Creare `/opt/idem-certbot/docker-compose.yml`:

    ```bash
    services:
    idem-certbot:
        image: "gitlab.dir.garr.it:4567/idem/idem-certbot:{{ certbot_version }}"
        container_name: "idem-certbot"
        hostname: idem-certbot
        env_file:
        - ".idemcertbot.env"
        volumes:
        - /etc/letsencrypt/:/etc/letsencrypt
        restart: unless-stopped
        healthcheck:
        test: ["CMD-SHELL", "certbot certificates > /dev/null 2>&1"]
        interval: 1m
        timeout: 10s
        retries: 3
        start_period: 20s
    ```

03. Creare `/opt/idem-certbot/.idemcertbot.env`:

    ```bash
    EMAIL_ADMIN=<MAIL-UTENTE>
    KEY_ID=<KEY-ID-VALUE>
    HMAC_KEY=<HMAC_KEY_VALUE>
    SERVER_URL=<ACME-SERVER-URL>

    #DOMAINS_LIST=domain1:alias1,alias2;domain2;domain3:alias1
    DOMAINS_LIST=example.com:www.example.com,mail.example.com;test.org;mysite.net:blog.mysite.net
    ```

04. Avviare il Certbot:

    `sudo docker compose pull && sudo docker compose up -d`

05. Utilizzare i certificati disponibili in `/etc/letsencrypt`.

06. Una volta avviato il container è possibile eliminare il file `idemcertbot.env`.
