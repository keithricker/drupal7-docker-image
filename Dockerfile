# Standard Drupal 7 image

FROM drupal:7

# public key goes here
RUN if [ ! -d "/root/.ssh" ]; then mkdir /root/.ssh; fi
RUN chmod 0700 /root/.ssh
