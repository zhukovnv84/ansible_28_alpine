FROM alpine:3.8
# if you have proxy use it here ENV HTTP_PROXY=http://:port
RUN export http_proxy=$HTTP_PROXY


RUN echo "===> Installing sudo to emulate normal OS behavior..."  && \
    apk --update add sudo                                         && \
    \
    \
    echo "===> Adding Python runtime..."  && \
    apk --update add python py-pip        && \
    apk --update add --virtual build-dependencies \
                python-dev libffi-dev openssl-dev build-base py-cryptography

RUN pip install --upgrade pip --proxy=$HTTP_PROXY &&\
    pip install setuptools --upgrade  --proxy=$HTTP_PROXY
    \
    \
RUN  echo "===> Installing Ansible..."  && \
    pip install --upgrade cffi --proxy=$HTTP_PROXY

RUN    pip install ansible==2.8  --proxy=$HTTP_PROXY  && \
    \
    \
    echo  "Installing ssh server.." 

RUN apk --update add --no-cache openssh bash openjdk8 git \
  && sed -i s/#PermitRootLogin.*/PermitRootLogin\ yes/ /etc/ssh/sshd_config \
  && echo "root:root" | chpasswd \
  && rm -rf /var/cache/apk/*
RUN sed -ie 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
RUN sed -ri 's/#HostKey \/etc\/ssh\/ssh_host_key/HostKey \/etc\/ssh\/ssh_host_key/g' /etc/ssh/sshd_config
RUN sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_rsa_key/HostKey \/etc\/ssh\/ssh_host_rsa_key/g' /etc/ssh/sshd_config
RUN sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_dsa_key/HostKey \/etc\/ssh\/ssh_host_dsa_key/g' /etc/ssh/sshd_config
RUN sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_ecdsa_key/HostKey \/etc\/ssh\/ssh_host_ecdsa_key/g' /etc/ssh/sshd_config
RUN sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_ed25519_key/HostKey \/etc\/ssh\/ssh_host_ed25519_key/g' /etc/ssh/sshd_config
RUN  echo -e "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

RUN /usr/bin/ssh-keygen -A
RUN ssh-keygen -t rsa -b 4096 -f  /etc/ssh/ssh_host_key

    # Create a group and user
    RUN addgroup -S jenkins && adduser -S jenkins -G jenkins -h /home/jenkins -s /bin/bash
    RUN  echo "jenkins:jenkins" | chpasswd \

    # add public key

    ENV pub_key=""

   RUN mkdir /home/jenkins/.ssh  &&\
   chmod 0700 /home/jenkins/.ssh
   COPY authorized_keys /home/jenkins/.ssh/
   RUN chmod 0600 /home/jenkins/.ssh/authorized_keys &&\
   chown -R jenkins:jenkins /home/jenkins/.ssh


   EXPOSE 22
   CMD ["/usr/sbin/sshd","-D"]
