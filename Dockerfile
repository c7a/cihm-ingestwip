FROM ubuntu:trusty-20170817

# Same layer as cihm-metadatabus -- benefit to keeping in sync
RUN groupadd -g 1117 tdr && useradd -u 1117 -g tdr -m tdr && \
    mkdir -p /etc/canadiana /var/log/tdr /var/lock/tdr && ln -s /home/tdr /etc/canadiana/tdr && chown tdr.tdr /var/log/tdr /var/lock/tdr && \
    apt-get update && apt-get install -y cpanminus build-essential libxml-libxml-perl libxml-libxslt-perl rsync && apt-get clean

RUN groupadd -g 1115 cihm && useradd -u 1015 -g cihm -m cihm && \ 
    ln -s /home/tdr /etc/canadiana/wip && apt-get update && apt-get install -y libxml2-utils openjdk-6-jdk subversion poppler-utils imagemagick perlmagick && apt-get clean

# JHOVE needs to be able to validate abbyy finereader generated files, and loc.gov now has firewall.
RUN mkdir -p /opt/xml && svn co -r 6750 http://svn.c7a.ca/svn/c7a/xml/trunk /opt/xml/current && \
    xmlcatalog --noout --add uri http://www.loc.gov/standards/xlink/xlink.xsd file:///opt/xml/current/unpublished/xsd/xlink.xsd /etc/xml/catalog && \
    xmlcatalog --noout --add uri http://www.loc.gov/alto/v3/alto-3-0.xsd file:///opt/xml/current/unpublished/xsd/alto-3-0.xsd /etc/xml/catalog && \
    xmlcatalog --noout --add uri http://www.loc.gov/alto/v3/alto-3-1.xsd file:///opt/xml/current/unpublished/xsd/alto-3-1.xsd /etc/xml/catalog

WORKDIR /home/tdr
COPY cpanfile* *.conf *.xml /home/tdr/

# Build recent JHOVE. Reports are currently added to SIP. Failed validation doesn't stop processing
RUN curl -OL http://software.openpreservation.org/rel/jhove/jhove-1.16.jar && \
    java -jar jhove-1.16.jar jhove-auto-install.xml && mv jhove.conf /opt/jhove/conf

# Our application is perl code, which we added to a local PINTO server as modules.  Other dependencies are from CPAN.
ENV PERL_CPANM_OPT "--mirror http://feta.office.c7a.ca/stacks/c7a-perl-devel/ --mirror http://www.cpan.org/"
RUN cpanm -n --installdeps . && rm -rf /root/.cpanm || (cat /root/.cpanm/work/*/build.log && exit 1)

# Sometimes 'tdr', sometimes 'cihm'.  Picked one for the default
USER tdr
