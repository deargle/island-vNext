# Island vNext via Discourse -- how to start from scratch

## nginx-proxy

Needed in front because we're also running the CAS middleware, also does letsencrypt

First,

    docker network create nginx-proxy

* set up the nginx-proxy docker-compose

      git clone https://github.com/deargle/nginx-proxy
      cd nginx-proxy && docker-compose up -d

## MTA | Outbound mail with DKIM signing -- exim

There is a `setup-exim.sh` script in this repo, but I made a docker repo which
should (hopefully) work as a containerized version of the script, without having
to configure exim on the host.

* configure exim to sign messages with dkim

      git clone git@github.com:deargle/exim4.git
      # place dkim key in the exim4 directory
      docker build --tag exim4:1.0 .
      docker run -d --name exim4 --restart always --network nginx-proxy exim4:1.0

## Island - Discourse main site

* git clone https://github.com/discourse/discourse_docker
* put `app.yml` into `containers/` folder within discourse-docker checkout
* check docker args

        ./launcher bootstrap app

* follow the steps for restoring island from backup:

        # restore discourse from backup
        # download a backup from one of deargle's aws accounts
        # and put it into `/var/discourse/shared/standalone/backups/default/`. Then:

        TARBALL_PATH=$(ls shared/standalone/backups/default/*.tar.gz | tail -n 1)
        TARBALL_NAME=$(basename ${TARBALL_PATH})
        docker cp ${TARBALL_PATH} app:/var/www/discourse/public/backups/default/${TARBALL_NAME}
        docker exec -i app sh -x << EOF
        discourse enable_restore
        discourse restore ${TARBALL_NAME}
        discourse disable_restore
        EOF

        ./launcher rebuild app



## Loggin in via BYU CAS - Discourse CAS SSO

* Get the SSO key

  visit https://island.byu.edu/u/admin-login and get it from the GUI

  Or,

      ./launcher enter app-new
      rails c
      SiteSetting.find_by(name: 'sso_secret').value

* git clone the discourse-cas repo, `up` that.

      git clone git@github.com:deargle/discourse_cas_sso_byu.git

Look in the `docker-compose` file, it expects two env vars to be available,
set in `.env`. One is the `sso_secret`.

then,

      docker-compose up -d


## Inbound mail

* copy `mail-receiver.yml` into `containers/` folder within discourse-docker checkout

* Generate a new API key if necessary.
* set `DISCOURSE_API_KEY` in the template.
* check proper binding of public port 25 for forwarding as `-p` docker arg

then,

      ./launcher bootstrap main-receiver


# IOSFlashcards

      git clone git@github.com:deargle/iosflashcards.git

Has its own README, it's just a docker command to spin it up.
Runs on the nginx-proxy network.
