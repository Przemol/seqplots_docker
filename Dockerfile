# run:      docker run --rm -p 80:80 przemol/seqplots
# build:    docker build -t przemol/seqplots .
# run R:    docker run --rm -it --user shiny przemol/seqplots /usr/bin/R
# run bash: docker run --rm -it przemol/seqplots bash
# push:     docker push przemol/seqplots

FROM r-base:latest

MAINTAINER PS "ps562@cam.ac.uk"

RUN apt-get update && apt-get install -y \
    sudo \
    gdebi-core \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev/unstable \
    libxt-dev

# Download and install libssl 0.9.8
RUN wget --no-verbose http://ftp.us.debian.org/debian/pool/main/o/openssl/libssl0.9.8_0.9.8o-4squeeze14_amd64.deb && \
    dpkg -i libssl0.9.8_0.9.8o-4squeeze14_amd64.deb && \
    rm -f libssl0.9.8_0.9.8o-4squeeze14_amd64.deb

# Download and install shiny server
RUN wget --no-verbose https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
    gdebi -n ss-latest.deb && \
    rm -f version.txt ss-latest.deb

RUN R -e "install.packages(c('shiny', 'rmarkdown'), repos='https://cran.rstudio.com/')"
RUN apt-get install -y libxml2-dev
RUN R -e "install.packages('XML')"
RUN R -e "source('http://bioconductor.org/biocLite.R'); biocLite('seqplots')"
RUN R -e "source('http://bioconductor.org/biocLite.R'); biocLite('BSgenome.Celegans.UCSC.ce10')"

RUN apt-get install -y libssl-dev
RUN apt-get install -y libssh2-1-dev
RUN R -e "if (!require('devtools'))  install.packages('devtools')"
RUN R -e "devtools::install_github('przemol/seqplots', build_vignettes=FALSE)"

COPY shiny-server.conf  /etc/shiny-server/shiny-server.conf
RUN rm -Rf /srv/shiny-server
RUN ln -s /usr/local/lib/R/site-library/seqplots/seqplots /srv/shiny-server

RUN mkdir /var/shiny-server
RUN chmod a+w /var/shiny-server

COPY init.R /var/shiny-server/init.R
RUN su -c "R --vanilla < /var/shiny-server/init.R" shiny

VOLUME /var/shiny-server/DATA
RUN echo '.libPaths( c( .libPaths(), "/var/shiny-server/DATA/genomes") )' > /home/shiny/.Rprofile
RUN echo '.libPaths( c( .libPaths(), "/var/shiny-server/DATA/genomes") )' > /home/docker/.Rprofile

EXPOSE 80

COPY shiny-server.sh /usr/bin/shiny-server.sh

CMD ["/usr/bin/shiny-server.sh"]