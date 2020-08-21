# how to start from scratch

# nginx-proxy

* set up the nginx-proxy docker-compose. pull down nginx.tmpl.
    * This will give auto letsencrypt

    git clone https://github.com/deargle/nginx-proxy
    cd nginx-proxy && docker-compose up -d

# exim

* configure exim on the host to sign messages with dkim (see script below)

      git clone git@github.com:deargle/exim4.git
      # place dkim key in the exim4 directory

see readme for that repo, but docker build, docker run, etc. make sure to run
it within the nginx-proxy network


# discourse

* git clone discourse-docker into `/home/deargle/island`, drop in the two
  container config files below. Build them using the discourse `launcher`


## app-new.yml

* put this file into `containers/` folder within discourse-docker checkout

* check docker args

`./launcher bootstrap app-new.yml`

## mail-receiver.yml

* put this file into `containers/` folder within discourse-docker checkout

* set `DISCOURSE_API_KEY:`
* bind public port 25 for forwarding as `-p` docker arg

`./launcher bootstrap main-receiver.yml`


# restore discourse from backup

* follow the steps for restoring island from backup:

        # download a backup from one of deargle's aws accounts
        # and put it into `shared/standalone/backups/default/`. Then:

        TARBALL_PATH=$(ls shared/standalone/backups/default/*.tar.gz | tail -n 1)
        TARBALL_NAME=$(basename ${TARBALL_PATH})
        docker cp ${TARBALL_PATH} app:/var/www/discourse/public/backups/default/${TARBALL_NAME}
        docker exec -i app sh -x << EOF
        discourse enable_restore
        discourse restore ${TARBALL_NAME}
        discourse disable_restore
        EOF

        ./launcher rebuild app

# Discourse CAS SSO

* git clone the discourse-cas repo, `up` that.

    git clone git@github.com:deargle/discourse_cas_sso_byu.git

In `config/configatron/defaults.rb`:
* `configatron.sso.secret`, pull from discourse

then,

    docker-compose up -d

# IOSFlashcards

git@github.com:deargle/iosflashcards.git

has its own README, it's just a docker command to spin it up.
